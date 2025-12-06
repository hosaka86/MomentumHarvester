# MQL5 Expert Advisor Tutorial: MA Trend Following Strategy

## Video Introduction Script

### Opening (0:00 - 0:45)

**[On Screen: Welcome back animation, your logo]**

"Hey traders, welcome back to the channel! I know it's been a while, but today I've got something special for you - a **complete Expert Advisor** that we're going to code together from scratch.

This is a **Moving Average Trend Following EA** - simple, but effective. And I highly recommend you follow along step by step, because by the end of this video, you'll understand not just HOW to code in MQL5, but WHY we make certain decisions.

Before we jump in, quick announcements:"

**[On Screen: Discord logo/link animation]**

"If you're looking to connect with other algo traders, discuss strategies, or get help with your code - join our Discord community. Link is in the description below."

**[On Screen: Purchase option graphic]**

"And if you want to skip the coding and get straight to testing this EA, you can purchase the ready-to-use version - also linked in the description."

### Strategy Overview (0:45 - 2:00)

**[On Screen: Chart with MAs animated]**

"Alright, let's talk about what this EA actually does.

**The Core Logic** is beautifully simple:

**Number 1:** We use two Moving Averages - a fast MA and a slow MA - to identify the trend direction.

**Number 2:** We enter a BUY when price is trading above both MAs, confirming an uptrend.

**Number 3:** We enter a SELL when price is below both MAs, confirming a downtrend.

**Number 4:** We exit when price crosses back through our MAs, signaling the trend is weakening.

That's it. No complicated indicators, no machine learning, no magic. Just clean trend-following logic."

**[On Screen: Backtest results montage]**

"Now, you might be thinking - 'Does this actually work?' Let me show you some backtest results..."

**[Show 3-5 slides of backtest stats: equity curve, win rate, profit factor, drawdown]**

"As you can see, on EUR/USD, we're getting a profit factor of [X], with a win rate around [Y]%. The equity curve shows consistent growth with manageable drawdowns. On GBP/USD, similar story - [brief stats]. And this is across multiple years of data."

### Transition to Code (2:00 - 2:20)

**[On Screen: Code editor opening]**

"Obviously, backtest results aren't guarantees - but they show this strategy has edge. Now, the exciting part: let's build this thing.

I've broken down the entire EA into **31 parts**. Each part focuses on one specific concept, so you'll understand every single line of code.

We'll cover:
- How to set up indicators in MQL5
- Entry and exit logic
- Risk management with stop losses
- Position management
- And all the best practices you need to know

So grab your coffee, open MetaEditor, and let's code."

**[Fade to Part 1]**

---

## Tutorial Structure

This tutorial breaks down a complete Moving Average Trend Following Expert Advisor (EA) into digestible parts. Each section explains what the code does and why we do it.

---

## Part 1: File Header and Basic Setup

**What is this?** Every MQL5 Expert Advisor starts with metadata and includes necessary libraries.

**Why?** The header provides information about the EA, and we need the Trade library to execute orders.

### 🎙️ Narration (Text-to-Speech Ready):
"Let's start with Part 1: the file header and basic setup. Every MQL5 Expert Advisor begins with a header section that contains metadata like copyright and version information. The hash-property strict directive enables strict compilation mode, which helps catch errors during development. Most importantly, we include the Trade library with the hash-include statement. This library provides the C-Trade class, which is what we'll use to execute all our buy and sell orders. Think of this as importing the toolbox we need to actually place trades."

```mql5
//+------------------------------------------------------------------+
//|                                            MomentumHarvester.mq5 |
//|                                   MA Trend Following Strategy     |
//+------------------------------------------------------------------+
#property copyright "MA Trend Follower EA"
#property version   "2.00"
#property strict

// Include the MQL5 trade library - provides functions to open/close trades
#include <Trade\Trade.mqh>
```

**Explanation:**
- `#property copyright` and `#property version`: Metadata about the EA
- `#property strict`: Enables strict compilation mode for better error checking
- `#include <Trade\Trade.mqh>`: Imports the CTrade class which handles all trading operations

---

## Part 2: Input Parameters - Moving Averages

**What is this?** User-configurable parameters for the Moving Averages that define our trend.

**Why?** We want users to customize the MA periods and calculation method without changing code.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 2 covers our Moving Average input parameters. The input keyword in MQL5 makes variables user-configurable, meaning traders can adjust these settings without touching the code. We define a fast MA with a period of 20, which reacts quickly to price changes, and a slow MA with a period of 50, which shows the longer-term trend. We're using exponential moving averages, or EMAs, which give more weight to recent prices compared to simple moving averages. Finally, we calculate these MAs based on the closing price of each candle. These four parameters are the foundation of our entire strategy."

```mql5
//--- Input Parameters
// input group creates visual sections in the EA settings dialog
input group "=== Moving Averages ==="
input int InpFastMA = 20;                      // Fast MA period - reacts quickly to price
input int InpSlowMA = 50;                      // Slow MA period - shows longer-term trend
input ENUM_MA_METHOD InpMAMethod = MODE_EMA;   // MA method (SMA, EMA, SMMA, LWMA)
input ENUM_APPLIED_PRICE InpMAPrice = PRICE_CLOSE; // Which price to use (close, open, high, low, etc.)
```

**Explanation:**
- `input`: Makes variables user-configurable in MetaTrader
- `input group`: Organizes parameters into sections
- **Fast MA (20)**: Shorter period follows price closely, catches trends early
- **Slow MA (50)**: Longer period filters noise, confirms trend direction
- **MODE_EMA**: Exponential Moving Average gives more weight to recent prices
- **PRICE_CLOSE**: Calculate MA based on closing prices of candles

---

## Part 3: Input Parameters - Entry Rules

**What is this?** Settings that control when the EA enters trades.

**Why?** Different entry rules create different trading behaviors and risk profiles.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 3 introduces our entry rules, which control when we actually enter trades. The first parameter, Require Both MA, determines whether price must be above or below both moving averages, or just one of them. Setting this to true creates a stricter filter with fewer but higher quality signals. The second parameter, Minimum Bars Above MA, prevents us from jumping into trades on the very first bar. Instead, we can require confirmation by waiting for one or more consecutive bars to meet our criteria. Setting this to zero gives instant entries, while setting it to one or higher adds confirmation."

```mql5
input group "=== Entry Rules ==="
// Determines if price must be above/below BOTH MAs or just ONE
input bool InpRequireBothMA = true;            // Require close above/below BOTH MAs
// How many consecutive bars must meet conditions before entering
input int InpMinBarsAboveMA = 1;               // Min bars above MA before entry (0=instant)
```

**Explanation:**
- **InpRequireBothMA = true**: Price must be above BOTH fast AND slow MA for BUY (stricter, fewer signals)
- **InpRequireBothMA = false**: Price above EITHER MA triggers entry (more signals, more risk)
- **InpMinBarsAboveMA**: Prevents entering on first bar - waits for confirmation. 1 = enter after 1 confirming bar, 0 = instant entry

---

## Part 4: Input Parameters - Trade Direction

**What is this?** Controls which trade directions are allowed.

**Why?** Sometimes you only want to trade in one direction based on market analysis.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 4 gives us directional control with two simple boolean switches. Allow Buy and Allow Sell let you enable or disable long and short positions independently. This is incredibly useful when you have a directional bias on the market. For example, if you believe we're in a strong bull market, you can disable sells and only take buy trades. This flexibility allows you to adapt the EA to different market conditions without changing any code."

```mql5
input group "=== Trade Direction ==="
// These switches allow directional bias trading
input bool InpAllowBuy = true;                 // Allow BUY trades
input bool InpAllowSell = true;                // Allow SELL trades
```

**Explanation:**
- **InpAllowBuy**: Set to false to disable long positions
- **InpAllowSell**: Set to false to disable short positions
- **Use case**: If you believe market is bullish, disable sells and only trade buys

---

## Part 5: Input Parameters - Exit Rules

**What is this?** Defines when to close open positions.

**Why?** Exit strategy is as important as entry - determines profit/loss on trades.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 5 covers our exit rules, which are just as important as our entry logic. We have two moving average exit options: exit on fast MA break, and exit on slow MA break. These work as an OR condition, meaning either one can trigger the exit. The fast MA gives you earlier exits when the trend weakens, while the slow MA lets winners run longer. Additionally, we have a maximum bars in trade parameter that forces an exit after a certain number of candles, preventing us from holding losing positions indefinitely. Set this to zero to disable it, or to something like 50 to enforce a maximum hold time."

```mql5
input group "=== Exit Rules ==="
// Exit when price crosses back below/above the moving averages
input bool InpExitOnFastMA = true;             // Exit when fast MA breaks
input bool InpExitOnSlowMA = false;            // Exit when slow MA breaks (OR condition)
// Maximum time to hold a trade regardless of profit/loss
input int InpMaxBarsInTrade = 0;               // Max bars in trade (0=disabled)
```

**Explanation:**
- **InpExitOnFastMA**: BUY closes when price crosses below fast MA, SELL closes when above
- **InpExitOnSlowMA**: Alternative exit on slow MA cross (OR condition with fast MA)
- **InpMaxBarsInTrade**: Forces exit after X bars - prevents holding losing trades forever
  - Set to 0 to disable this feature
  - Example: 50 bars = close position after 50 candles no matter what

---

## Part 6: Input Parameters - Risk Management

**What is this?** Controls position sizing and stop loss/take profit levels.

**Why?** Risk management is crucial - determines how much you risk per trade.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 6 introduces risk management parameters, which are absolutely critical for protecting your trading account. The lot size parameter controls your position size, with zero point zero one being a micro lot suitable for testing and small accounts. Stop loss in pips defines your maximum loss per trade, measured in pips rather than price. Setting it to 100 pips means you'll risk 100 pips on each trade, while setting it to zero disables the stop loss entirely, though that's not recommended. Take profit in pips works the same way, defining your profit target, and setting it to zero means you'll rely on the moving average exit rules instead of a fixed profit target."

```mql5
input group "=== Risk Management ==="
// Fixed lot size for all trades
input double InpLotSize = 0.01;                // Fixed lot size
// Stop Loss in pips - maximum loss per trade
input double InpStopLossPips = 100;            // Stop Loss in pips (0=disabled)
// Take Profit in pips - profit target
input double InpTakeProfitPips = 0;            // Take Profit in pips (0=disabled)
```

**Explanation:**
- **InpLotSize**: Fixed position size (0.01 = micro lot)
  - Future enhancement: could implement percentage-based sizing
- **InpStopLossPips**: Maximum loss in pips (10 pips = 100 points on 5-digit broker)
  - Set to 0 to disable SL (not recommended!)
- **InpTakeProfitPips**: Profit target in pips
  - Set to 0 to let trend run (exit only on MA cross)

---

## Part 7: Input Parameters - Trading Hours & General Settings

**What is this?** Time filter and EA identification settings.

**Why?** Some strategies work better during specific hours; magic number identifies this EA's trades.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 7 covers trading hours and general settings that control when and how the EA operates. The time filter lets you restrict trading to specific hours of the day based on broker server time, which is useful for avoiding low-liquidity periods like the Asian session or overnight trading. The magic number is a unique identifier that tags all trades opened by this EA, ensuring it doesn't interfere with manual trades or other Expert Advisors running on the same account. Finally, the trade comment parameter adds a label to all your trades, making them easy to identify in your trading history."

```mql5
input group "=== Trading Hours ==="
// Restrict trading to specific hours of the day
input bool InpUseTimeFilter = false;           // Use time filter
input int InpStartHour = 8;                    // Start hour (broker server time)
input int InpEndHour = 20;                     // End hour (broker server time)

input group "=== General ==="
// Unique identifier for this EA's trades
input int InpMagicNumber = 123456;             // Magic number
// Comment attached to all trades
input string InpTradeComment = "MATrend";      // Trade comment
```

**Explanation:**
- **InpUseTimeFilter**: Enable/disable time restrictions
- **InpStartHour/InpEndHour**: Only trade between these hours (avoids low-liquidity periods)
  - Example: 8-20 avoids Asian session, focuses on European/US overlap
- **InpMagicNumber**: Unique ID so EA doesn't interfere with manual trades or other EAs
- **InpTradeComment**: Appears in trade history for easy identification

---

## Part 8: Global Variables

**What is this?** Variables that persist between function calls and store EA state.

**Why?** We need to remember indicator handles, buffers, and track trading state.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 8 defines our global variables, which maintain state across the entire lifecycle of the EA. The CTrade object handles all our trading operations like opening and closing positions. The indicator handles are references to our moving average indicators that we'll create during initialization. The MA buffer arrays store the actual moving average values that we'll use for our trading logic. We track the last bar time to ensure we only make decisions once per completed candle, and we maintain counters for bars in trade and confirmation bars, which help us enforce our entry and exit rules."

```mql5
//--- Global Variables
// CTrade object handles all trading operations (open, close, modify)
CTrade trade;

// Indicator handles - references to the MA indicators
int handleFastMA, handleSlowMA;

// Arrays to store MA values - [0] is current, [1] is previous bar
double fastMABuffer[], slowMABuffer[];

// Tracks when last bar was processed - ensures we only trade once per bar
datetime lastBarTime = 0;

// Counter for how many bars current position has been open
int barsInTrade = 0;

// Counters for consecutive bars above/below MA (for confirmation)
int barsAboveMA = 0;
int barsBelowMA = 0;
```

**Explanation:**
- **CTrade trade**: Object that executes market orders
- **handleFastMA/handleSlowMA**: Pointers to indicator instances
- **fastMABuffer[]/slowMABuffer[]**: Store MA values for analysis
- **lastBarTime**: Prevents multiple trades on same bar
- **barsInTrade**: Tracks position duration (for max bars exit)
- **barsAboveMA/barsBelowMA**: Counts confirmation bars before entry

---

## Part 9: OnInit() Function - Part A: Indicator Initialization

**What is this?** Initialization function runs once when EA starts.

**Why?** We must create indicators and configure settings before trading begins.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 9 begins our OnInit function, which runs exactly once when the EA is first attached to a chart. This is where we create our moving average indicators using the iMA function, which returns a handle or reference to each indicator. We pass in the user's configured parameters for period, method, and price type. It's critical to check if the indicators were created successfully by verifying the handles aren't invalid, and if creation fails, we return INIT_FAILED to prevent the EA from running with broken indicators."

```mql5
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Create Moving Average indicators
   // iMA returns a handle (reference) to the indicator
   // _Symbol = current chart symbol, PERIOD_CURRENT = current timeframe
   handleFastMA = iMA(_Symbol, PERIOD_CURRENT, InpFastMA, 0, InpMAMethod, InpMAPrice);
   handleSlowMA = iMA(_Symbol, PERIOD_CURRENT, InpSlowMA, 0, InpMAMethod, InpMAPrice);

   // Check if indicators were created successfully
   if(handleFastMA == INVALID_HANDLE || handleSlowMA == INVALID_HANDLE)
   {
      Print("Failed to create indicators");
      return INIT_FAILED;  // Stop EA if indicators fail
   }
```

**Explanation:**
- **iMA()**: Creates a Moving Average indicator
  - Parameters: Symbol, Timeframe, Period, Shift, Method, Applied Price
- **INVALID_HANDLE**: Returned if indicator creation fails
- **INIT_FAILED**: Tells MetaTrader the EA couldn't start properly

---

## Part 10: OnInit() Function - Part B: Array and Trade Configuration

**What is this?** Final initialization steps - configure arrays and trading settings.

**Why?** Arrays must be set as series; trade object needs magic number and execution settings.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 10 completes our initialization by configuring the indicator buffers and trade settings. We set both MA buffers as series arrays, which makes index zero represent the most recent bar, matching how MQL5 references price data. Then we configure the CTrade object with our magic number for trade identification, set the maximum slippage we'll accept, specify Fill or Kill execution mode, and disable asynchronous mode so the EA waits for trade confirmation before continuing. Finally, we return INIT_SUCCEEDED to signal that everything initialized correctly and the EA is ready to start trading."

```mql5
   // Set arrays as series (indexing: 0=newest, 1=previous, 2=older, etc.)
   // This matches how we reference bars in MQL5
   ArraySetAsSeries(fastMABuffer, true);
   ArraySetAsSeries(slowMABuffer, true);

   // Configure the CTrade object with our settings
   trade.SetExpertMagicNumber(InpMagicNumber);  // Assign our magic number
   trade.SetDeviationInPoints(20);              // Allow 20 points slippage
   trade.SetTypeFilling(ORDER_FILLING_FOK);     // Fill or Kill - execute completely or not at all
   trade.SetAsyncMode(false);                   // Synchronous mode - wait for trade result

   // Log successful initialization
   Print("MA Trend Follower initialized - Fast MA: ", InpFastMA, " Slow MA: ", InpSlowMA);
   return INIT_SUCCEEDED;  // EA initialized successfully
}
```

**Explanation:**
- **ArraySetAsSeries(true)**: Makes array[0] = most recent data (like price bars)
- **SetExpertMagicNumber()**: Tags all trades with our magic number
- **SetDeviationInPoints(20)**: Accept up to 20 points price difference from requested price
- **ORDER_FILLING_FOK**: "Fill or Kill" - entire order executes or nothing (vs partial fills)
- **SetAsyncMode(false)**: Wait for broker response before continuing (safer for EAs)
- **INIT_SUCCEEDED**: EA ready to trade

---

## Part 11: OnDeinit() Function

**What is this?** Cleanup function runs when EA is removed or stopped.

**Why?** Must release indicator resources to prevent memory leaks.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 11 covers the OnDeinit function, which is the cleanup counterpart to OnInit. This function runs when the EA is removed from the chart, when MetaTrader closes, or when you recompile the code. Its job is simple but important: release the indicator handles to free up memory. We check that each handle is valid before releasing it, which is a defensive programming practice that prevents errors if something went wrong during initialization."

```mql5
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Release indicator handles to free memory
   // Always clean up resources when EA stops
   if(handleFastMA != INVALID_HANDLE) IndicatorRelease(handleFastMA);
   if(handleSlowMA != INVALID_HANDLE) IndicatorRelease(handleSlowMA);
}
```

**Explanation:**
- **OnDeinit()**: Called when EA stops (removed from chart, terminal closes, recompile)
- **reason**: Code indicating why EA stopped (useful for debugging)
- **IndicatorRelease()**: Frees memory used by indicators
- **if check**: Only release if handle is valid (defensive programming)

---

## Part 12: OnTick() Function - Main Logic Entry Point

**What is this?** Called every time price changes (every tick).

**Why?** This is the "heart" of the EA - where all trading decisions happen.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 12 introduces the OnTick function, which is the beating heart of our Expert Advisor. This function is called automatically every single time the price changes, which could be hundreds of times per second during active market hours. However, we don't want to make trading decisions on every tick, so the first thing we do is check if a new bar has formed using our IsNewBar function. If we're still on the same candle as before, we simply exit and wait. Once a new bar forms, we copy the latest moving average values into our buffers using CopyBuffer, retrieving three bars of data for current, previous, and historical analysis."

```mql5
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // STEP 1: Check for new bar - only trade on bar close, not every tick
   // This prevents multiple entries on same candle
   if(!IsNewBar())
      return;  // Exit if same bar as last check

   // STEP 2: Update indicator buffers with latest MA values
   // CopyBuffer fills our arrays with MA data
   // Parameters: handle, buffer_index, start_position, count, destination_array
   // We copy 3 bars: [0]=current, [1]=previous completed, [2]=older
   if(CopyBuffer(handleFastMA, 0, 0, 3, fastMABuffer) < 3) return;
   if(CopyBuffer(handleSlowMA, 0, 0, 3, slowMABuffer) < 3) return;
```

**Explanation:**
- **OnTick()**: Executes on every price change (could be hundreds per second)
- **IsNewBar()**: Our function to check if a new candle formed
- **Why wait for new bar?**: Prevents overtrading, ensures completed candle data
- **CopyBuffer()**: Retrieves calculated indicator values
  - Returns number of values copied
  - We need at least 3 for analysis (current, previous, confirmation)
  - `< 3`: Data not ready yet, exit and wait

---

## Part 13: OnTick() Function - Position Management

**What is this?** Checks if we have an open trade and manages it.

**Why?** If we're already in a trade, we should manage it instead of looking for new entries.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 13 handles position management logic within our OnTick function. We use PositionSelect to check if we already have an open position for the current symbol. If a position exists, we call our ManageOpenPosition function to check exit conditions and then return immediately, preventing the EA from looking for new entries while already in a trade. This ensures we maintain only one position at a time. If no position is found, we reset the bars in trade counter to zero, preparing for the next potential entry."

```mql5
   // STEP 3: Check if we already have a position open
   // PositionSelect returns true if a position exists for this symbol
   if(PositionSelect(_Symbol))
   {
      // We have an open position - manage it (check for exit conditions)
      ManageOpenPosition();
      return;  // Don't look for new entries while in a trade
   }

   // STEP 4: No position open - reset the bars-in-trade counter
   barsInTrade = 0;
```

**Explanation:**
- **PositionSelect(_Symbol)**: Checks if position exists for current symbol
  - Returns true if position found
  - Also loads position info for other PositionGet functions
- **ManageOpenPosition()**: Our function to check exit conditions
- **return**: Important! Don't check for entries if already in trade (one position at a time)
- **barsInTrade = 0**: Reset counter when no position

---

## Part 14: OnTick() Function - Time Filter and Entry Check

**What is this?** Final checks before looking for trade entries.

**Why?** Respect time filter if enabled, then check for valid entry setups.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 14 completes our OnTick function with time filtering and entry logic. If the time filter is enabled, we convert the current broker time into a structure so we can access the hour component. We then check if the current hour falls outside our specified trading window, and if so, we exit without looking for entries. This is useful for avoiding low-liquidity periods or overnight risk. Finally, if we pass the time filter and have no open positions, we call CheckForEntry to analyze the moving average conditions and potentially open a new trade."

```mql5
   // STEP 5: Apply time filter if enabled
   if(InpUseTimeFilter)
   {
      MqlDateTime dt;  // Structure to hold date/time components
      TimeToStruct(TimeCurrent(), dt);  // Convert current time to structure

      // Check if current hour is outside trading window
      if(dt.hour < InpStartHour || dt.hour >= InpEndHour)
         return;  // Outside trading hours - don't enter new trades
   }

   // STEP 6: Look for valid entry signals
   CheckForEntry();
}
```

**Explanation:**
- **MqlDateTime**: Structure containing year, month, day, hour, minute, second
- **TimeCurrent()**: Current broker server time
- **TimeToStruct()**: Converts datetime to structure for easy access to hour/minute
- **dt.hour**: Current hour (0-23)
- **Time filter logic**: Only trade between start and end hours
  - Example: Start=8, End=20 → only trade 08:00-19:59
- **CheckForEntry()**: Our function to analyze MA conditions and open trades

---

## Part 15: IsNewBar() Function

**What is this?** Detects when a new candle has formed.

**Why?** We only want to make decisions on completed candles, not mid-candle.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 15 introduces the IsNewBar function, which is a critical utility that prevents our EA from overtrading. The function works by retrieving the opening time of the current bar using iTime, and comparing it to the last bar time we stored in our global variable. If these times are different, it means a new candle has formed, so we update our stored time and return true. If they're the same, we return false, signaling that we're still on the same bar. This elegant solution ensures our trading logic executes exactly once per candle, not on every price tick."

```mql5
//+------------------------------------------------------------------+
//| Check if new bar formed                                          |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   // Get the opening time of the current (most recent) bar
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);

   // Compare with the last bar time we processed
   if(currentBarTime != lastBarTime)
   {
      // New bar detected! Update our stored time
      lastBarTime = currentBarTime;
      return true;  // Signal that we have a new bar
   }

   // Same bar as before - no new candle yet
   return false;
}
```

**Explanation:**
- **iTime()**: Returns opening time of specified bar
  - Parameters: Symbol, Timeframe, Bar Index (0=current)
- **currentBarTime**: Opening time of current candle
- **lastBarTime**: Global variable storing last processed candle time
- **Logic**: If times differ, a new candle formed
- **Why this works**: Each candle has unique opening time
- **Result**: Ensures OnTick logic runs only once per candle

---

## Part 16: CheckForEntry() Function - Part A: Get Price and MA Data

**What is this?** First step of entry logic - gather data for analysis.

**Why?** Need close price and MA values to determine if trend conditions are met.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 16 begins our CheckForEntry function by gathering the data we need for analysis. We retrieve the closing price of the previous completed bar using index one, not index zero, because the current bar at index zero is still forming and its price keeps changing. We also grab the fast and slow moving average values from index one in our buffers. Using completed bar data is crucial for reliable trading decisions, as it ensures we're analyzing confirmed price action rather than mid-candle fluctuations."

```mql5
//+------------------------------------------------------------------+
//| Check for trend entry                                            |
//+------------------------------------------------------------------+
void CheckForEntry()
{
   // Get the COMPLETED candle data (index 1, not 0)
   // Index 0 = current forming candle (incomplete)
   // Index 1 = last completed candle (reliable data)
   double close = iClose(_Symbol, PERIOD_CURRENT, 1);
   double fastMA = fastMABuffer[1];  // Fast MA value at bar 1
   double slowMA = slowMABuffer[1];  // Slow MA value at bar 1
```

**Explanation:**
- **Index 1 vs Index 0**:
  - [0] = current forming bar (still changing)
  - [1] = previous completed bar (fixed, reliable)
- **iClose()**: Gets closing price of specified bar
- **Why completed bar?**: Current bar keeps changing - we need confirmed data
- **MA values**: Already copied to buffers in OnTick()

---

## Part 17: CheckForEntry() Function - Part B: Determine Bullish Setup

**What is this?** Logic to identify bullish (uptrend) entry conditions.

**Why?** Different rules for strict vs lenient entry (both MAs vs either MA).

### 🎙️ Narration (Text-to-Speech Ready):
"Part 17 determines whether we have a bullish setup worthy of entering a buy trade. If the Require Both MA parameter is true, we use strict mode where the closing price must be above both the fast and slow moving averages, creating an AND condition that provides stronger trend confirmation. If Require Both MA is false, we use lenient mode where price only needs to be above either moving average, creating an OR condition that generates more trading opportunities but with potentially weaker signals. This flexibility lets you tune the strategy's aggressiveness to match your risk tolerance."

```mql5
   // Determine if we have a BULLISH setup (price above MAs)
   bool bullishSetup = false;

   if(InpRequireBothMA)
      // STRICT MODE: Price must be above BOTH fast AND slow MA
      // More conservative - fewer but higher quality signals
      bullishSetup = (close > fastMA && close > slowMA);
   else
      // LENIENT MODE: Price above EITHER fast OR slow MA
      // More aggressive - more signals but potentially weaker
      bullishSetup = (close > fastMA || close > slowMA);
```

**Explanation:**
- **InpRequireBothMA = true (strict)**:
  - AND condition: `close > fastMA && close > slowMA`
  - Both conditions must be true
  - Stronger confirmation of uptrend
  - Fewer false signals
- **InpRequireBothMA = false (lenient)**:
  - OR condition: `close > fastMA || close > slowMA`
  - Either condition triggers entry
  - More trading opportunities
  - Higher risk of false signals

---

## Part 18: CheckForEntry() Function - Part C: Determine Bearish Setup

**What is this?** Logic to identify bearish (downtrend) entry conditions.

**Why?** Mirror logic of bullish setup for selling opportunities.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 18 implements the bearish setup detection, which is the mirror image of our bullish logic. In strict mode, price must be below both moving averages to confirm a strong downtrend, while in lenient mode, price only needs to be below either moving average for an earlier signal. The logic is identical to Part 17 except we've inverted the comparison operators from greater than to less than. This symmetrical approach ensures our strategy treats long and short trades with the same logical consistency."

```mql5
   // Determine if we have a BEARISH setup (price below MAs)
   bool bearishSetup = false;

   if(InpRequireBothMA)
      // STRICT MODE: Price must be below BOTH fast AND slow MA
      bearishSetup = (close < fastMA && close < slowMA);
   else
      // LENIENT MODE: Price below EITHER fast OR slow MA
      bearishSetup = (close < fastMA || close < slowMA);
```

**Explanation:**
- **Same logic as bullish, but inverted**:
  - `>` becomes `<` (below instead of above)
- **InpRequireBothMA = true**: Close below BOTH MAs (strong downtrend)
- **InpRequireBothMA = false**: Close below EITHER MA (early downtrend signal)
- **Symmetry**: Ensures consistent logic for both directions

---

## Part 19: CheckForEntry() Function - Part D: Count Confirmation Bars

**What is this?** Tracks consecutive bars above/below MAs for entry confirmation.

**Why?** Prevents entering on first touch - requires sustained move for confirmation.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 19 implements our confirmation bar counting system, which prevents jumping into trades on the very first signal. If we detect a bullish setup, we increment the bars above MA counter and reset the bars below MA counter to zero, since we can't be bullish and bearish simultaneously. If we detect a bearish setup, we do the opposite. If neither setup is present, meaning price is between the moving averages or conditions are mixed, we reset both counters to zero. This mechanism ensures we only enter after price has shown sustained directional movement for the number of bars specified in our minimum bars parameter."

```mql5
   // Count consecutive bars that meet setup criteria
   // This provides confirmation - not just a single bar touch

   if(bullishSetup)
   {
      barsAboveMA++;     // Increment bullish counter
      barsBelowMA = 0;   // Reset bearish counter
   }
   else if(bearishSetup)
   {
      barsBelowMA++;     // Increment bearish counter
      barsAboveMA = 0;   // Reset bullish counter
   }
   else
   {
      // Price between MAs or mixed conditions - reset both
      barsAboveMA = 0;
      barsBelowMA = 0;
   }
```

**Explanation:**
- **barsAboveMA**: Counts consecutive bullish bars
- **barsBelowMA**: Counts consecutive bearish bars
- **Increment logic**: Add 1 each bar that meets criteria
- **Reset logic**: When setup changes, counter resets to 0
- **Why reset opposite?**: Can't be bullish and bearish simultaneously
- **Use case**:
  - InpMinBarsAboveMA = 3 → Need 3 consecutive bullish bars before entering
  - Filters out weak/choppy moves

---

## Part 20: CheckForEntry() Function - Part E: Execute Bullish Entry

**What is this?** Checks if bullish conditions met and opens BUY trade.

**Why?** Final gate before entering - verifies all conditions and direction allowed.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 20 executes our bullish entry after verifying all conditions are met. We check three things: first, that we have a bullish setup with price above the moving averages; second, that we've accumulated enough confirmation bars to meet our minimum requirement; and third, that buy trades are allowed by the directional filter. All three must be true for the entry to proceed. If they are, we log detailed entry information to the Experts tab showing the exact price and moving average values, then call our OpenTrade function with ORDER_TYPE_BUY to execute the market order."

```mql5
   // Check if all conditions met for BULLISH entry
   if(bullishSetup && barsAboveMA >= InpMinBarsAboveMA && InpAllowBuy)
   {
      // Log entry details for analysis/debugging
      Print("=== BULLISH TREND ENTRY ===");
      Print("Close: ", close, " | Fast MA: ", fastMA, " | Slow MA: ", slowMA,
            " | Bars above: ", barsAboveMA);

      // Execute BUY order
      OpenTrade(ORDER_TYPE_BUY);
   }
```

**Explanation:**
- **Three conditions required**:
  1. `bullishSetup`: Price above MA(s)
  2. `barsAboveMA >= InpMinBarsAboveMA`: Enough confirmation bars
  3. `InpAllowBuy`: BUY direction enabled
- **All must be true (AND)**: If any false, no entry
- **Print statements**: Log entry details to Experts tab
  - Helps with backtesting analysis
  - Shows exact values at entry
- **OpenTrade()**: Our function to execute the order

---

## Part 21: CheckForEntry() Function - Part F: Execute Bearish Entry

**What is this?** Checks if bearish conditions met and opens SELL trade.

**Why?** Mirror logic for sell entries - ensures symmetrical trading approach.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 21 handles bearish entries using the same structure as our bullish logic. We use else if to ensure we only enter one trade at a time, since we can't be both bullish and bearish simultaneously. The three conditions mirror Part 20: we need a bearish setup, sufficient confirmation bars, and sell trades must be allowed. Notice we use the same minimum bars parameter for both directions, which keeps our confirmation requirements consistent. Once all conditions are met, we log the entry details and call OpenTrade with ORDER_TYPE_SELL to execute the short position."

```mql5
   else if(bearishSetup && barsBelowMA >= InpMinBarsAboveMA && InpAllowSell)
   {
      // Log entry details
      Print("=== BEARISH TREND ENTRY ===");
      Print("Close: ", close, " | Fast MA: ", fastMA, " | Slow MA: ", slowMA,
            " | Bars below: ", barsBelowMA);

      // Execute SELL order
      OpenTrade(ORDER_TYPE_SELL);
   }
}
```

**Explanation:**
- **else if**: Only one trade at a time (can't be both bullish and bearish)
- **Three conditions**:
  1. `bearishSetup`: Price below MA(s)
  2. `barsBelowMA >= InpMinBarsAboveMA`: Enough confirmation
  3. `InpAllowSell`: SELL direction enabled
- **Note**: Uses same `InpMinBarsAboveMA` parameter (works for both directions)
- **Print**: Shows bearish entry details
- **ORDER_TYPE_SELL**: Parameter tells OpenTrade to sell

---

## Part 22: OpenTrade() Function - Part A: Get Entry Price

**What is this?** Determines the execution price for market order.

**Why?** BUY uses Ask price, SELL uses Bid price (standard Forex convention).

### 🎙️ Narration (Text-to-Speech Ready):
"Part 22 begins our OpenTrade function, which handles the actual order execution. The function accepts an order type parameter that tells us whether we're buying or selling. We use a ternary operator to select the appropriate entry price: buy orders execute at the Ask price, which is the higher price where the market is willing to sell to you, while sell orders execute at the Bid price, which is the lower price where the market is willing to buy from you. We also retrieve the symbol's point value and digit precision, which we'll need for calculating stop loss and take profit levels."

```mql5
//+------------------------------------------------------------------+
//| Open trade with fixed lot size                                   |
//+------------------------------------------------------------------+
void OpenTrade(ENUM_ORDER_TYPE orderType)
{
   // Get the appropriate entry price based on order type
   // BUY orders execute at ASK (higher price - you're buying from market)
   // SELL orders execute at BID (lower price - you're selling to market)
   double price = (orderType == ORDER_TYPE_BUY) ?
                  SymbolInfoDouble(_Symbol, SYMBOL_ASK) :
                  SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Variables for Stop Loss and Take Profit
   double stopLoss = 0, takeProfit = 0;

   // Get symbol specifications needed for calculations
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);    // Minimum price change
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS); // Price decimal places
```

**Explanation:**
- **ENUM_ORDER_TYPE orderType**: Parameter (ORDER_TYPE_BUY or ORDER_TYPE_SELL)
- **Ternary operator**: `condition ? value_if_true : value_if_false`
- **SYMBOL_ASK**: Price at which you can BUY
- **SYMBOL_BID**: Price at which you can SELL
- **Spread**: Difference between Ask and Bid (broker's profit)
- **point**: Smallest price increment (0.00001 for EUR/USD)
- **digits**: Decimal places (5 for EUR/USD, 3 for JPY pairs)

---

## Part 23: OpenTrade() Function - Part B: Calculate Stop Loss

**What is this?** Calculates Stop Loss price if enabled.

**Why?** Protects against excessive losses - crucial risk management.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 23 calculates our stop loss price, which is critical for risk management. We first check if stop loss is enabled by testing if the pips value is greater than zero. If enabled, we convert pips to price distance by multiplying by the point value and by ten, since one pip equals ten points on a five-digit broker. For buy orders, the stop loss goes below the entry price since losses occur when price drops, while for sell orders, it goes above the entry price since losses occur when price rises. Finally, we normalize the price to the correct number of decimal places required by the broker."

```mql5
   // Calculate Stop Loss if specified (InpStopLossPips > 0)
   if(InpStopLossPips > 0)
   {
      // Convert pips to price distance
      // Multiply by 10 because 1 pip = 10 points on 5-digit broker
      // Example: 100 pips * 0.00001 * 10 = 0.00100 (100 points)
      double slDistance = InpStopLossPips * point * 10;

      if(orderType == ORDER_TYPE_BUY)
         // BUY: Stop Loss is BELOW entry price
         stopLoss = price - slDistance;
      else
         // SELL: Stop Loss is ABOVE entry price
         stopLoss = price + slDistance;

      // Round to correct decimal places for this symbol
      stopLoss = NormalizeDouble(stopLoss, digits);
   }
```

**Explanation:**
- **Pips vs Points**:
  - 1 pip = 10 points (on 5-digit broker)
  - EUR/USD: 1.10500 → 1.10510 = 1 pip = 10 points
- **slDistance**: Distance from entry to SL in price terms
- **BUY SL logic**: Loss occurs when price drops → SL below entry
- **SELL SL logic**: Loss occurs when price rises → SL above entry
- **NormalizeDouble()**: Rounds to broker's required precision
- **InpStopLossPips = 0**: Disables SL (stopLoss remains 0)

---

## Part 24: OpenTrade() Function - Part C: Calculate Take Profit

**What is this?** Calculates Take Profit price if enabled.

**Why?** Defines profit target - alternative to trailing with MA exits.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 24 calculates take profit using the exact same logic as stop loss, but in the opposite direction. We convert pips to price distance, then for buy orders, place the take profit above the entry price since profits occur when price rises, while for sell orders, we place it below the entry price since profits occur when price falls. This gives you the flexibility to use fixed profit targets instead of or in addition to the moving average exit rules. Setting take profit to zero means you'll rely entirely on the MA crosses for your exits, letting trends run as long as they remain valid."

```mql5
   // Calculate Take Profit if specified (InpTakeProfitPips > 0)
   if(InpTakeProfitPips > 0)
   {
      // Convert pips to price distance (same logic as SL)
      double tpDistance = InpTakeProfitPips * point * 10;

      if(orderType == ORDER_TYPE_BUY)
         // BUY: Take Profit is ABOVE entry price
         takeProfit = price + tpDistance;
      else
         // SELL: Take Profit is BELOW entry price
         takeProfit = price - tpDistance;

      // Round to correct decimal places
      takeProfit = NormalizeDouble(takeProfit, digits);
   }
```

**Explanation:**
- **tpDistance**: Distance from entry to TP in price terms
- **BUY TP logic**: Profit when price rises → TP above entry
- **SELL TP logic**: Profit when price drops → TP below entry
- **Opposite of SL**:
  - BUY: SL below, TP above
  - SELL: SL above, TP below
- **InpTakeProfitPips = 0**: No TP, exit only on MA cross
- **Flexibility**: Can use TP for fixed target OR MA for dynamic exit

---

## Part 25: OpenTrade() Function - Part D: Execute Trade and Log Result

**What is this?** Sends order to broker and logs the outcome.

**Why?** Actually places the trade and provides feedback on success/failure.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 25 completes our OpenTrade function by actually executing the order and logging the result. We call either trade.Buy or trade.Sell depending on the order type, passing in our lot size, symbol, entry price, stop loss, take profit, and trade comment. Both methods return a boolean indicating success or failure. If the trade succeeds, we log comprehensive details including the order type, lot size, and the stop loss and take profit levels, displaying none if they're disabled. If the trade fails, we log the error code and description from the broker, which helps with troubleshooting issues like insufficient margin or invalid parameters."

```mql5
   // Execute the trade using CTrade object
   bool result = false;

   if(orderType == ORDER_TYPE_BUY)
      // Open BUY position
      // Parameters: volume, symbol, price, stop_loss, take_profit, comment
      result = trade.Buy(InpLotSize, _Symbol, price, stopLoss, takeProfit, InpTradeComment);
   else
      // Open SELL position
      result = trade.Sell(InpLotSize, _Symbol, price, stopLoss, takeProfit, InpTradeComment);

   // Check if trade was successful
   if(result)
   {
      // Trade opened successfully - log details
      Print("Trade opened: ", EnumToString(orderType), " Lots: ", InpLotSize,
            " SL: ", (stopLoss > 0 ? DoubleToString(stopLoss, digits) : "None"),
            " TP: ", (takeProfit > 0 ? DoubleToString(takeProfit, digits) : "None"));
   }
   else
   {
      // Trade failed - log error details
      Print("Trade failed: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
   }
}
```

**Explanation:**
- **trade.Buy()/trade.Sell()**: CTrade methods to open positions
  - Returns true if successful, false if failed
- **Parameters in order**:
  1. Volume (lot size)
  2. Symbol
  3. Entry price
  4. Stop Loss (0 = none)
  5. Take Profit (0 = none)
  6. Comment
- **EnumToString()**: Converts ORDER_TYPE_BUY to "ORDER_TYPE_BUY" text
- **Ternary in Print**: Shows "None" if SL/TP = 0
- **ResultRetcode()**: Error code if trade failed (e.g., 10006 = request rejected)
- **ResultRetcodeDescription()**: Human-readable error message

---

## Part 26: ManageOpenPosition() Function - Part A: Initialize and Get Data

**What is this?** Manages existing positions - checks if they should be closed.

**Why?** Exit strategy is critical - determines profit/loss outcomes.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 26 introduces our ManageOpenPosition function, which runs every bar while we have an open trade. We first double-check that the position still exists, since it could have been closed by stop loss or take profit hitting. We increment our bars in trade counter, which tracks how long we've been holding the position. Then we retrieve the position type to know if we're managing a buy or sell, get the latest closing price and moving average values from the completed bar, and initialize our exit control variables that will determine whether and why we should close the trade."

```mql5
//+------------------------------------------------------------------+
//| Manage open position                                             |
//+------------------------------------------------------------------+
void ManageOpenPosition()
{
   // Double-check that position still exists
   // (could have been closed by SL/TP)
   if(!PositionSelect(_Symbol))
      return;

   // Increment the bars-in-trade counter
   // Called once per bar while position is open
   barsInTrade++;

   // Get position information
   long posType = PositionGetInteger(POSITION_TYPE);  // BUY or SELL

   // Get current price and MA data (from completed bar)
   double close = iClose(_Symbol, PERIOD_CURRENT, 1);
   double fastMA = fastMABuffer[1];
   double slowMA = slowMABuffer[1];

   // Variables to control exit logic
   bool shouldExit = false;
   string exitReason = "";
```

**Explanation:**
- **PositionSelect()**: Returns false if position already closed
  - Could close from SL/TP hit
- **barsInTrade++**: Increments each bar
  - Used for max bars exit condition
- **POSITION_TYPE**: Returns POSITION_TYPE_BUY or POSITION_TYPE_SELL
- **Index [1]**: Again using completed bar, not forming bar
- **shouldExit flag**: Tracks if any exit condition met
- **exitReason**: For logging why position closed

---

## Part 27: ManageOpenPosition() Function - Part B: Check BUY Exit Conditions

**What is this?** Checks if BUY position should exit based on MA crosses.

**Why?** When uptrend ends (price crosses below MA), we exit to preserve profits.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 27 checks exit conditions for buy positions based on moving average crosses. If we're in a buy trade and the fast MA exit is enabled, we check if the closing price has dropped below the fast moving average, signaling the uptrend is weakening. Alternatively, if slow MA exit is enabled, we check if price crossed below the slow MA for a later exit that lets trends run longer. These work as an OR condition, meaning either one can trigger the exit. We set the should exit flag and record which condition triggered so we have detailed logging of why each trade closed."

```mql5
   // Check exit conditions based on position type
   if(posType == POSITION_TYPE_BUY)
   {
      // BUY EXIT CONDITION 1: Price crossed below Fast MA
      if(InpExitOnFastMA && close < fastMA)
      {
         shouldExit = true;
         exitReason = "Close below Fast MA";
      }
      // BUY EXIT CONDITION 2: Price crossed below Slow MA
      else if(InpExitOnSlowMA && close < slowMA)
      {
         shouldExit = true;
         exitReason = "Close below Slow MA";
      }
   }
```

**Explanation:**
- **posType == POSITION_TYPE_BUY**: Only execute for BUY positions
- **InpExitOnFastMA**: User setting to enable/disable fast MA exit
- **close < fastMA**: Price crossed below fast MA (trend weakening)
- **else if**: OR condition - exit on EITHER fast OR slow MA
  - If both enabled, fast MA triggers first (more sensitive)
- **exitReason**: Records which condition triggered exit
- **Logic**:
  - Fast MA = early exit (more responsive)
  - Slow MA = late exit (lets trend run longer)

---

## Part 28: ManageOpenPosition() Function - Part C: Check SELL Exit Conditions

**What is this?** Checks if SELL position should exit based on MA crosses.

**Why?** When downtrend ends (price crosses above MA), exit to lock in profits.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 28 implements the sell exit conditions, which mirror the buy logic with inverted comparisons. For sell positions, we're looking for price to cross back above the moving averages, which signals the downtrend is ending. If fast MA exit is enabled and price closes above the fast MA, we trigger an exit. If slow MA exit is enabled and price crosses above the slow MA, that's an alternative exit trigger. This symmetrical structure ensures we treat long and short positions consistently, exiting when the trend that justified our entry begins to reverse."

```mql5
   else // POSITION_TYPE_SELL
   {
      // SELL EXIT CONDITION 1: Price crossed above Fast MA
      if(InpExitOnFastMA && close > fastMA)
      {
         shouldExit = true;
         exitReason = "Close above Fast MA";
      }
      // SELL EXIT CONDITION 2: Price crossed above Slow MA
      else if(InpExitOnSlowMA && close > slowMA)
      {
         shouldExit = true;
         exitReason = "Close above Slow MA";
      }
   }
```

**Explanation:**
- **else**: Must be POSITION_TYPE_SELL (only two types exist)
- **Mirror logic of BUY**:
  - `<` becomes `>` (above instead of below)
  - "below" becomes "above" in reason
- **close > fastMA**: Price crossed above MA (downtrend ending)
- **Symmetry**: Same structure as BUY ensures consistent behavior
- **SELL logic**:
  - Entered when price below MAs
  - Exit when price crosses back above MAs
  - Captures the downtrend movement

---

## Part 29: ManageOpenPosition() Function - Part D: Time-Based Exit

**What is this?** Forces exit after maximum number of bars in trade.

**Why?** Prevents holding positions indefinitely - especially important for losing trades.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 29 adds a time-based exit that forces the position to close after a maximum number of bars, regardless of profit or loss. We check if this feature is enabled by testing if the max bars parameter is greater than zero, then compare our bars in trade counter against that limit. If we've held the position too long, we set the should exit flag and use StringFormat to create a descriptive exit reason that includes the actual bar limit. This is particularly useful for preventing positions from being held indefinitely when the trend stalls, and it can help enforce trading discipline by limiting your exposure time."

```mql5
   // Time-based exit - force close after max bars
   if(InpMaxBarsInTrade > 0 && barsInTrade >= InpMaxBarsInTrade)
   {
      shouldExit = true;
      exitReason = StringFormat("Max bars in trade (%d)", InpMaxBarsInTrade);
   }
```

**Explanation:**
- **InpMaxBarsInTrade > 0**: Feature enabled (0 = disabled)
- **barsInTrade >= InpMaxBarsInTrade**: Held too long
  - Example: Set to 50, current = 50 → trigger exit
- **StringFormat()**: Creates formatted string with variable
  - Shows actual max bars value in reason
- **Use cases**:
  - Prevent holding overnight (set to bars per day)
  - Cut losses on stalled trades
  - Enforce trading discipline
- **Note**: Can trigger even if MA exit hasn't occurred

---

## Part 30: ManageOpenPosition() Function - Part E: Execute Exit

**What is this?** Closes the position if any exit condition met.

**Why?** Actually closes the trade and logs the result for analysis.

### 🎙️ Narration (Text-to-Speech Ready):
"Part 30 executes the exit if any of our conditions were triggered. We check the should exit flag, and if it's true, we retrieve the current profit or loss using PositionGetDouble. Then we log comprehensive exit information including the specific reason for closing, the final profit or loss amount, and how many bars we held the trade. Finally, we call trade.PositionClose to close the position at the current market price. This detailed logging is invaluable for post-trade analysis and strategy optimization, helping you understand which exit rules are working best."

```mql5
   // Execute exit if any condition was met
   if(shouldExit)
   {
      // Get final profit/loss amount
      double profit = PositionGetDouble(POSITION_PROFIT);

      // Log exit details
      Print("=== CLOSING POSITION ===");
      Print("Reason: ", exitReason, " | Profit: ", DoubleToString(profit, 2),
            " | Bars in trade: ", barsInTrade);

      // Close the position
      trade.PositionClose(_Symbol);
   }
}
```

**Explanation:**
- **shouldExit**: True if any exit condition triggered
- **PositionGetDouble(POSITION_PROFIT)**: Gets current P&L in account currency
  - Positive = profit
  - Negative = loss
- **Print**: Logs comprehensive exit data
  - Why we exited (MA cross, max bars, etc.)
  - Final profit/loss
  - How long we held the trade
- **trade.PositionClose()**: Closes position at market price
  - BUY closes at BID
  - SELL closes at ASK
- **Analysis value**: Exit logs help optimize strategy

---

## Part 31: Complete Code Assembly

**Important!** When you assemble all the parts above in order (Part 1 → Part 30), you will have the complete, functional EA. Here's a verification checklist:

### 🎙️ Narration (Text-to-Speech Ready):
"Part 31 wraps up our tutorial with assembly instructions and verification steps. When you combine all thirty parts in order, from the file header through to the exit logic, you'll have a complete, functional Expert Advisor ready to compile and test. The code totals around 319 lines and includes seven main functions: OnInit for setup, OnDeinit for cleanup, OnTick as the main loop, IsNewBar for candle detection, CheckForEntry for analyzing setups, OpenTrade for order execution, and ManageOpenPosition for exit logic. Before running it, verify that all opening braces have matching closing braces, all parameters are present, and the code structure matches the outline provided. This modular approach makes the EA easy to understand, maintain, and customize for your specific trading needs."

### Assembly Instructions:
1. Start with Part 1 (File Header)
2. Add Part 2-7 (All Input Parameters)
3. Add Part 8 (Global Variables)
4. Add Part 9-10 (OnInit Function)
5. Add Part 11 (OnDeinit Function)
6. Add Part 12-14 (OnTick Function)
7. Add Part 15 (IsNewBar Function)
8. Add Part 16-21 (CheckForEntry Function)
9. Add Part 22-25 (OpenTrade Function)
10. Add Part 26-30 (ManageOpenPosition Function)

### Verification:
- Total lines: ~319
- Functions: OnInit(), OnDeinit(), OnTick(), IsNewBar(), CheckForEntry(), OpenTrade(), ManageOpenPosition()
- All opening braces `{` have matching closing braces `}`
- All input parameters, global variables, and logic blocks are present

### Code Structure Summary:
```
Header & Includes
├─ Input Parameters (grouped)
├─ Global Variables
├─ OnInit() - Setup
├─ OnDeinit() - Cleanup
├─ OnTick() - Main loop
│   ├─ Calls IsNewBar()
│   ├─ Calls ManageOpenPosition() OR CheckForEntry()
├─ IsNewBar() - Bar detection
├─ CheckForEntry() - Entry logic
│   └─ Calls OpenTrade()
├─ OpenTrade() - Execute orders
└─ ManageOpenPosition() - Exit logic
```

This completes your MQL5 tutorial breakdown. Each part can be explained separately in your YouTube video, and when combined, forms the complete working EA!
