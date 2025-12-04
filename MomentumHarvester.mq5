//+------------------------------------------------------------------+
//|                                            MomentumHarvester.mq5 |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Momentum Harvester EA"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

//--- Input Parameters
input group "=== Momentum Detection ==="
input int InpConsolidationBars = 20;           // Bars for consolidation detection
input double InpBreakoutMultiplier = 2.0;      // ATR multiplier for breakout
input int InpATRPeriod = 14;                   // ATR Period
input double InpMinMomentumCandle = 1.5;       // Min candle size (ATR multiplier)

input group "=== Risk Management ==="
input double InpRiskPercent = 1.0;             // Risk per trade (%)
input double InpStopLossATR = 3.0;             // Stop Loss (ATR multiplier)
input double InpTakeProfitATR = 3.0;           // Take Profit (ATR multiplier)
input int InpMaxBarsInTrade = 10;              // Max bars in trade (0=disabled)

input group "=== Filters ==="
input int InpMaxSpreadPoints = 50;             // Max spread in points (0=disabled)
input double InpSpreadToMoveRatio = 0.2;       // Max spread/expected move ratio (0=disabled)
input int InpMinVolumeMultiplier = 2;          // Min volume vs average (0=disabled)

input group "=== Trading Hours ==="
input bool InpUseTimeFilter = false;           // Use time filter
input int InpStartHour = 8;                    // Start hour
input int InpEndHour = 20;                     // End hour

input group "=== General ==="
input int InpMagicNumber = 123456;             // Magic number
input string InpTradeComment = "MomHarvest";   // Trade comment

//--- Global Variables
CTrade trade;
int handleATR;
double atrBuffer[];
datetime lastBarTime = 0;
int barsInTrade = 0;
datetime tradeOpenTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize ATR indicator
   handleATR = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);
   if(handleATR == INVALID_HANDLE)
   {
      Print("Failed to create ATR indicator");
      return INIT_FAILED;
   }

   // Set array as series
   ArraySetAsSeries(atrBuffer, true);

   // Configure trade object
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(20);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   trade.SetAsyncMode(false);

   Print("MomentumHarvester initialized successfully");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(handleATR != INVALID_HANDLE)
      IndicatorRelease(handleATR);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check for new bar
   if(!IsNewBar())
      return;

   // Update ATR
   if(CopyBuffer(handleATR, 0, 0, 3, atrBuffer) < 3)
      return;

   double currentATR = atrBuffer[0];
   if(currentATR <= 0)
   {
      Print("ATR is zero or negative: ", currentATR);
      return;
   }

   // Check if we have an open position
   if(PositionSelect(_Symbol))
   {
      ManageOpenPosition(currentATR);
      return;
   }

   // Reset trade counter if no position
   barsInTrade = 0;

   // Debug: Print ATR value once per hour
   static datetime lastDebugTime = 0;
   if(TimeCurrent() - lastDebugTime > 3600)
   {
      Print("Current ATR: ", DoubleToString(currentATR, _Digits),
            " | Symbol Point: ", SymbolInfoDouble(_Symbol, SYMBOL_POINT),
            " | Spread: ", SymbolInfoInteger(_Symbol, SYMBOL_SPREAD), " points");
      lastDebugTime = TimeCurrent();
   }

   // Apply filters
   if(!PassesFilters(currentATR))
      return;

   // Check for momentum breakout
   CheckForBreakout(currentATR);
}

//+------------------------------------------------------------------+
//| Check if new bar formed                                          |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(currentBarTime != lastBarTime)
   {
      lastBarTime = currentBarTime;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Check if trading conditions pass filters                         |
//+------------------------------------------------------------------+
bool PassesFilters(double atr)
{
   // Time filter
   if(InpUseTimeFilter)
   {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      if(dt.hour < InpStartHour || dt.hour >= InpEndHour)
         return false;
   }

   // Spread filter in points
   int spreadPoints = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   double spreadValue = spreadPoints * SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   if(InpMaxSpreadPoints > 0 && spreadPoints > InpMaxSpreadPoints)
   {
      Print("Spread too high: ", spreadPoints, " points");
      return false;
   }

   // Spread to expected move ratio
   if(InpSpreadToMoveRatio > 0)
   {
      double expectedMove = atr * InpBreakoutMultiplier;
      double ratio = spreadValue / expectedMove;

      if(ratio > InpSpreadToMoveRatio)
      {
         Print("Spread/Move ratio too high: ", DoubleToString(ratio, 3),
               " | Spread: ", spreadPoints, " points (", DoubleToString(spreadValue, _Digits), ")",
               " | ATR: ", DoubleToString(atr, _Digits),
               " | Expected move (ATR*", InpBreakoutMultiplier, "): ", DoubleToString(expectedMove, _Digits),
               " | Ratio: ", DoubleToString(ratio * 100, 1), "%");
         return false;
      }
   }

   return true;
}

//+------------------------------------------------------------------+
//| Detect consolidation phase                                       |
//+------------------------------------------------------------------+
bool IsConsolidating(double atr, double &rangeHigh, double &rangeLow)
{
   if(InpConsolidationBars < 3)
      return false;

   rangeHigh = iHigh(_Symbol, PERIOD_CURRENT, 1);
   rangeLow = iLow(_Symbol, PERIOD_CURRENT, 1);

   // Find highest high and lowest low in consolidation period
   for(int i = 2; i <= InpConsolidationBars; i++)
   {
      double high = iHigh(_Symbol, PERIOD_CURRENT, i);
      double low = iLow(_Symbol, PERIOD_CURRENT, i);

      if(high > rangeHigh) rangeHigh = high;
      if(low < rangeLow) rangeLow = low;
   }

   double rangeSize = rangeHigh - rangeLow;
   double avgATR = atrBuffer[1]; // Previous ATR

   // Consolidation if range is smaller than normal volatility
   if(rangeSize < avgATR * InpBreakoutMultiplier)
      return true;

   return false;
}

//+------------------------------------------------------------------+
//| Check for momentum breakout                                      |
//+------------------------------------------------------------------+
void CheckForBreakout(double atr)
{
   double rangeHigh, rangeLow;

   // First check if we were in consolidation
   if(!IsConsolidating(atr, rangeHigh, rangeLow))
      return;

   // Get current completed candle
   double open = iOpen(_Symbol, PERIOD_CURRENT, 1);
   double close = iClose(_Symbol, PERIOD_CURRENT, 1);
   double high = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double low = iLow(_Symbol, PERIOD_CURRENT, 1);

   double candleSize = MathAbs(close - open);
   double candleRange = high - low;

   // Check if candle is strong enough
   if(candleSize < atr * InpMinMomentumCandle)
      return;

   // Check volume if enabled
   if(InpMinVolumeMultiplier > 0)
   {
      long currentVol = iVolume(_Symbol, PERIOD_CURRENT, 1);
      long avgVol = 0;
      for(int i = 2; i < InpConsolidationBars + 2; i++)
         avgVol += iVolume(_Symbol, PERIOD_CURRENT, i);
      avgVol /= InpConsolidationBars;

      if(currentVol < avgVol * InpMinVolumeMultiplier)
      {
         Print("Volume too low for breakout");
         return;
      }
   }

   // Bullish breakout
   if(close > open && close > rangeHigh)
   {
      // Check candle quality (small wicks = institutional move)
      double bodyRatio = candleSize / candleRange;
      if(bodyRatio > 0.6) // At least 60% body
      {
         Print("Bullish breakout detected! Close: ", close, " Range high: ", rangeHigh);
         OpenTrade(ORDER_TYPE_BUY, atr);
      }
   }
   // Bearish breakout
   else if(close < open && close < rangeLow)
   {
      double bodyRatio = candleSize / candleRange;
      if(bodyRatio > 0.6)
      {
         Print("Bearish breakout detected! Close: ", close, " Range low: ", rangeLow);
         OpenTrade(ORDER_TYPE_SELL, atr);
      }
   }
}

//+------------------------------------------------------------------+
//| Open trade with calculated risk                                  |
//+------------------------------------------------------------------+
void OpenTrade(ENUM_ORDER_TYPE orderType, double atr)
{
   double price = (orderType == ORDER_TYPE_BUY) ?
                  SymbolInfoDouble(_Symbol, SYMBOL_ASK) :
                  SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double stopLoss, takeProfit;

   // Calculate SL and TP based on ATR
   if(orderType == ORDER_TYPE_BUY)
   {
      stopLoss = price - (atr * InpStopLossATR);
      takeProfit = price + (atr * InpTakeProfitATR);
   }
   else
   {
      stopLoss = price + (atr * InpStopLossATR);
      takeProfit = price - (atr * InpTakeProfitATR);
   }

   // Normalize prices
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   stopLoss = NormalizeDouble(MathRound(stopLoss / tickSize) * tickSize, _Digits);
   takeProfit = NormalizeDouble(MathRound(takeProfit / tickSize) * tickSize, _Digits);

   // Calculate lot size based on risk
   double slDistance = MathAbs(price - stopLoss);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = accountBalance * (InpRiskPercent / 100.0);

   double lots = riskAmount / (slDistance / tickSize * tickValue);
   lots = MathFloor(lots / lotStep) * lotStep;
   lots = MathMax(minLot, MathMin(maxLot, lots));

   // Execute trade
   bool result = false;
   if(orderType == ORDER_TYPE_BUY)
      result = trade.Buy(lots, _Symbol, price, stopLoss, takeProfit, InpTradeComment);
   else
      result = trade.Sell(lots, _Symbol, price, stopLoss, takeProfit, InpTradeComment);

   if(result)
   {
      tradeOpenTime = TimeCurrent();
      Print("Trade opened: ", EnumToString(orderType), " Lots: ", lots,
            " SL: ", stopLoss, " TP: ", takeProfit);
   }
   else
   {
      Print("Trade failed: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Manage open position                                             |
//+------------------------------------------------------------------+
void ManageOpenPosition(double atr)
{
   if(!PositionSelect(_Symbol))
      return;

   barsInTrade++;

   // Time-based exit
   if(InpMaxBarsInTrade > 0 && barsInTrade >= InpMaxBarsInTrade)
   {
      double currentProfit = PositionGetDouble(POSITION_PROFIT);
      if(currentProfit > 0)
      {
         Print("Closing position after ", barsInTrade, " bars with profit: ", currentProfit);
         trade.PositionClose(_Symbol);
         return;
      }
   }

   // Could add trailing stop logic here later if needed
   // For now we rely on fixed TP and time-based exit
}

//+------------------------------------------------------------------+
