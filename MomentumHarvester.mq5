//+------------------------------------------------------------------+
//|                                            MomentumHarvester.mq5 |
//|                                   MA Trend Following Strategy     |
//+------------------------------------------------------------------+
#property copyright "MA Trend Follower EA"
#property version   "2.00"
#property strict

#include <Trade\Trade.mqh>

//--- Input Parameters
input group "=== Moving Averages ==="
input int InpFastMA = 20;                      // Fast MA period
input int InpSlowMA = 50;                      // Slow MA period
input ENUM_MA_METHOD InpMAMethod = MODE_EMA;   // MA method
input ENUM_APPLIED_PRICE InpMAPrice = PRICE_CLOSE; // MA applied price

input group "=== Entry Rules ==="
input bool InpRequireBothMA = true;            // Require close above/below BOTH MAs
input int InpMinBarsAboveMA = 1;               // Min bars above MA before entry (0=instant)

input group "=== Exit Rules ==="
input bool InpExitOnFastMA = true;             // Exit when fast MA breaks
input bool InpExitOnSlowMA = false;            // Exit when slow MA breaks (OR condition)
input int InpMaxBarsInTrade = 0;               // Max bars in trade (0=disabled)

input group "=== Risk Management ==="
input double InpRiskPercent = 1.0;             // Risk per trade (%)
input double InpStopLossATR = 3.0;             // Stop Loss (ATR multiplier)
input double InpTakeProfitATR = 0;             // Take Profit (ATR multiplier, 0=disabled)
input int InpATRPeriod = 14;                   // ATR Period

input group "=== Filters ==="
input int InpMaxSpreadPoints = 50;             // Max spread in points (0=disabled)
input double InpSpreadToMoveRatio = 0.5;       // Max spread/expected move ratio (0=disabled)

input group "=== Trading Hours ==="
input bool InpUseTimeFilter = false;           // Use time filter
input int InpStartHour = 8;                    // Start hour
input int InpEndHour = 20;                     // End hour

input group "=== General ==="
input int InpMagicNumber = 123456;             // Magic number
input string InpTradeComment = "MATrend";      // Trade comment

//--- Global Variables
CTrade trade;
int handleFastMA, handleSlowMA, handleATR;
double fastMABuffer[], slowMABuffer[], atrBuffer[];
datetime lastBarTime = 0;
int barsInTrade = 0;
int barsAboveMA = 0;
int barsBelowMA = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize indicators
   handleFastMA = iMA(_Symbol, PERIOD_CURRENT, InpFastMA, 0, InpMAMethod, InpMAPrice);
   handleSlowMA = iMA(_Symbol, PERIOD_CURRENT, InpSlowMA, 0, InpMAMethod, InpMAPrice);
   handleATR = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);

   if(handleFastMA == INVALID_HANDLE || handleSlowMA == INVALID_HANDLE || handleATR == INVALID_HANDLE)
   {
      Print("Failed to create indicators");
      return INIT_FAILED;
   }

   // Set arrays as series
   ArraySetAsSeries(fastMABuffer, true);
   ArraySetAsSeries(slowMABuffer, true);
   ArraySetAsSeries(atrBuffer, true);

   // Configure trade object
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(20);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   trade.SetAsyncMode(false);

   Print("MA Trend Follower initialized - Fast MA: ", InpFastMA, " Slow MA: ", InpSlowMA);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(handleFastMA != INVALID_HANDLE) IndicatorRelease(handleFastMA);
   if(handleSlowMA != INVALID_HANDLE) IndicatorRelease(handleSlowMA);
   if(handleATR != INVALID_HANDLE) IndicatorRelease(handleATR);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check for new bar
   if(!IsNewBar())
      return;

   // Update indicators
   if(CopyBuffer(handleFastMA, 0, 0, 3, fastMABuffer) < 3) return;
   if(CopyBuffer(handleSlowMA, 0, 0, 3, slowMABuffer) < 3) return;
   if(CopyBuffer(handleATR, 0, 0, 3, atrBuffer) < 3) return;

   double currentATR = atrBuffer[0];
   if(currentATR <= 0) return;

   // Check if we have an open position
   if(PositionSelect(_Symbol))
   {
      ManageOpenPosition(currentATR);
      return;
   }

   // Reset trade counter if no position
   barsInTrade = 0;

   // Apply filters
   if(!PassesFilters(currentATR))
      return;

   // Check for trend entry
   CheckForEntry(currentATR);
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

   // Get spread and point size
   int spreadPoints = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // Simple spread filter
   if(InpMaxSpreadPoints > 0 && spreadPoints > InpMaxSpreadPoints)
   {
      Print("Spread too high: ", spreadPoints, " points (max: ", InpMaxSpreadPoints, ")");
      return false;
   }

   // Spread to expected move ratio
   if(InpSpreadToMoveRatio > 0)
   {
      double atrInPoints = atr / point;
      double expectedMovePoints = atrInPoints;
      double ratio = spreadPoints / expectedMovePoints;

      if(ratio > InpSpreadToMoveRatio)
      {
         static int ratioCounter = 0;
         ratioCounter++;
         if(ratioCounter >= 20)
         {
            Print("Spread/Move ratio too high: ", DoubleToString(ratio * 100, 1), "% (max: ",
                  DoubleToString(InpSpreadToMoveRatio * 100, 1), "%)");
            ratioCounter = 0;
         }
         return false;
      }
   }

   return true;
}

//+------------------------------------------------------------------+
//| Check for trend entry                                            |
//+------------------------------------------------------------------+
void CheckForEntry(double atr)
{
   // Get completed candle data
   double close = iClose(_Symbol, PERIOD_CURRENT, 1);
   double fastMA = fastMABuffer[1];
   double slowMA = slowMABuffer[1];

   // Check bullish setup
   bool bullishSetup = false;
   if(InpRequireBothMA)
      bullishSetup = (close > fastMA && close > slowMA);
   else
      bullishSetup = (close > fastMA || close > slowMA);

   // Check bearish setup
   bool bearishSetup = false;
   if(InpRequireBothMA)
      bearishSetup = (close < fastMA && close < slowMA);
   else
      bearishSetup = (close < fastMA || close < slowMA);

   // Count bars above/below MA
   if(bullishSetup)
   {
      barsAboveMA++;
      barsBelowMA = 0;
   }
   else if(bearishSetup)
   {
      barsBelowMA++;
      barsAboveMA = 0;
   }
   else
   {
      barsAboveMA = 0;
      barsBelowMA = 0;
   }

   // Entry conditions
   if(bullishSetup && barsAboveMA >= InpMinBarsAboveMA)
   {
      Print("=== BULLISH TREND ENTRY ===");
      Print("Close: ", close, " | Fast MA: ", fastMA, " | Slow MA: ", slowMA,
            " | Bars above: ", barsAboveMA);
      OpenTrade(ORDER_TYPE_BUY, atr);
   }
   else if(bearishSetup && barsBelowMA >= InpMinBarsAboveMA)
   {
      Print("=== BEARISH TREND ENTRY ===");
      Print("Close: ", close, " | Fast MA: ", fastMA, " | Slow MA: ", slowMA,
            " | Bars below: ", barsBelowMA);
      OpenTrade(ORDER_TYPE_SELL, atr);
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

   // Calculate SL based on ATR
   if(orderType == ORDER_TYPE_BUY)
   {
      stopLoss = price - (atr * InpStopLossATR);
      takeProfit = (InpTakeProfitATR > 0) ? price + (atr * InpTakeProfitATR) : 0;
   }
   else
   {
      stopLoss = price + (atr * InpStopLossATR);
      takeProfit = (InpTakeProfitATR > 0) ? price - (atr * InpTakeProfitATR) : 0;
   }

   // Normalize prices
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   stopLoss = NormalizeDouble(MathRound(stopLoss / tickSize) * tickSize, _Digits);
   if(takeProfit > 0)
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
      Print("Trade opened: ", EnumToString(orderType), " Lots: ", lots,
            " SL: ", stopLoss, " TP: ", (takeProfit > 0 ? DoubleToString(takeProfit, _Digits) : "None"));
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

   // Get position info
   long posType = PositionGetInteger(POSITION_TYPE);
   double close = iClose(_Symbol, PERIOD_CURRENT, 1);
   double fastMA = fastMABuffer[1];
   double slowMA = slowMABuffer[1];

   bool shouldExit = false;
   string exitReason = "";

   // Check MA break exit
   if(posType == POSITION_TYPE_BUY)
   {
      if(InpExitOnFastMA && close < fastMA)
      {
         shouldExit = true;
         exitReason = "Close below Fast MA";
      }
      else if(InpExitOnSlowMA && close < slowMA)
      {
         shouldExit = true;
         exitReason = "Close below Slow MA";
      }
   }
   else // POSITION_TYPE_SELL
   {
      if(InpExitOnFastMA && close > fastMA)
      {
         shouldExit = true;
         exitReason = "Close above Fast MA";
      }
      else if(InpExitOnSlowMA && close > slowMA)
      {
         shouldExit = true;
         exitReason = "Close above Slow MA";
      }
   }

   // Time-based exit
   if(InpMaxBarsInTrade > 0 && barsInTrade >= InpMaxBarsInTrade)
   {
      shouldExit = true;
      exitReason = StringFormat("Max bars in trade (%d)", InpMaxBarsInTrade);
   }

   // Execute exit
   if(shouldExit)
   {
      double profit = PositionGetDouble(POSITION_PROFIT);
      Print("=== CLOSING POSITION ===");
      Print("Reason: ", exitReason, " | Profit: ", DoubleToString(profit, 2),
            " | Bars in trade: ", barsInTrade);
      trade.PositionClose(_Symbol);
   }
}

//+------------------------------------------------------------------+
