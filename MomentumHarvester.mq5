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

input group "=== Trade Direction ==="
input bool InpAllowBuy = true;                 // Allow BUY trades
input bool InpAllowSell = true;                // Allow SELL trades

input group "=== Exit Rules ==="
input bool InpExitOnFastMA = true;             // Exit when fast MA breaks
input bool InpExitOnSlowMA = false;            // Exit when slow MA breaks (OR condition)
input int InpMaxBarsInTrade = 0;               // Max bars in trade (0=disabled)

input group "=== Risk Management ==="
input double InpLotSize = 0.01;                // Fixed lot size
input double InpStopLossPoints = 1000;         // Stop Loss in points (0=disabled)
input double InpTakeProfitPoints = 0;          // Take Profit in points (0=disabled)

input group "=== Trading Hours ==="
input bool InpUseTimeFilter = false;           // Use time filter
input int InpStartHour = 8;                    // Start hour
input int InpEndHour = 20;                     // End hour

input group "=== General ==="
input int InpMagicNumber = 123456;             // Magic number
input string InpTradeComment = "MATrend";      // Trade comment

//--- Global Variables
CTrade trade;
int handleFastMA, handleSlowMA;
double fastMABuffer[], slowMABuffer[];
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

   if(handleFastMA == INVALID_HANDLE || handleSlowMA == INVALID_HANDLE)
   {
      Print("Failed to create indicators");
      return INIT_FAILED;
   }

   // Set arrays as series
   ArraySetAsSeries(fastMABuffer, true);
   ArraySetAsSeries(slowMABuffer, true);

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

   // Check if we have an open position
   if(PositionSelect(_Symbol))
   {
      ManageOpenPosition();
      return;
   }

   // Reset trade counter if no position
   barsInTrade = 0;

   // Time filter
   if(InpUseTimeFilter)
   {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      if(dt.hour < InpStartHour || dt.hour >= InpEndHour)
         return;
   }

   // Check for trend entry
   CheckForEntry();
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
//| Check for trend entry                                            |
//+------------------------------------------------------------------+
void CheckForEntry()
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
   if(bullishSetup && barsAboveMA >= InpMinBarsAboveMA && InpAllowBuy)
   {
      Print("=== BULLISH TREND ENTRY ===");
      Print("Close: ", close, " | Fast MA: ", fastMA, " | Slow MA: ", slowMA,
            " | Bars above: ", barsAboveMA);
      OpenTrade(ORDER_TYPE_BUY);
   }
   else if(bearishSetup && barsBelowMA >= InpMinBarsAboveMA && InpAllowSell)
   {
      Print("=== BEARISH TREND ENTRY ===");
      Print("Close: ", close, " | Fast MA: ", fastMA, " | Slow MA: ", slowMA,
            " | Bars below: ", barsBelowMA);
      OpenTrade(ORDER_TYPE_SELL);
   }
}

//+------------------------------------------------------------------+
//| Open trade with fixed lot size                                   |
//+------------------------------------------------------------------+
void OpenTrade(ENUM_ORDER_TYPE orderType)
{
   double price = (orderType == ORDER_TYPE_BUY) ?
                  SymbolInfoDouble(_Symbol, SYMBOL_ASK) :
                  SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double stopLoss = 0, takeProfit = 0;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   // Calculate SL and TP if specified
   if(InpStopLossPoints > 0)
   {
      double slDistance = InpStopLossPoints * point;
      if(orderType == ORDER_TYPE_BUY)
         stopLoss = price - slDistance;
      else
         stopLoss = price + slDistance;
      stopLoss = NormalizeDouble(stopLoss, digits);
   }

   if(InpTakeProfitPoints > 0)
   {
      double tpDistance = InpTakeProfitPoints * point;
      if(orderType == ORDER_TYPE_BUY)
         takeProfit = price + tpDistance;
      else
         takeProfit = price - tpDistance;
      takeProfit = NormalizeDouble(takeProfit, digits);
   }

   // Execute trade
   bool result = false;
   if(orderType == ORDER_TYPE_BUY)
      result = trade.Buy(InpLotSize, _Symbol, price, stopLoss, takeProfit, InpTradeComment);
   else
      result = trade.Sell(InpLotSize, _Symbol, price, stopLoss, takeProfit, InpTradeComment);

   if(result)
   {
      Print("Trade opened: ", EnumToString(orderType), " Lots: ", InpLotSize,
            " SL: ", (stopLoss > 0 ? DoubleToString(stopLoss, digits) : "None"),
            " TP: ", (takeProfit > 0 ? DoubleToString(takeProfit, digits) : "None"));
   }
   else
   {
      Print("Trade failed: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Manage open position                                             |
//+------------------------------------------------------------------+
void ManageOpenPosition()
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
