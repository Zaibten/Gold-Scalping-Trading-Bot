//+------------------------------------------------------------------+
//|                                              GoldScalperEA.mq5     |
//|   Gold (XAUUSD) Multi-TF Cascade Scalper – Professional Edition   |
//|   Cascade : D1 → H4 → H1 → M30 → M5 → M1                          |
//|   High-selectivity design for elevated win-rate potential         |
//|                                                                   |
//|   ⚠️  RUN ON DEMO FIRST. No strategy guarantees profit.           |
//+------------------------------------------------------------------+
#property copyright "Educational use only. Not financial advice."
#property version   "3.00"
#property description "Strict multi-TF cascade + RSI pullback + ATR/swing stops + confluence filters. DEMO FIRST."

#include <Trade/Trade.mqh>
CTrade trade;

//============================ INPUTS ===============================
input group "=== Multi-TF Cascade (D1 → H4 → H1 → M30 → M5 → M1) ==="
input ENUM_TIMEFRAMES TradeTF          = PERIOD_M1;   // Entry / scalp TF
input int             FastEMA          = 21;
input int             SlowEMA          = 50;
input int             TrendEMA         = 200;         // used on every TF
input bool            RequireFullCascade = true;      // ALL TFs must align (recommended)
input bool            RequireEntryTFTrend = true;     // price must be on correct side of TrendEMA on TradeTF
input bool            UseEMASlopeFilter = true;       // FastEMA must be sloping in trade direction

input group "=== RSI Pullback ==="
input int             RSIPeriod        = 14;
input double          RSILongLevel     = 42.0;        // stricter → higher quality longs
input double          RSIShortLevel    = 58.0;        // stricter → higher quality shorts

input group "=== Trend Strength & Volatility ==="
input bool            UseADX           = true;
input int             ADXPeriod        = 14;
input double          ADXMin           = 23.0;        // skip weak / choppy markets
input double          MinATRPoints     = 8.0;         // skip extremely low volatility (in points)

input group "=== Confluence Filters ==="
input bool            RequireCandleConfirm = true;    // last closed candle must be in trade direction
input double          MaxEMADistanceATR = 2.8;        // skip if price is too far from FastEMA (in ATR)

input group "=== Risk / Exits ==="
input double          SL_ATR_Mult      = 1.35;
input double          RewardRisk       = 2.0;         // 1:2 RR
input bool            UseRiskSizing    = true;
input double          FixedLot         = 0.01;
input double          RiskPercent      = 0.8;         // slightly more conservative
input double          MaxLot           = 0.40;
input int             MaxHoldHours     = 6;           // tighter for M1 scalping

input group "=== Swing structure (SL/TP) ==="
input bool            UseSwingStops    = true;
input int             SwingLookback    = 4;
input int             SwingScanBars    = 35;
input double          SwingBufferATR   = 0.22;
input double          SwingSLCapATR    = 2.3;

input group "=== Trailing / Breakeven ==="
input bool            UseTrailing      = false;       // keep off until thoroughly tested
input double          TrailActivate    = 4.0;
input double          TrailGiveback    = 2.0;
input bool            UseBreakeven     = true;
input double          BreakevenActivate= 2.2;
input double          BreakevenLock    = 0.6;

input group "=== Daily & Loss Guards ==="
input double          MaxDailyLossPct  = 2.5;
input double          DailyProfitTarget= 3.5;
input int             MaxTradesPerDay  = 5;           // quality over quantity
input int             MaxOpenPositions = 1;
input int             MaxConsecutiveLosses = 3;       // cool-down after X losses in a row
input int             CoolDownMinutes  = 45;

input group "=== Session & Spread ==="
input int             TradeStartHour   = 7;           // server time
input int             TradeEndHour     = 20;
input int             MaxSpreadPoints  = 30;          // tighter for gold

input group "=== Misc ==="
input long            MagicNumber      = 990014;
input string          TradeComment     = "GoldMTF_v3";
input bool            EnableDebugPrint = false;       // turn off in live for less log spam

input group "=== Telegram ==="
input bool            EnableTelegram   = true;
input string          TelegramToken    = "";
input string          TelegramChatID   = "7758500311";
input int             TelegramPollSec  = 5;

input group "=== Trade logging ==="
input bool            EnableTradeLog   = true;
input string          TradeLogFile     = "GoldScalperEA_trades_v3.csv";

//============================ GLOBALS ==============================
int hEmaFast = INVALID_HANDLE, hEmaSlow = INVALID_HANDLE, hRSI = INVALID_HANDLE;
int hATR = INVALID_HANDLE, hADX = INVALID_HANDLE;
int hD1 = INVALID_HANDLE, hH4 = INVALID_HANDLE, hH1 = INVALID_HANDLE;
int hM30 = INVALID_HANDLE, hM5 = INVALID_HANDLE, hM1 = INVALID_HANDLE;

datetime lastBarTime     = 0;
double   dailyStartEquity = 0.0;
int      dayOfTracking   = -1;
int      tradesToday     = 0;
bool     haltedToday     = false;

string   g_regime        = "warming up";
double   g_rsiNow        = 0.0;
string   g_waiting       = "menunggu data...";
string   g_cascade       = "-";

string   g_tgQueue[];
string   g_tgToken       = "";
bool     g_paused        = false;
long     g_lastUpdateId  = 0;

// Entry snapshot for logging
bool     g_eHasOpen      = false;
ulong    g_trailTicket   = 0;
double   g_peakProfit    = 0;
bool     g_trailArmed    = false;
bool     g_trailClosing  = false;
datetime g_eTime         = 0;
string   g_eDir = "", g_eRegime = "";
double   g_ePrice = 0, g_eSL = 0, g_eTP = 0, g_eLot = 0;
double   g_eRSI = 0, g_eATR = 0, g_eSwingDist = 0;
double   g_eEmaGap = 0, g_eTrendDist = 0;
int      g_eHour = 0, g_eDow = 0, g_eSpread = 0;

// Consecutive loss cool-down
int      consecutiveLosses = 0;
datetime coolDownUntil     = 0;

// Feature values (fixed missing declarations)
double   g_featEmaGap    = 0;
double   g_featTrendDist = 0;

//============================ INIT / DEINIT ========================
int OnInit()
{
   //--- Indicators
   hEmaFast = iMA(_Symbol, TradeTF, FastEMA, 0, MODE_EMA, PRICE_CLOSE);
   hEmaSlow = iMA(_Symbol, TradeTF, SlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   hRSI     = iRSI(_Symbol, TradeTF, RSIPeriod, PRICE_CLOSE);
   hATR     = iATR(_Symbol, TradeTF, 14);
   hADX     = iADX(_Symbol, TradeTF, ADXPeriod);

   hD1  = iMA(_Symbol, PERIOD_D1,  TrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   hH4  = iMA(_Symbol, PERIOD_H4,  TrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   hH1  = iMA(_Symbol, PERIOD_H1,  TrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   hM30 = iMA(_Symbol, PERIOD_M30, TrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   hM5  = iMA(_Symbol, PERIOD_M5,  TrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   hM1  = iMA(_Symbol, PERIOD_M1,  TrendEMA, 0, MODE_EMA, PRICE_CLOSE);

   if(hEmaFast == INVALID_HANDLE || hEmaSlow == INVALID_HANDLE || hRSI == INVALID_HANDLE ||
      hATR == INVALID_HANDLE || hADX == INVALID_HANDLE ||
      hD1 == INVALID_HANDLE || hH4 == INVALID_HANDLE || hH1 == INVALID_HANDLE ||
      hM30 == INVALID_HANDLE || hM5 == INVALID_HANDLE || hM1 == INVALID_HANDLE)
   {
      Print("ERROR: indicator handles failed – check symbol & timeframe");
      return INIT_FAILED;
   }

   //--- Trade settings
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);
   trade.SetDeviationInPoints(25);

   //--- Basic input sanity
   if(FastEMA >= SlowEMA || SlowEMA >= TrendEMA)
   {
      Print("WARNING: EMA periods should be Fast < Slow < Trend");
   }
   if(RiskPercent <= 0 || RiskPercent > 5.0)
      Print("WARNING: RiskPercent outside recommended 0.3–2.0 range");

   ResetDaily();
   g_tgToken = (StringLen(TelegramToken) > 0) ? TelegramToken : ReadTokenFile();

   QueueTelegram(StringFormat("Gold Multi-TF Cascade v3 online | %s %s | D1→H4→H1→M30→M5→M1",
                              _Symbol, EnumToString(TradeTF)));

   if(EnableTelegram)
   {
      PollTelegram(false);
      EventSetTimer(MathMax(2, TelegramPollSec));
   }

   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(hEmaFast); IndicatorRelease(hEmaSlow);
   IndicatorRelease(hRSI); IndicatorRelease(hATR); IndicatorRelease(hADX);
   IndicatorRelease(hD1); IndicatorRelease(hH4); IndicatorRelease(hH1);
   IndicatorRelease(hM30); IndicatorRelease(hM5); IndicatorRelease(hM1);
   EventKillTimer();
   Comment("");
}

//============================ MAIN LOOP ============================
void OnTick()
{
   FlushTelegram();
   ManageDailyState();
   ManageOpenPositions();
   ManageTrailing();
   ManageBreakeven();
   UpdateDashboard();

   if(haltedToday || g_paused) return;
   if(TimeCurrent() < coolDownUntil) return;          // consecutive-loss cool-down
   if(!IsTradeSession()) return;

   // Only process on new bar of TradeTF (efficiency + no look-ahead)
   datetime t = iTime(_Symbol, TradeTF, 0);
   if(t == lastBarTime) return;
   lastBarTime = t;

   if(CountMyPositions() >= MaxOpenPositions) return;
   if(MaxTradesPerDay > 0 && tradesToday >= MaxTradesPerDay) return;
   if(CurrentSpreadPoints() > MaxSpreadPoints) return;

   CheckSignals();
}

//============================ MULTI-TF CASCADE =====================
bool GetCascadeBias(bool &bullBias, bool &bearBias, string &status)
{
   double d1[], h4[], h1[], m30[], m5[], m1[];
   ArraySetAsSeries(d1, true); ArraySetAsSeries(h4, true); ArraySetAsSeries(h1, true);
   ArraySetAsSeries(m30, true); ArraySetAsSeries(m5, true); ArraySetAsSeries(m1, true);

   if(CopyBuffer(hD1, 0, 0, 2, d1) < 2 || CopyBuffer(hH4, 0, 0, 2, h4) < 2 ||
      CopyBuffer(hH1, 0, 0, 2, h1) < 2 || CopyBuffer(hM30, 0, 0, 2, m30) < 2 ||
      CopyBuffer(hM5, 0, 0, 2, m5) < 2 || CopyBuffer(hM1, 0, 0, 2, m1) < 2)
      return false;

   // Use previous closed bar of TradeTF for consistency
   double c = iClose(_Symbol, TradeTF, 1);

   bool d1Bull = c > d1[1];  bool d1Bear = c < d1[1];
   bool h4Bull = c > h4[1];  bool h4Bear = c < h4[1];
   bool h1Bull = c > h1[1];  bool h1Bear = c < h1[1];
   bool m30Bull= c > m30[1]; bool m30Bear= c < m30[1];
   bool m5Bull = c > m5[1];  bool m5Bear = c < m5[1];
   bool m1Bull = c > m1[1];  bool m1Bear = c < m1[1];

   if(RequireFullCascade)
   {
      bullBias = d1Bull && h4Bull && h1Bull && m30Bull && m5Bull && m1Bull;
      bearBias = d1Bear && h4Bear && h1Bear && m30Bear && m5Bear && m1Bear;
   }
   else
   {
      int bullCnt = (d1Bull?1:0)+(h4Bull?1:0)+(h1Bull?1:0)+(m30Bull?1:0)+(m5Bull?1:0);
      int bearCnt = (d1Bear?1:0)+(h4Bear?1:0)+(h1Bear?1:0)+(m30Bear?1:0)+(m5Bear?1:0);
      bullBias = (bullCnt >= 4);
      bearBias = (bearCnt >= 4);
   }

   status = StringFormat("D1%s H4%s H1%s M30%s M5%s M1%s",
                         d1Bull?"▲":(d1Bear?"▼":"•"),
                         h4Bull?"▲":(h4Bear?"▼":"•"),
                         h1Bull?"▲":(h1Bear?"▼":"•"),
                         m30Bull?"▲":(m30Bear?"▼":"•"),
                         m5Bull?"▲":(m5Bear?"▼":"•"),
                         m1Bull?"▲":(m1Bear?"▼":"•"));
   return true;
}

//============================ SIGNALS ==============================
void CheckSignals()
{
   double emaFast[], emaSlow[], rsi[], atr[], adx[];
   ArraySetAsSeries(emaFast, true); ArraySetAsSeries(emaSlow, true);
   ArraySetAsSeries(rsi, true); ArraySetAsSeries(atr, true); ArraySetAsSeries(adx, true);

   if(CopyBuffer(hEmaFast, 0, 0, 4, emaFast) < 4) return;
   if(CopyBuffer(hEmaSlow, 0, 0, 3, emaSlow) < 3) return;
   if(CopyBuffer(hRSI, 0, 0, 3, rsi) < 3) return;
   if(CopyBuffer(hATR, 0, 0, 3, atr) < 3) return;
   if(UseADX && CopyBuffer(hADX, 0, 0, 2, adx) < 2) return;

   double closePrev = iClose(_Symbol, TradeTF, 1);
   double openPrev  = iOpen(_Symbol, TradeTF, 1);
   double ef = emaFast[1], es = emaSlow[1];
   double r1 = rsi[1], r2 = rsi[2];
   double a  = atr[1];

   if(a <= 0) return;

   // Minimum volatility filter
   double atrPoints = a / _Point;
   if(atrPoints < MinATRPoints) return;

   // Local micro trend
   bool microBull = (ef > es);
   bool microBear = (ef < es);

   // EMA slope filter (FastEMA rising/falling)
   bool slopeBull = true, slopeBear = true;
   if(UseEMASlopeFilter)
   {
      slopeBull = (emaFast[1] > emaFast[2]);
      slopeBear = (emaFast[1] < emaFast[2]);
   }

   // Full cascade
   bool bullBias = false, bearBias = false;
   string cascadeStatus;
   if(!GetCascadeBias(bullBias, bearBias, cascadeStatus)) return;
   g_cascade = cascadeStatus;

   // Entry TF TrendEMA confirmation
   bool entryTFBull = true, entryTFBear = true;
   if(RequireEntryTFTrend)
   {
      double trendEma[];
      ArraySetAsSeries(trendEma, true);
      // Re-use M1 handle if TradeTF == M1, otherwise we need a dedicated handle
      // For simplicity and efficiency we use the already-created hM1 when TradeTF is M1,
      // otherwise fall back to comparing against SlowEMA as proxy (or create extra handle if needed)
      if(TradeTF == PERIOD_M1)
      {
         double m1t[];
         ArraySetAsSeries(m1t, true);
         if(CopyBuffer(hM1, 0, 0, 2, m1t) >= 2)
         {
            entryTFBull = (closePrev > m1t[1]);
            entryTFBear = (closePrev < m1t[1]);
         }
      }
      else
      {
         // For other TFs we already have the cascade using TrendEMA; this is a secondary check
         entryTFBull = (closePrev > es);
         entryTFBear = (closePrev < es);
      }
   }

   // ADX strength
   bool strongTrend = true;
   if(UseADX) strongTrend = (adx[1] >= ADXMin);

   // Distance from FastEMA filter (avoid chasing)
   bool distanceOk = true;
   if(MaxEMADistanceATR > 0)
   {
      double dist = MathAbs(closePrev - ef);
      distanceOk = (dist <= MaxEMADistanceATR * a);
   }

   // Candle confirmation
   bool candleBull = true, candleBear = true;
   if(RequireCandleConfirm)
   {
      candleBull = (closePrev > openPrev);   // bullish body
      candleBear = (closePrev < openPrev);   // bearish body
   }

   // Final high-quality signals
   bool longSig  = microBull && slopeBull && bullBias && entryTFBull &&
                   strongTrend && distanceOk && candleBull &&
                   (r2 < RSILongLevel) && (r1 >= RSILongLevel);

   bool shortSig = microBear && slopeBear && bearBias && entryTFBear &&
                   strongTrend && distanceOk && candleBear &&
                   (r2 > RSIShortLevel) && (r1 <= RSIShortLevel);

   // Diagnostics
   g_rsiNow = r1;
   if(bullBias && microBull)      g_regime = "BULL cascade";
   else if(bearBias && microBear) g_regime = "BEAR cascade";
   else                           g_regime = "NO ALIGNMENT";

   if(!strongTrend)                g_waiting = "ADX weak – skip";
   else if(!distanceOk)            g_waiting = "Price too far from EMA";
   else if(!bullBias && !bearBias) g_waiting = "Cascade not aligned → " + cascadeStatus;
   else if(longSig)                g_waiting = "LONG SIGNAL";
   else if(shortSig)               g_waiting = "SHORT SIGNAL";
   else if(bullBias)               g_waiting = StringFormat("Bull cascade – wait RSI ↑%.0f (now %.1f)", RSILongLevel, r1);
   else                            g_waiting = StringFormat("Bear cascade – wait RSI ↓%.0f (now %.1f)", RSIShortLevel, r1);

   if(EnableDebugPrint)
      PrintFormat("%s | %s | RSI=%.1f | %s",
                  TimeToString(iTime(_Symbol, TradeTF, 0), TIME_MINUTES), g_regime, r1, g_waiting);

   g_featEmaGap    = ef - es;
   g_featTrendDist = closePrev - ef;

   if(longSig)       OpenTrade(true, a);
   else if(shortSig) OpenTrade(false, a);
}

//============================ ORDER / STOPS / LOT ==================
void OpenTrade(bool isLong, double atr)
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double price = isLong ? ask : bid;

   double slDist, tpDist;
   ComputeStops(isLong, price, atr, slDist, tpDist);

   double stopsLevel = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   if(slDist < stopsLevel) slDist = stopsLevel + _Point * 5;
   if(tpDist < stopsLevel) tpDist = stopsLevel + _Point * 5;

   double sl = NormalizeDouble(isLong ? price - slDist : price + slDist, _Digits);
   double tp = NormalizeDouble(isLong ? price + tpDist : price - tpDist, _Digits);

   double lot = CalcLot(slDist);
   if(lot <= 0) return;

   // Extra safety: free margin check
   double margin = 0;
   if(!OrderCalcMargin(isLong ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, _Symbol, lot, price, margin) ||
      margin > AccountInfoDouble(ACCOUNT_MARGIN_FREE) * 0.9)
   {
      if(EnableDebugPrint) Print("Insufficient free margin for lot ", lot);
      return;
   }

   bool ok = isLong ? trade.Buy(lot, _Symbol, ask, sl, tp, TradeComment)
                    : trade.Sell(lot, _Symbol, bid, sl, tp, TradeComment);

   if(ok)
   {
      tradesToday++;
      QueueTelegram(StringFormat("ENTRY %s %.2f lot @ %.2f | SL %.2f TP %.2f | %s",
                    isLong ? "BUY" : "SELL", lot, price, sl, tp, g_cascade));

      // Snapshot for log
      MqlDateTime edt;
      TimeToStruct(TimeCurrent(), edt);
      g_eHasOpen   = true;
      g_eTime      = TimeCurrent();
      g_eDir       = isLong ? "BUY" : "SELL";
      g_ePrice     = price;
      g_eSL        = sl;
      g_eTP        = tp;
      g_eLot       = lot;
      g_eRSI       = g_rsiNow;
      g_eATR       = atr;
      g_eSwingDist = slDist;
      g_eEmaGap    = g_featEmaGap;
      g_eTrendDist = g_featTrendDist;
      g_eRegime    = isLong ? "BULL" : "BEAR";
      g_eHour      = edt.hour;
      g_eDow       = edt.day_of_week;
      g_eSpread    = CurrentSpreadPoints();
   }
}

double CalcLot(double slDist)
{
   double lot = FixedLot;

   if(UseRiskSizing && slDist > 0)
   {
      double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
      double riskMoney = balance * RiskPercent / 100.0;
      double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

      if(tickSize > 0 && tickValue > 0)
      {
         double lossPerLot = (slDist / tickSize) * tickValue;
         if(lossPerLot > 0) lot = riskMoney / lossPerLot;
      }
   }

   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(lot > MaxLot) lot = MaxLot;
   if(step > 0) lot = MathFloor(lot / step) * step;
   if(lot < minLot) lot = minLot;
   if(lot > maxLot) lot = maxLot;

   return NormalizeDouble(lot, 2);
}

double FindSwingLow(int lr, int maxBars)
{
   if(lr < 1) return 0.0;
   double low[];
   ArraySetAsSeries(low, true);
   int copied = CopyLow(_Symbol, TradeTF, 0, maxBars + lr + 2, low);
   if(copied < lr * 2 + 1) return 0.0;

   for(int i = lr; i <= maxBars && i + lr < copied; i++)
   {
      bool ok = true;
      for(int j = 1; j <= lr; j++)
         if(!(low[i] < low[i - j] && low[i] < low[i + j])) { ok = false; break; }
      if(ok) return low[i];
   }
   return 0.0;
}

double FindSwingHigh(int lr, int maxBars)
{
   if(lr < 1) return 0.0;
   double high[];
   ArraySetAsSeries(high, true);
   int copied = CopyHigh(_Symbol, TradeTF, 0, maxBars + lr + 2, high);
   if(copied < lr * 2 + 1) return 0.0;

   for(int i = lr; i <= maxBars && i + lr < copied; i++)
   {
      bool ok = true;
      for(int j = 1; j <= lr; j++)
         if(!(high[i] > high[i - j] && high[i] > high[i + j])) { ok = false; break; }
      if(ok) return high[i];
   }
   return 0.0;
}

void ComputeStops(bool isLong, double price, double atr, double &slDist, double &tpDist)
{
   double rr  = RewardRisk;
   double buf = SwingBufferATR * atr;
   slDist = atr * SL_ATR_Mult;

   if(UseSwingStops)
   {
      double sw = isLong ? FindSwingLow(SwingLookback, SwingScanBars)
                         : FindSwingHigh(SwingLookback, SwingScanBars);
      if(sw > 0)
      {
         double d = isLong ? (price - sw) + buf : (sw - price) + buf;
         if(d > 0) slDist = d;
      }
   }

   double slFloor = atr * SL_ATR_Mult * 0.55;
   double slCap   = atr * SwingSLCapATR;
   if(slDist < slFloor) slDist = slFloor;
   if(slDist > slCap)   slDist = slCap;

   tpDist = slDist * rr;
}

//============================ POSITION MANAGEMENT ==================
void ManageOpenPositions()
{
   if(MaxHoldHours <= 0) return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;

      if(TimeCurrent() - (datetime)PositionGetInteger(POSITION_TIME) >= (long)MaxHoldHours * 3600)
         trade.PositionClose(ticket);
   }
}

void ManageTrailing()
{
   if(!UseTrailing) return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong tk = PositionGetTicket(i);
      if(tk == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;

      double pf = PositionGetDouble(POSITION_PROFIT);
      if(tk != g_trailTicket) { g_trailTicket = tk; g_peakProfit = pf; g_trailArmed = false; }
      if(pf > g_peakProfit) g_peakProfit = pf;

      if(!g_trailArmed && g_peakProfit >= TrailActivate) g_trailArmed = true;

      if(g_trailArmed && pf <= g_peakProfit - TrailGiveback)
      {
         g_trailClosing = true;
         if(!trade.PositionClose(tk)) g_trailClosing = false;
      }
      return; // only manage one position (MaxOpenPositions=1)
   }
}

void ManageBreakeven()
{
   if(!UseBreakeven) return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong tk = PositionGetTicket(i);
      if(tk == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;

      if(PositionGetDouble(POSITION_PROFIT) < BreakevenActivate) return;

      bool isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
      double entry = PositionGetDouble(POSITION_PRICE_OPEN);
      double curSL = PositionGetDouble(POSITION_SL);
      double tp    = PositionGetDouble(POSITION_TP);

      double newSL = NormalizeDouble(isBuy ? entry + BreakevenLock : entry - BreakevenLock, _Digits);
      bool improves = isBuy ? (curSL < newSL - _Point) : (curSL == 0 || curSL > newSL + _Point);

      if(improves) trade.PositionModify(tk, newSL, tp);
      return;
   }
}

int CountMyPositions()
{
   int c = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         PositionGetString(POSITION_SYMBOL) == _Symbol) c++;
   }
   return c;
}

//============================ DAILY / FILTERS / DASHBOARD ==========
void ManageDailyState()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(dt.day_of_year != dayOfTracking) ResetDaily();

   if(dailyStartEquity <= 0) return;

   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   double pnlPct = (eq - dailyStartEquity) / dailyStartEquity * 100.0;

   if(MaxDailyLossPct > 0 && pnlPct <= -MaxDailyLossPct)
   {
      if(!haltedToday) QueueTelegram(StringFormat("KILL-SWITCH %.2f%%", pnlPct));
      haltedToday = true;
   }
   if(DailyProfitTarget > 0 && pnlPct >= DailyProfitTarget)
   {
      if(!haltedToday) QueueTelegram(StringFormat("TARGET +%.1f%% hit", DailyProfitTarget));
      haltedToday = true;
   }
}

void ResetDaily()
{
   dailyStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(dailyStartEquity <= 0) dailyStartEquity = AccountInfoDouble(ACCOUNT_BALANCE);
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dayOfTracking = dt.day_of_year;
   tradesToday = 0;
   haltedToday = false;
   consecutiveLosses = 0;          // reset cool-down counter daily
}

bool IsTradeSession()
{
   if(TradeStartHour == TradeEndHour) return true;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int h = dt.hour;
   if(TradeStartHour < TradeEndHour) return (h >= TradeStartHour && h < TradeEndHour);
   return (h >= TradeStartHour || h < TradeEndHour);
}

int CurrentSpreadPoints()
{
   return (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
}

void UpdateDashboard()
{
   static datetime lastDash = 0;
   if(TimeCurrent() - lastDash < 2) return; // throttle to reduce CPU
   lastDash = TimeCurrent();

   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   double pnlPct = dailyStartEquity > 0 ? (eq - dailyStartEquity) / dailyStartEquity * 100.0 : 0.0;

   string s = "════ Gold Multi-TF Cascade v3 ════\n";
   s += "TF Cascade : D1→H4→H1→M30→M5→M1\n";
   s += "Entry TF   : " + EnumToString(TradeTF) + "\n";
   s += "Cascade    : " + g_cascade + "\n";
   s += "Regime     : " + g_regime + "   RSI: " + DoubleToString(g_rsiNow, 1) + "\n";
   s += "Waiting    : " + g_waiting + "\n";
   s += "Open/Today : " + IntegerToString(CountMyPositions()) + " / " + IntegerToString(tradesToday) + "\n";
   s += "Daily P/L  : " + DoubleToString(pnlPct, 2) + "%\n";
   s += "Status     : " + (haltedToday ? "HALTED" : (g_paused ? "PAUSED" : (TimeCurrent() < coolDownUntil ? "COOLDOWN" : "running"))) + "\n";
   s += "──────────────────────\nDEMO FIRST – you own every trade.";
   Comment(s);
}

//============================ TELEGRAM + LOG =======================
string UrlEncode(string s)
{
   string out = "";
   uchar b[];
   int n = StringToCharArray(s, b, 0, -1, CP_UTF8);
   for(int i = 0; i < n; i++)
   {
      uchar c = b[i];
      if(c == 0) break;
      if((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') ||
         c == '-' || c == '_' || c == '.' || c == '~')
         out += CharToString(c);
      else
         out += StringFormat("%%%02X", c);
   }
   return out;
}

string ReadTokenFile()
{
   int h = FileOpen("gs_telegram_token.txt", FILE_READ | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE) return "";
   string t = FileReadString(h);
   FileClose(h);
   StringTrimLeft(t);
   StringTrimRight(t);
   return t;
}

void SendTelegram(string text)
{
   if(!EnableTelegram || g_tgToken == "" || TelegramChatID == "") return;
   string url = "https://api.telegram.org/bot" + g_tgToken + "/sendMessage";
   string body = "chat_id=" + TelegramChatID + "&text=" + UrlEncode(text);
   uchar post[], result[];
   int written = StringToCharArray(body, post, 0, -1, CP_UTF8);
   if(written > 0) ArrayResize(post, written - 1);
   string resHeaders;
   WebRequest("POST", url, "Content-Type: application/x-www-form-urlencoded\r\n", 5000, post, result, resHeaders);
}

void QueueTelegram(string msg)
{
   if(!EnableTelegram) return;
   int n = ArraySize(g_tgQueue);
   ArrayResize(g_tgQueue, n + 1);
   g_tgQueue[n] = msg;
}

void FlushTelegram()
{
   int n = ArraySize(g_tgQueue);
   for(int i = 0; i < n; i++) SendTelegram(g_tgQueue[i]);
   ArrayResize(g_tgQueue, 0);
}

void WriteTradeLog(double exitPrice, double profit, long durMin, string reason)
{
   bool existed = FileIsExist(TradeLogFile);
   int h = FileOpen(TradeLogFile, FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI, ',');
   if(h == INVALID_HANDLE) return;
   FileSeek(h, 0, SEEK_END);

   if(!existed)
      FileWrite(h, "close_time", "dir", "outcome", "reason", "entry", "exit", "sl", "tp",
                   "lot", "profit", "dur_min", "regime", "rsi", "atr", "ema_gap",
                   "trend_dist", "sl_dist", "hour", "dow", "spread_pts");

   FileWrite(h,
             TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES),
             g_eDir, (profit >= 0 ? "WIN" : "LOSS"), reason,
             DoubleToString(g_ePrice, 2), DoubleToString(exitPrice, 2),
             DoubleToString(g_eSL, 2), DoubleToString(g_eTP, 2), DoubleToString(g_eLot, 2),
             DoubleToString(profit, 2), IntegerToString(durMin), g_eRegime,
             DoubleToString(g_eRSI, 1), DoubleToString(g_eATR, 2), DoubleToString(g_eEmaGap, 2),
             DoubleToString(g_eTrendDist, 2), DoubleToString(g_eSwingDist, 2),
             IntegerToString(g_eHour), IntegerToString(g_eDow), IntegerToString(g_eSpread));
   FileClose(h);
}

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;
   if(!HistoryDealSelect(trans.deal)) return;
   if(HistoryDealGetInteger(trans.deal, DEAL_MAGIC) != MagicNumber) return;
   if(HistoryDealGetString(trans.deal, DEAL_SYMBOL) != _Symbol) return;
   if(HistoryDealGetInteger(trans.deal, DEAL_ENTRY) != DEAL_ENTRY_OUT) return;

   double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
   double price  = HistoryDealGetDouble(trans.deal, DEAL_PRICE);

   QueueTelegram(StringFormat("%s @ %.2f | P/L %.2f", profit >= 0 ? "WIN" : "LOSS", price, profit));

   // Consecutive loss cool-down
   if(profit < 0)
   {
      consecutiveLosses++;
      if(MaxConsecutiveLosses > 0 && consecutiveLosses >= MaxConsecutiveLosses)
      {
         coolDownUntil = TimeCurrent() + CoolDownMinutes * 60;
         QueueTelegram(StringFormat("Cool-down activated for %d min after %d losses", CoolDownMinutes, consecutiveLosses));
         consecutiveLosses = 0;
      }
   }
   else
      consecutiveLosses = 0;

   if(EnableTradeLog && g_eHasOpen)
   {
      long durMin = (long)((TimeCurrent() - g_eTime) / 60);
      double tol = g_eATR * 0.25 + _Point * 10;
      string reason = "OTHER";
      if(g_trailClosing) { reason = "TRAIL"; g_trailClosing = false; }
      else if(MathAbs(price - g_eTP) <= tol) reason = "TP";
      else if(MathAbs(price - g_eSL) <= tol) reason = "SL";
      WriteTradeLog(price, profit, durMin, reason);
      g_eHasOpen = false;
   }
}

void OnTimer() { PollTelegram(true); }

string ExtractJsonString(string js, string key)
{
   string pat = "\"" + key + "\":\"";
   int p = StringFind(js, pat);
   if(p < 0) return "";
   p += StringLen(pat);
   int e = StringFind(js, "\"", p);
   while(e > 0 && StringGetCharacter(js, e - 1) == '\\') e = StringFind(js, "\"", e + 1);
   if(e < 0) return "";
   return StringSubstr(js, p, e - p);
}

string ExtractChatId(string seg)
{
   int c = StringFind(seg, "\"chat\":");
   if(c < 0) return "";
   int idp = StringFind(seg, "\"id\":", c);
   if(idp < 0) return "";
   idp += 5;
   string out = "";
   for(int i = idp; i < StringLen(seg); i++)
   {
      ushort ch = StringGetCharacter(seg, i);
      if((ch >= '0' && ch <= '9') || ch == '-') out += ShortToString(ch);
      else break;
   }
   return out;
}

void PollTelegram(bool execute)
{
   if(!EnableTelegram || g_tgToken == "" || TelegramChatID == "") return;
   string url = "https://api.telegram.org/bot" + g_tgToken + "/getUpdates?timeout=0&offset=" + IntegerToString(g_lastUpdateId + 1);
   uchar data[], result[];
   string resHeaders;
   if(WebRequest("GET", url, "", 4000, data, result, resHeaders) != 200) return;

   string js = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
   int pos = 0;
   while(true)
   {
      int u = StringFind(js, "\"update_id\":", pos);
      if(u < 0) break;
      int idStart = u + StringLen("\"update_id\":");
      long uid = (long)StringToInteger(StringSubstr(js, idStart, 20));
      int nextU = StringFind(js, "\"update_id\":", idStart);
      int segEnd = (nextU < 0) ? StringLen(js) : nextU;
      string seg = StringSubstr(js, idStart, segEnd - idStart);

      if(uid > g_lastUpdateId)
      {
         g_lastUpdateId = uid;
         if(execute)
         {
            string chatId = ExtractChatId(seg);
            string text = ExtractJsonString(seg, "text");
            if(chatId == TelegramChatID && StringLen(text) > 0) HandleCommand(text);
         }
      }
      if(nextU < 0) break;
      pos = segEnd;
   }
}

void HandleCommand(string text)
{
   StringTrimLeft(text);
   StringTrimRight(text);
   string cmd = text;
   int sp = StringFind(cmd, " ");
   if(sp > 0) cmd = StringSubstr(cmd, 0, sp);
   int at = StringFind(cmd, "@");
   if(at > 0) cmd = StringSubstr(cmd, 0, at);
   StringToLower(cmd);

   if(cmd == "/status") SendTelegram(BuildStatus());
   else if(cmd == "/report") SendTelegram(BuildReport());
   else if(cmd == "/pause") { g_paused = true; SendTelegram("PAUSED"); }
   else if(cmd == "/resume") { g_paused = false; SendTelegram("RESUMED"); }
   else if(cmd == "/close") CloseAllAndReport();
   else if(cmd == "/help" || cmd == "/start") SendTelegram("/status /report /pause /resume /close /help");
   else SendTelegram("Unknown. /help");
}

string BuildStatus()
{
   double dpnl = dailyStartEquity > 0 ?
                 (AccountInfoDouble(ACCOUNT_EQUITY) - dailyStartEquity) / dailyStartEquity * 100.0 : 0.0;
   return StringFormat("STATUS %s\nCascade: %s\nRegime: %s\nRSI: %.1f\n%s\nP/L day: %.2f%%\nState: %s",
                       _Symbol, g_cascade, g_regime, g_rsiNow, g_waiting, dpnl,
                       haltedToday ? "HALTED" : (g_paused ? "PAUSED" : (TimeCurrent() < coolDownUntil ? "COOLDOWN" : "running")));
}

string BuildReport()
{
   datetime from = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   HistorySelect(from, TimeCurrent());
   int wins = 0, losses = 0, closed = 0;
   double net = 0;
   for(int i = 0; i < HistoryDealsTotal(); i++)
   {
      ulong t = HistoryDealGetTicket(i);
      if(t == 0) continue;
      if(HistoryDealGetInteger(t, DEAL_MAGIC) != MagicNumber) continue;
      if(HistoryDealGetString(t, DEAL_SYMBOL) != _Symbol) continue;
      if(HistoryDealGetInteger(t, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;
      double p = HistoryDealGetDouble(t, DEAL_PROFIT);
      net += p;
      closed++;
      if(p >= 0) wins++; else losses++;
   }
   return StringFormat("Today: %d trades (W%d L%d) Net %.2f", closed, wins, losses, net);
}

void CloseAllAndReport()
{
   int n = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong tk = PositionGetTicket(i);
      if(tk == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol)
         if(trade.PositionClose(tk)) n++;
   }
   SendTelegram(StringFormat("Closed %d positions", n));
}
//+------------------------------------------------------------------+