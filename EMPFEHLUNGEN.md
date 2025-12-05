# Trading Empfehlungen für MA Trend Follower EA

## 📊 Beste Trending-Instrumente (2024-2025)

### Top Forex Pairs für Trend-Following

1. **EUR/JPY, NZD/USD, AUD/USD** - Laut Trendedness-Analyse die trendstärksten Paare
2. **EUR/USD** - Längste konsekutive Tage über/unter MAs
3. **GBP/USD** - Zweitbeste Trendstabilität
4. **JPY-Crosses** (AUD/JPY, GBP/JPY, NZD/JPY) - Hohe Volatilität + gute Trends

### Indizes

- **US30, NAS100, S&P500** - Natürliche Aufwärtsbias, lange Trends
- Besonders geeignet für Long-Only Trading

---

## ⚙️ MA-Einstellungen nach Trading-Stil

### Swing Trading (EMPFOHLEN)

- **MAs**: 20/50 EMA - Beste Balance zwischen Responsiveness und Stabilität
- **Timeframe**: H1 oder H4 - Medium-term trends ohne Short-term noise
- **Vorteil**: Hält dich in Trades mehrere Tage/Wochen

### Day Trading (schnellere Trades)

- **MAs**: 10/20 EMA oder 9/21 EMA - Schnellere Signale
- **Timeframe**: M15 oder H1
- **Vorteil**: Mehr Trades
- **Nachteil**: Auch mehr False Signals

### Position Trading (langfristig)

- **MAs**: 50/200 EMA - Für große Trends, wenig Noise
- **Timeframe**: D1 (Daily)
- **Vorteil**: Wenige aber hochwertige Trades

---

## 🎯 Konkrete Test-Setups

### Setup 1: Swing Trading (Best Starting Point)

**Empfohlen für Anfang!**

```
Instrumente:     EUR/JPY, AUD/USD, EUR/USD
Timeframe:       H1 oder H4
Fast MA:         20 EMA
Slow MA:         50 EMA
MA Method:       EMA
Allow Buy:       true
Allow Sell:      true
Exit on Fast MA: true
Exit on Slow MA: false
Min Bars Above:  1
Stop Loss:       100 pips (oder 0 für nur MA-Exit)
Take Profit:     0 (disabled, nur MA-Exit)
```

**Warum**: Beste Balance zwischen Trade-Frequenz und Trend-Qualität

---

### Setup 2: Indizes Long-Only

**Für US30, NAS100, S&P500**

```
Instrumente:     US30, NAS100
Timeframe:       H4 oder D1
Fast MA:         20 EMA
Slow MA:         50 EMA
MA Method:       EMA
Allow Buy:       true
Allow Sell:      false  ← NUR LONGS
Exit on Fast MA: true
Exit on Slow MA: false (oder true testen)
Min Bars Above:  1
Stop Loss:       200 pips (wegen höherer Volatilität)
Take Profit:     0
```

**Warum**: Indizes haben natürliche Aufwärtsbias, Long-Only reduziert Whipsaws

---

### Setup 3: Aggressive JPY-Crosses

**Für erfahrenere Trader**

```
Instrumente:     AUD/JPY, GBP/JPY, NZD/JPY
Timeframe:       H1
Fast MA:         10 EMA
Slow MA:         20 EMA  ← Schnellere MAs
MA Method:       EMA
Allow Buy:       true
Allow Sell:      true
Exit on Fast MA: true
Exit on Slow MA: false
Min Bars Above:  1
Stop Loss:       150 pips
Take Profit:     0
```

**Warum**: JPY-Pairs sind volatil und trenden gut, schnellere MAs fangen mehr Bewegung ein

---

## 💡 Optimierungs-Tipps

### Was testen?

1. **Timeframe-Variation**: H1 vs H4 vs D1
2. **Exit-Strategie**: Fast MA vs Slow MA vs beide
3. **Min Bars Above MA**: 0 (instant) vs 1 vs 2 (mehr Bestätigung)
4. **Stop Loss**: Eng (50-100) vs Weit (200+) vs Keins (0)

### Was NICHT ändern (am Anfang)

- MA Perioden (20/50 ist bewährt)
- MA Method (EMA ist Standard für Trend-Following)
- Require Both MA (true halten für saubere Trends)

---

## 📈 Backtesting-Strategie

1. **Start**: Setup 1 mit EUR/JPY auf H4, 1-2 Jahre backtesten
2. **Analyse**: Win-Rate, Profit Factor, Max Drawdown checken
3. **Optimierung**: Nur 1 Parameter gleichzeitig ändern
4. **Validierung**: Auf anderem Instrument/Zeitraum testen
5. **Forward Test**: Demo Account mit echten Daten

---

## ⚠️ Wichtige Hinweise

### Wann funktioniert die Strategie NICHT?

- **Ranging Markets**: Bei seitwärts-laufenden Märkten viele False Signals
- **Hohe Volatilität**: News-Events können zu Whipsaws führen
- **Overnight Gaps**: Besonders bei Indizes am Wochenende

### Risiko-Management

- **Lot Size**: Nicht mehr als 1-2% Risiko pro Trade
- **Correlation**: Nicht gleichzeitig EUR/JPY und GBP/JPY traden (korreliert)
- **Max Drawdown**: Bei >20% Settings überprüfen

---

## 📚 Quellen

Diese Empfehlungen basieren auf Recherche aktueller Trend-Following Strategien (2024-2025):

- [Which Forex Pair Trends the Most — 2025 Data](https://www.earnforex.com/guides/which-forex-pair-trends-the-most/)
- [Most Trending Currency Pairs in 2025](https://fxssi.com/most-trendy-currency-pairs)
- [Top 10 Most Volatile Currency Pairs 2024](https://justmarkets.com/trading-articles/forex/top-10-most-volatile-currency-pairs-in-2024)
- [Exponential Moving Average: Best Settings](https://www.xs.com/en/blog/exponential-moving-average/)
- [Best Moving Average Settings Based on Trading Style](https://acy.com/en/market-news/education/market-education-moving-averages-best-settings-j-o-20250723-093921/)
- [5 Best Moving Average Indicators 2025 Guide](https://www.mindmathmoney.com/articles/best-moving-average-indicators-amp-settings-for-tradingview-the-complete-trading-strategy-guide)
- [How To Use Moving Averages - Moving Average Trading 101](https://tradeciety.com/how-to-use-moving-averages)
- [Moving Average Trading Strategy](https://www.tradingwithrayner.com/moving-average-indicator-strategy/)

---

**Viel Erfolg beim Trading! 🚀**
