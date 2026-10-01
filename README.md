# 🥇 XAUUSD Gold Scalping Trading Bot — MT5

An automated **Gold (XAUUSD) scalping Expert Advisor (EA) for MetaTrader 5 (MT5)** designed to identify short-term trading opportunities using technical indicators, market-condition filters, risk management, and automated trade execution.

> ⚠️ **Risk Warning:** This project is for educational and research purposes. No trading bot can guarantee profits or a high win rate. Always backtest and forward-test on a demo account before using real funds.

---

## 🚀 Features

* 🥇 **XAUUSD / Gold Trading**
* ⚡ Short-term scalping strategy
* 📊 Technical indicator-based entry signals
* 🧠 Market-condition detection
* 🛡️ Spread & volatility filters
* 📈 Trend confirmation
* 🚫 Avoid trading during unfavorable market conditions
* 💰 Configurable risk management
* 🎯 Stop Loss & Take Profit
* 🔄 Automatic trade execution
* 📉 Maximum daily loss protection
* 🔢 Maximum open trades control
* 🕐 Trading-session filters
* 📰 Optional high-impact news filter
* 📋 Detailed trading logs
* 🧪 Backtesting support through MT5 Strategy Tester

---

## 🧠 Trading Logic

The EA evaluates multiple conditions before opening a trade.

### Buy Conditions

A BUY signal can be generated when:

```text
Trend Confirmation
        ↓
Momentum Confirmation
        ↓
Volatility Check
        ↓
Spread Check
        ↓
Trading Session Check
        ↓
Risk Validation
        ↓
BUY
```

### Sell Conditions

A SELL signal can be generated when:

```text
Trend Confirmation
        ↓
Momentum Confirmation
        ↓
Volatility Check
        ↓
Spread Check
        ↓
Trading Session Check
        ↓
Risk Validation
        ↓
SELL
```

The exact strategy parameters should be optimized and validated using historical and forward-testing data rather than assuming a fixed win rate.

---

## 🛡️ Risk Management

Risk management is a core part of the EA.

The bot can include:

* Risk percentage per trade
* Maximum daily drawdown
* Maximum consecutive losses
* Maximum open positions
* Maximum spread
* Stop Loss
* Take Profit
* Break-even protection
* Trailing Stop
* Trading-session restrictions
* Volatility protection

Example:

```text
Account Balance: $1,000
Risk Per Trade: 1%

Maximum planned risk ≈ $10
```

Actual risk depends on the broker's contract specifications, stop-loss distance, lot size, spread, and execution.

---

## ⚡ Market Risk Protection

Gold can experience rapid price movements, especially around major economic events.

The EA can therefore use protection such as:

```text
High Volatility
      ↓
Market Condition Check
      ↓
Trading Disabled
```

Possible filters include:

* ATR volatility filter
* Spread filter
* Abnormal candle detection
* Trading-session filter
* High-impact news filter
* Maximum drawdown protection

---

## 📊 Suggested Indicators

The strategy can combine indicators such as:

* EMA
* RSI
* ATR
* ADX
* MACD
* Bollinger Bands
* Support & Resistance
* Price Action

Indicators should be used as confirmation rather than relying on a single indicator.

---

## 🖥️ Requirements

### MetaTrader 5

Required:

* MetaTrader 5
* MQL5 Expert Advisor
* Broker supporting XAUUSD
* Stable internet/VPS for automated execution

Recommended:

* Low-spread account
* Reliable execution
* VPS located close to the broker's trading server

---

## 📂 Project Structure

```text
XAUUSD-Scalping-Bot/
│
├── EA/
│   └── XAUUSD_Scalper.mq5
│
├── Indicators/
│   └── CustomIndicators.mq5
│
├── Backtests/
│   └── reports/
│
├── Presets/
│   └── XAUUSD.set
│
├── Documentation/
│   └── Strategy.md
│
└── README.md
```

---

## ⚙️ Installation

### 1. Download the EA

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/XAUUSD-Scalping-Bot.git
```

### 2. Open MetaTrader 5

Go to:

```text
File → Open Data Folder
```

Then navigate to:

```text
MQL5 → Experts
```

Copy the EA file into the folder.

### 3. Compile

Open:

```text
MetaEditor
```

Open:

```text
XAUUSD_Scalper.mq5
```

Click:

```text
Compile
```

### 4. Attach EA

In MT5:

```text
Navigator
→ Expert Advisors
→ XAUUSD Scalper
```

Attach it to the appropriate **XAUUSD** chart.

Enable:

```text
Algo Trading
```

---

## 🧪 Backtesting

Before using a live account, test the EA using:

```text
MT5
→ View
→ Strategy Tester
```

Recommended testing process:

```text
Historical Backtest
        ↓
Parameter Validation
        ↓
Out-of-Sample Test
        ↓
Demo Forward Test
        ↓
Small Live Test
```

Do not optimize parameters only for historical profit. Excessive optimization can produce **overfitting**, where the strategy performs well on historical data but poorly on unseen market conditions.

---

## 📈 Performance Metrics

When testing the EA, monitor:

| Metric             | Description                     |
| ------------------ | ------------------------------- |
| Net Profit         | Overall strategy result         |
| Profit Factor      | Gross profit / gross loss       |
| Win Rate           | Percentage of profitable trades |
| Maximum Drawdown   | Largest account decline         |
| Recovery Factor    | Return relative to drawdown     |
| Average Trade      | Average result per trade        |
| Sharpe Ratio       | Risk-adjusted performance       |
| Number of Trades   | Sample size                     |
| Consecutive Losses | Losing streak                   |
| Expected Payoff    | Average expected result         |

A high win rate alone does **not** mean a strategy is safe or profitable.

---

## ⚙️ Example Settings

```text
Symbol              = XAUUSD
Timeframe           = M1 / M5
RiskPerTrade        = 0.50%
MaxOpenTrades       = 1
MaxDailyLoss        = 3%
MaxSpread           = Configurable
StopLoss            = ATR Based
TakeProfit          = Risk/Reward Based
TrailingStop        = Enabled
BreakEven            = Enabled
NewsFilter          = Enabled
VolatilityFilter    = Enabled
```

These are example configuration values, not guaranteed optimal settings.

---

## 🧠 Smart Trading Protection

The EA should **not trade continuously**.

It can skip trades when:

```text
Spread Too High
       OR
Volatility Too High
       OR
Daily Loss Limit Reached
       OR
News Event Active
       OR
Trading Session Disabled
       OR
Market Conditions Invalid
```

This helps prevent the EA from entering trades simply because a technical indicator generated a signal.

---

## 🖥️ VPS Deployment

For 24/7 automated execution, the EA can be deployed on a Windows VPS.

Recommended setup:

```text
Windows VPS
     ↓
MetaTrader 5
     ↓
XAUUSD Chart
     ↓
Expert Advisor
     ↓
Broker
```

Make sure the VPS is stable and the EA reconnects correctly after MT5 or network interruptions.

---

## 🔐 Security

Never commit sensitive information to GitHub.

Do **NOT** upload:

```text
.env
Broker passwords
Trading account credentials
API keys
News API keys
Private configuration files
```

Use environment variables or secure configuration where applicable.

---

## 📌 Development Roadmap

* [x] MT5 Expert Advisor foundation
* [x] XAUUSD support
* [x] Entry/exit framework
* [x] Risk management framework
* [ ] Advanced volatility detection
* [ ] Economic news integration
* [ ] Adaptive market-regime detection
* [ ] Advanced trade management
* [ ] Telegram notifications
* [ ] Web dashboard
* [ ] Performance analytics
* [ ] Multi-symbol support

---

## 📊 Future Architecture

```text
                 ┌─────────────────┐
                 │   Market Data   │
                 └────────┬────────┘
                          ↓
                 ┌─────────────────┐
                 │ Market Regime   │
                 │    Detection    │
                 └────────┬────────┘
                          ↓
                 ┌─────────────────┐
                 │ Signal Engine   │
                 └────────┬────────┘
                          ↓
                 ┌─────────────────┐
                 │ Risk Management │
                 └────────┬────────┘
                          ↓
                 ┌─────────────────┐
                 │ Trade Manager   │
                 └────────┬────────┘
                          ↓
                 ┌─────────────────┐
                 │    MT5 Broker   │
                 └─────────────────┘
```

---

## ⚠️ Disclaimer

This software is provided for **educational and research purposes only**.

Trading XAUUSD and other financial instruments involves substantial risk of loss. Historical backtest results do not guarantee future performance.

The developer does not guarantee:

* A specific win rate
* Guaranteed profits
* Guaranteed monthly returns
* No losing trades
* Protection from market gaps
* Protection from broker execution issues

Use appropriate risk management and test the EA thoroughly before deploying it with real capital.

---

## ⭐ Contributing

Contributions, suggestions, bug reports, and strategy improvements are welcome.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the changes
5. Submit a Pull Request

---

## 📜 License

This project is intended for educational and research purposes.

Add your preferred open-source license before publishing commercially.

---

## 👨‍💻 Author

**Muzamil Khan**

**Tech Explorer | Software Developer**

GitHub:
https://github.com/Zaibten

---

### ⭐ If you find this project useful

Give the repository a ⭐ and follow the project for future updates!

**Built for systematic XAUUSD research, testing, and automated execution on MetaTrader 5.**
