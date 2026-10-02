//+------------------------------------------------------------------+
//|                                    GOLD DASHBOARD PRO v3.7       |
//|  MTF Confirmation | Trailing TP | Clean Structure | Bug Fixes      |
//|  ⚠ UNTESTED — verify on DEMO before any live use                  |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Dashboard"
#property version   "3.70"
#property strict
#property description "Gold EA v3.7 — MTF confirmation + trailing TP + compile fixes"

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| INPUTS                                                           |
//+------------------------------------------------------------------+
input group "═══════════════ Panel Layout ═══════════════"
input int      InpXLeft          = 300;
input int      InpYTop           = 40;
input int      InpWidthLeft      = 300;
input int      InpPanelHeight    = 840;

input group "═══════════════ Start/Stop Button ═══════════════"
input int      InpBtnX           = 10;
input int      InpBtnY           = 40;
input int      InpBtnWidth       = 260;
input int      InpBtnHeight      = 40;

input group "═══════════════ Colors ═══════════════"
input color    ClrBackground     = C'10,10,12';
input color    ClrHeader         = C'255,190,0';
input color    ClrLabel          = C'180,180,180';
input color    ClrValue          = C'255,255,255';
input color    ClrBuy            = C'46,204,113';
input color    ClrSell           = C'231,76,60';
input color    ClrNeutral        = C'120,120,120';
input color    ClrWarning        = C'255,152,0';
input color    ClrBtnStart       = C'39,174,96';
input color    ClrBtnStop        = C'192,57,43';

input group "═══════════════ Indicators ═══════════════"
input int      InpRSIPeriod      = 14;
input int      InpMAFast         = 20;
input int      InpMASlow         = 50;
input int      InpATRPeriod      = 14;
input int      InpHTFPeriod      = 50;     // H4 EMA

input group "═══════════════ MTF Confirmation (NEW v3.7) ═══════════════"
input bool     InpUseMTF         = true;   // Require M5+M15 alignment
input int      InpMTFFastEMA     = 20;
input int      InpMTFSlowEMA     = 50;

input group "═══════════════ OpenAI (paste key in Inputs tab) ═══════════════"
input bool     InpUseAI           = true;
input string   InpOpenAIAPIKey    = "";
input string   InpOpenAIModel     = "gpt-5.2";
input int      InpAIUpdateSeconds = 120;
input double   InpAIConfidenceMin = 0.80;

input group "═══════════════ Trading Core ═══════════════"
input bool     InpEnableTrading   = true;
input int      InpMagicNumber     = 20241002;
input int      InpMaxPositions    = 1;
input int      InpMaxSpreadPoints = 70;    // raised to allow XM standard

input group "═══════════════ Risk ═══════════════"
input bool     InpUseRiskSizing   = true;
input double   InpRiskPercent     = 0.5;
input double   InpFixedLot        = 0.01;
input double   InpMaxLotCap       = 0.20;
input double   InpMaxDailyLossPct = 2.0;
input double   InpMaxDailyProfitPct = 5.0;

input group "═══════════════ Loss Reduction ═══════════════"
input int      InpCooldownAfterLossSec = 600;
input int      InpMaxConsecutiveLosses = 2;
input int      InpConsecLossPauseMin   = 120;
input int      InpMinSecondsBetweenTrades = 180;

input group "═══════════════ MARKET STATE FILTERS ═══════════════"
input bool     InpUseMarketStateFilter = false;
input double   InpMinATRPoints         = 50.0;
input double   InpMarketDownDropATR    = 2.0;
input int      InpMarketDownWindowSec  = 300;
input int      InpSlowLogEverySec      = 15;
input int      InpMarketDownPauseMin   = 10;
input double   InpVolSpikeMult         = 2.5;
input int      InpVolSpikePauseMin     = 20;

input group "═══════════════ PROFESSIONAL FILTERS ═══════════════"
input bool     InpUseHTF         = true;
input bool     InpUseVolumeFilter = true;
input int      InpMinTickVolume  = 30;    // lowered from 50 to allow more trades
input bool     InpUseATRPercentile = true;
input double   InpATRPercentileLow = 20.0; // widened from 30
input double   InpATRPercentileHigh = 95.0;// widened from 90
input bool     InpUseSessionQuality = true;
input int      InpSessionStartHour = 13;
input int      InpSessionEndHour   = 17;

input group "═══════════════ AUTO-CLOSE PROTECTIONS ═══════════════"
input bool     InpCloseOnCollapse = true;
input bool     InpCloseOnOppositeAI = true;
input double   InpCloseLossATR    = 2.5;
input int      InpCloseMaxAgeMin  = 240;

input group "═══════════════ SL / TP ═══════════════"
input double   InpSL_ATR_Mult     = 3.0;
input double   InpTP_ATR_Mult     = 2.5;   // slightly bigger TP
input bool     InpUseBreakEven    = true;
input double   InpBE_TriggerATR   = 1.0;
input double   InpBE_OffsetPts    = 30;

input group "═══════════════ Trailing ═══════════════"
input bool     InpUseTrailing     = true;
input double   InpTrail_ATR_Mult  = 1.2;
input double   InpTrail_StepPts   = 25;

input group "═══════════════ Trailing Take Profit (NEW v3.7) ═══════════════"
input bool     InpUseTrailingTP   = true;   // Close if price reverses from peak
input double   InpTP_PeakDropATR  = 0.8;    // Close when profit drops this much from peak

input group "═══════════════ Entry Filters ═══════════════"
input int      InpEntryCheckSec   = 5;
input bool     InpRequireTrendConfirm = true;

input group "═══════════════ Test Mode ═══════════════"
input bool     InpTestMode        = false;

//+------------------------------------------------------------------+
//| GLOBALS                                                          |
//+------------------------------------------------------------------+
string   g_Prefix = "GOLDPRO_v37_";
int      g_HandleRSI, g_HandleMAFast, g_HandleMASlow, g_HandleATR, g_HandleHTF;
int      g_HandleM5Fast, g_HandleM5Slow, g_HandleM15Fast, g_HandleM15Slow;
double   g_BufferRSI[], g_BufferMAFast[], g_BufferMASlow[], g_BufferATR[], g_BufferHTF[];
double   g_BufferM5Fast[], g_BufferM5Slow[], g_BufferM15Fast[], g_BufferM15Slow[];
int      g_SymbolDigits = 0;
double   g_SymbolPoint = 0.0;
CTrade   g_Trade;

bool     g_TradingPaused = false;
datetime g_LastEntryCheck = 0, g_LastAICheck = 0, g_LastSecond = 0, g_LastSlowLog = 0;
int      g_TicksPerSecond = 0;
datetime g_CooldownUntil = 0;
int      g_ConsecutiveLosses = 0;
datetime g_LastTradeTime = 0;

enum ENUM_MARKET_STATE { MKT_OK, MKT_SLOW, MKT_DOWN, MKT_COLLAPSE, MKT_SPIKE };
ENUM_MARKET_STATE g_MarketState = MKT_OK;
datetime g_MarketPauseUntil = 0;

enum ENUM_MARKET_DIR { DIR_UNKNOWN, DIR_UP, DIR_DOWN, DIR_SIDEWAYS };
ENUM_MARKET_DIR g_MarketDir = DIR_UNKNOWN;

string   g_BlockReason = "";
color    g_BlockColor = ClrValue;

double   g_PriceHistory[];
datetime g_PriceHistoryTime[];
double   g_ATRHistory[];

// Position peak tracking for trailing TP
ulong    g_PeakTickets[];
double   g_PeakProfit[];

ulong    g_LastSeenPositions[];

string   g_AISignal = "WAIT";
double   g_AIConfidence = 0.0;
string   g_AIReasoning = "";
bool     g_AIIsActive = false;
string   g_AIStatus = "INITIALIZING";

int      g_TotalTrades = 0;
int      g_WinningTrades = 0;
int      g_LosingTrades = 0;
double   g_TotalProfit = 0.0;

double   g_DayStartBalance = 0.0;
datetime g_DayStartTime = 0;
bool     g_DailyLimitHit = false;

bool     g_TestCompleted = false;
int      g_TestStep = 0;
datetime g_TestLastAction = 0;

//+------------------------------------------------------------------+
int OnInit()
{
   g_SymbolDigits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   g_SymbolPoint  = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   SymbolSelect(_Symbol, true);

   g_HandleRSI    = iRSI(_Symbol, PERIOD_CURRENT, InpRSIPeriod, PRICE_CLOSE);
   g_HandleMAFast = iMA(_Symbol, PERIOD_CURRENT, InpMAFast, 0, MODE_EMA, PRICE_CLOSE);
   g_HandleMASlow = iMA(_Symbol, PERIOD_CURRENT, InpMASlow, 0, MODE_EMA, PRICE_CLOSE);
   g_HandleATR    = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);
   g_HandleHTF    = iMA(_Symbol, PERIOD_H4, InpHTFPeriod, 0, MODE_EMA, PRICE_CLOSE);
   g_HandleM5Fast = iMA(_Symbol, PERIOD_M5, InpMTFFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   g_HandleM5Slow = iMA(_Symbol, PERIOD_M5, InpMTFSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   g_HandleM15Fast = iMA(_Symbol, PERIOD_M15, InpMTFFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   g_HandleM15Slow = iMA(_Symbol, PERIOD_M15, InpMTFSlowEMA, 0, MODE_EMA, PRICE_CLOSE);

   if(g_HandleRSI == INVALID_HANDLE || g_HandleMAFast == INVALID_HANDLE ||
      g_HandleMASlow == INVALID_HANDLE || g_HandleATR == INVALID_HANDLE ||
      g_HandleHTF == INVALID_HANDLE || g_HandleM5Fast == INVALID_HANDLE ||
      g_HandleM5Slow == INVALID_HANDLE || g_HandleM15Fast == INVALID_HANDLE ||
      g_HandleM15Slow == INVALID_HANDLE)
   { Print("Indicator init failed"); return INIT_FAILED; }

   ArraySetAsSeries(g_BufferRSI, true);
   ArraySetAsSeries(g_BufferMAFast, true);
   ArraySetAsSeries(g_BufferMASlow, true);
   ArraySetAsSeries(g_BufferATR, true);
   ArraySetAsSeries(g_BufferHTF, true);
   ArraySetAsSeries(g_BufferM5Fast, true);
   ArraySetAsSeries(g_BufferM5Slow, true);
   ArraySetAsSeries(g_BufferM15Fast, true);
   ArraySetAsSeries(g_BufferM15Slow, true);

   g_Trade.SetExpertMagicNumber(InpMagicNumber);
   g_Trade.SetDeviationInPoints(20);
   long filling = SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((filling & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
      g_Trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if((filling & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
      g_Trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
      g_Trade.SetTypeFilling(ORDER_FILLING_RETURN);

   DrawDashboard();
   CreateStartStopButton();
   EventSetTimer(1);

   g_DayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_DayStartTime = TimeCurrent();

   Print("═══════════════════════════════════════════════════");
   Print(" GOLD PRO v3.7 — MTF + Trailing TP");
   Print(" ⚠ UNTESTED — no guaranteed edge. Use on DEMO.");
   Print(" Spread limit: ", InpMaxSpreadPoints, " pts (XM gold is ~55)");
   Print(" MTF confirm: ", (InpUseMTF ? "ON" : "OFF"));
   Print(" Trailing TP: ", (InpUseTrailingTP ? "ON" : "OFF"));
   Print(" AI: ", (InpUseAI ? "ON" : "OFF"));
   Print("═══════════════════════════════════════════════════");

   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectsDeleteAll(0, g_Prefix);
   if(g_HandleRSI != INVALID_HANDLE) IndicatorRelease(g_HandleRSI);
   if(g_HandleMAFast != INVALID_HANDLE) IndicatorRelease(g_HandleMAFast);
   if(g_HandleMASlow != INVALID_HANDLE) IndicatorRelease(g_HandleMASlow);
   if(g_HandleATR != INVALID_HANDLE) IndicatorRelease(g_HandleATR);
   if(g_HandleHTF != INVALID_HANDLE) IndicatorRelease(g_HandleHTF);
   if(g_HandleM5Fast != INVALID_HANDLE) IndicatorRelease(g_HandleM5Fast);
   if(g_HandleM5Slow != INVALID_HANDLE) IndicatorRelease(g_HandleM5Slow);
   if(g_HandleM15Fast != INVALID_HANDLE) IndicatorRelease(g_HandleM15Fast);
   if(g_HandleM15Slow != INVALID_HANDLE) IndicatorRelease(g_HandleM15Slow);
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK) return;
   if(sparam == g_Prefix + "BtnStartStop")
   {
      g_TradingPaused = !g_TradingPaused;
      UpdateButtonLabel();
      Print(g_TradingPaused ? "⏸ [USER] PAUSED" : "▶ [USER] RESUMED");
      ChartRedraw(0);
   }
}

void CreateStartStopButton()
{
   string name = g_Prefix + "BtnStartStop";
   if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, InpBtnX);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, InpBtnY);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, InpBtnWidth);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, InpBtnHeight);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 11);
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas Bold");
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_STATE, false);
   UpdateButtonLabel();
}

void UpdateButtonLabel()
{
   string name = g_Prefix + "BtnStartStop";
   if(ObjectFind(0, name) < 0) return;
   if(g_TradingPaused)
   {
      ObjectSetString(0, name, OBJPROP_TEXT, "▶  RESUME TRADING");
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, ClrBtnStart);
   }
   else
   {
      ObjectSetString(0, name, OBJPROP_TEXT, "⏸  PAUSE TRADING");
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, ClrBtnStop);
   }
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
}

//+------------------------------------------------------------------+
void OnTick()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double spread = (ask - bid) / g_SymbolPoint;

   UpdateUI("BidPrice", DoubleToString(bid, g_SymbolDigits), ClrValue);
   UpdateUI("AskPrice", DoubleToString(ask, g_SymbolDigits), ClrValue);
   UpdateUI("Spread", DoubleToString(spread, 0) + " pts",
            (spread > InpMaxSpreadPoints) ? ClrWarning : ClrValue);

   datetime cs = TimeCurrent();
   if(cs != g_LastSecond) { g_LastSecond = cs; g_TicksPerSecond = 0; }
   g_TicksPerSecond++;

   DetectClosedPositions();
   EvaluateMarketState(bid);
   EvaluateMarketDirection();
   UpdatePeakTracking();

   if(InpTestMode && !g_TestCompleted) RunTestMode();

   if(InpEnableTrading && !g_TradingPaused &&
      TimeCurrent() - g_LastEntryCheck >= InpEntryCheckSec)
   {
      g_LastEntryCheck = TimeCurrent();
      ProcessTradingEngine();
   }

   if(InpEnableTrading) 
   {
      ManageBreakEvenAndTrailing();
      ManageAutoClose();
      ManageTrailingTP();
   }

   UpdateAllData();
   ChartRedraw(0);
}

void OnTimer()
{
   DetectClosedPositions();
   UpdateAllData();
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
void EvaluateMarketDirection()
{
   if(ArraySize(g_PriceHistory) < 10) { g_MarketDir = DIR_UNKNOWN; return; }
   int n = ArraySize(g_PriceHistory);
   int lookback = MathMin(20, n);
   int start = n - lookback;
   double firstPrice = g_PriceHistory[start];
   double lastPrice  = g_PriceHistory[n - 1];
   double maxP = g_PriceHistory[start], minP = g_PriceHistory[start];
   for(int i = start; i < n; i++)
   {
      if(g_PriceHistory[i] > maxP) maxP = g_PriceHistory[i];
      if(g_PriceHistory[i] < minP) minP = g_PriceHistory[i];
   }
   double range = maxP - minP;
   double move = lastPrice - firstPrice;
   if(range <= 0) { g_MarketDir = DIR_SIDEWAYS; return; }
   if(MathAbs(move) < range * 0.30) g_MarketDir = DIR_SIDEWAYS;
   else if(move > 0) g_MarketDir = DIR_UP;
   else g_MarketDir = DIR_DOWN;
}

void EvaluateMarketState(double bid)
{
   ENUM_MARKET_STATE prev = g_MarketState;
   datetime now = TimeCurrent();
   g_MarketState = MKT_OK;

   int sz = ArraySize(g_PriceHistory);
   ArrayResize(g_PriceHistory, sz + 1);
   ArrayResize(g_PriceHistoryTime, sz + 1);
   g_PriceHistory[sz] = bid;
   g_PriceHistoryTime[sz] = now;

   int removeCount = 0;
   for(int i = 0; i < ArraySize(g_PriceHistoryTime); i++)
   {
      if(now - g_PriceHistoryTime[i] > InpMarketDownWindowSec) removeCount++;
      else break;
   }
   if(removeCount > 0)
   {
      for(int i = 0; i < ArraySize(g_PriceHistory) - removeCount; i++)
      {
         g_PriceHistory[i]     = g_PriceHistory[i + removeCount];
         g_PriceHistoryTime[i] = g_PriceHistoryTime[i + removeCount];
      }
      ArrayResize(g_PriceHistory, ArraySize(g_PriceHistory) - removeCount);
      ArrayResize(g_PriceHistoryTime, ArraySize(g_PriceHistoryTime) - removeCount);
   }

   double atr = 0.0;
   if(CopyBuffer(g_HandleATR, 0, 0, 1, g_BufferATR) >= 1) atr = g_BufferATR[0];
   if(atr <= 0) return;

   double atrPts = atr / g_SymbolPoint;

   int asz = ArraySize(g_ATRHistory);
   ArrayResize(g_ATRHistory, asz + 1);
   g_ATRHistory[asz] = atr;
   if(ArraySize(g_ATRHistory) > 100)
   {
      for(int i = 0; i < ArraySize(g_ATRHistory) - 1; i++)
         g_ATRHistory[i] = g_ATRHistory[i + 1];
      ArrayResize(g_ATRHistory, 100);
   }

   if(InpUseMarketStateFilter && atrPts < InpMinATRPoints)
      g_MarketState = MKT_SLOW;

   if(InpUseMarketStateFilter && ArraySize(g_PriceHistory) >= 2)
   {
      double highest = g_PriceHistory[0];
      for(int i = 1; i < ArraySize(g_PriceHistory); i++)
         if(g_PriceHistory[i] > highest) highest = g_PriceHistory[i];
      double drop = highest - bid;
      if(drop >= atr * InpMarketDownDropATR)
      {
         if(drop >= atr * (InpMarketDownDropATR * 1.5))
            g_MarketState = MKT_COLLAPSE;
         else
            g_MarketState = MKT_DOWN;
         if(now >= g_MarketPauseUntil)
         {
            g_MarketPauseUntil = now + InpMarketDownPauseMin * 60;
            Print("⚠ [", (g_MarketState == MKT_COLLAPSE ? "COLLAPSE" : "DOWN"),
                  "] drop ", DoubleToString(drop / g_SymbolPoint, 0), " pts.");
         }
      }
   }

   if(ArraySize(g_ATRHistory) >= 20)
   {
      double sum = 0;
      for(int i = 0; i < ArraySize(g_ATRHistory) - 1; i++) sum += g_ATRHistory[i];
      double avg = sum / (ArraySize(g_ATRHistory) - 1);
      if(avg > 0 && atr >= avg * InpVolSpikeMult)
      {
         g_MarketState = MKT_SPIKE;
         if(now >= g_MarketPauseUntil)
         {
            g_MarketPauseUntil = now + InpVolSpikePauseMin * 60;
            Print("⚠ [SPIKE] ATR ", DoubleToString(atrPts, 0));
         }
      }
   }

   if(g_MarketState != prev)
   {
      if(g_MarketState == MKT_OK)          Print("✓ [MARKET OK]");
      else if(g_MarketState == MKT_SLOW)   Print("⏸ [SLOW] ATR ", DoubleToString(atrPts,1));
   }
}

bool ATRInGoodRange(double currentATR)
{
   if(!InpUseATRPercentile) return true;
   int n = ArraySize(g_ATRHistory);
   if(n < 20) return true;

   int below = 0;
   for(int i = 0; i < n; i++)
      if(g_ATRHistory[i] < currentATR) below++;
   double percentile = (double)below / n * 100.0;

   if(percentile < InpATRPercentileLow) return false;
   if(percentile > InpATRPercentileHigh) return false;
   return true;
}

bool VolumeOK()
{
   if(!InpUseVolumeFilter) return true;
   long vol = iVolume(_Symbol, PERIOD_CURRENT, 0);
   return (vol >= InpMinTickVolume);
}

bool InGoodSession()
{
   if(!InpUseSessionQuality) return true;
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   return (dt.hour >= InpSessionStartHour && dt.hour < InpSessionEndHour);
}

bool HTFTrendBullish()
{
   if(!InpUseHTF) return true;
   if(CopyBuffer(g_HandleHTF, 0, 0, 1, g_BufferHTF) < 1) return true;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   return (bid > g_BufferHTF[0]);
}

//+------------------------------------------------------------------+
//| MTF trend check (M5 + M15)                                        |
//+------------------------------------------------------------------+
bool MTFTrendBullish()
{
   if(!InpUseMTF) return true;
   if(CopyBuffer(g_HandleM5Fast, 0, 0, 1, g_BufferM5Fast) < 1) return true;
   if(CopyBuffer(g_HandleM5Slow, 0, 0, 1, g_BufferM5Slow) < 1) return true;
   if(CopyBuffer(g_HandleM15Fast, 0, 0, 1, g_BufferM15Fast) < 1) return true;
   if(CopyBuffer(g_HandleM15Slow, 0, 0, 1, g_BufferM15Slow) < 1) return true;
   return (g_BufferM5Fast[0] > g_BufferM5Slow[0]) &&
          (g_BufferM15Fast[0] > g_BufferM15Slow[0]);
}

bool MTFTrendBearish()
{
   if(!InpUseMTF) return true;
   if(CopyBuffer(g_HandleM5Fast, 0, 0, 1, g_BufferM5Fast) < 1) return true;
   if(CopyBuffer(g_HandleM5Slow, 0, 0, 1, g_BufferM5Slow) < 1) return true;
   if(CopyBuffer(g_HandleM15Fast, 0, 0, 1, g_BufferM15Fast) < 1) return true;
   if(CopyBuffer(g_HandleM15Slow, 0, 0, 1, g_BufferM15Slow) < 1) return true;
   return (g_BufferM5Fast[0] < g_BufferM5Slow[0]) &&
          (g_BufferM15Fast[0] < g_BufferM15Slow[0]);
}

//+------------------------------------------------------------------+
//| Peak profit tracking for trailing TP                              |
//+------------------------------------------------------------------+
void UpdatePeakTracking()
{
   for(int i = 0; i < ArraySize(g_PeakTickets); i++)
   {
      ulong ticket = g_PeakTickets[i];
      bool exists = false;
      for(int j = PositionsTotal() - 1; j >= 0; j--)
      {
         if(PositionGetTicket(j) == ticket) { exists = true; break; }
      }
      if(!exists)
      {
         for(int k = i; k < ArraySize(g_PeakTickets) - 1; k++)
         {
            g_PeakTickets[k] = g_PeakTickets[k + 1];
            g_PeakProfit[k]  = g_PeakProfit[k + 1];
         }
         ArrayResize(g_PeakTickets, ArraySize(g_PeakTickets) - 1);
         ArrayResize(g_PeakProfit, ArraySize(g_PeakProfit) - 1);
         i--;
      }
   }
}

double GetPeakProfit(ulong ticket, double currentProfit)
{
   for(int i = 0; i < ArraySize(g_PeakTickets); i++)
   {
      if(g_PeakTickets[i] == ticket)
      {
         if(currentProfit > g_PeakProfit[i]) g_PeakProfit[i] = currentProfit;
         return g_PeakProfit[i];
      }
   }
   int sz = ArraySize(g_PeakTickets);
   ArrayResize(g_PeakTickets, sz + 1);
   ArrayResize(g_PeakProfit, sz + 1);
   g_PeakTickets[sz] = ticket;
   g_PeakProfit[sz]  = currentProfit;
   return currentProfit;
}

//+------------------------------------------------------------------+
//| Trailing take profit                                              |
//+------------------------------------------------------------------+
void ManageTrailingTP()
{
   if(!InpUseTrailingTP) return;

   double atr = 0.0;
   if(CopyBuffer(g_HandleATR, 0, 0, 1, g_BufferATR) >= 1) atr = g_BufferATR[0];
   if(atr <= 0) return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;

      double profit = PositionGetDouble(POSITION_PROFIT);
      double peak = GetPeakProfit(t, profit);

      // Only active if we're in meaningful profit
      if(peak < 1.0) continue;

      double dropFromPeak = peak - profit;
      double dropThreshold = atr * InpTP_PeakDropATR;

      if(dropFromPeak >= dropThreshold && profit > 0)
      {
         Print("💰 TRAILING TP #", t, ": Peak $", DoubleToString(peak, 2),
               " → Current $", DoubleToString(profit, 2), " — Closing to lock profit.");
         if(g_Trade.PositionClose(t))
            Print("✅ Closed. P/L = ", DoubleToString(profit, 2));
      }
   }
}

//+------------------------------------------------------------------+
void ManageAutoClose()
{
   double atr = 0.0;
   if(CopyBuffer(g_HandleATR, 0, 0, 1, g_BufferATR) >= 1) atr = g_BufferATR[0];
   if(atr <= 0) return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;

      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double entry = PositionGetDouble(POSITION_PRICE_OPEN);
      double profit = PositionGetDouble(POSITION_PROFIT);
      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      string closeReason = "";
      bool shouldClose = false;

      if(InpCloseOnCollapse && g_MarketState == MKT_COLLAPSE)
      { shouldClose = true; closeReason = "Market collapse"; }

      if(InpCloseOnOppositeAI && g_AIIsActive && g_AIConfidence >= InpAIConfidenceMin)
      {
         if(type == POSITION_TYPE_BUY && g_AISignal == "SELL")
         { shouldClose = true; closeReason = "AI flipped to SELL"; }
         if(type == POSITION_TYPE_SELL && g_AISignal == "BUY")
         { shouldClose = true; closeReason = "AI flipped to BUY"; }
      }

      if(entry > 0)
      {
         double lossDist = (type == POSITION_TYPE_BUY) ? (entry - bid) : (ask - entry);
         if(lossDist >= atr * InpCloseLossATR)
         { shouldClose = true; closeReason = "Loss >= " + DoubleToString(InpCloseLossATR, 1) + "× ATR"; }
      }

      if(InpCloseMaxAgeMin > 0 && (TimeCurrent() - openTime) > InpCloseMaxAgeMin * 60)
      { shouldClose = true; closeReason = "Age > " + IntegerToString(InpCloseMaxAgeMin) + " min"; }

      if(shouldClose)
      {
         Print("🔒 AUTO-CLOSE #", t, ": ", closeReason);
         if(g_Trade.PositionClose(t))
            Print("✅ Closed. P/L = ", DoubleToString(profit, 2));
      }
   }
}

void DetectClosedPositions()
{
   ulong currentTickets[];
   int curCount = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      ArrayResize(currentTickets, curCount + 1);
      currentTickets[curCount++] = t;
   }

   for(int i = 0; i < ArraySize(g_LastSeenPositions); i++)
   {
      ulong old = g_LastSeenPositions[i];
      bool stillOpen = false;
      for(int j = 0; j < curCount; j++)
         if(currentTickets[j] == old) { stillOpen = true; break; }
      if(stillOpen) continue;

      if(HistorySelect(TimeCurrent() - 86400, TimeCurrent() + 60))
      {
         int deals = HistoryDealsTotal();
         for(int d = deals - 1; d >= 0; d--)
         {
            ulong dticket = HistoryDealGetTicket(d);
            if(dticket == 0) continue;
            if(HistoryDealGetString(dticket, DEAL_SYMBOL) != _Symbol) continue;
            if(HistoryDealGetInteger(dticket, DEAL_MAGIC) != InpMagicNumber) continue;
            if(HistoryDealGetInteger(dticket, DEAL_POSITION_ID) != old) continue;

            double profit = HistoryDealGetDouble(dticket, DEAL_PROFIT)
                          + HistoryDealGetDouble(dticket, DEAL_SWAP)
                          + HistoryDealGetDouble(dticket, DEAL_COMMISSION);

            g_TotalTrades++;
            g_TotalProfit += profit;

            if(profit > 0)
            {
               g_WinningTrades++;
               g_ConsecutiveLosses = 0;
               Print("✅ WIN: +", DoubleToString(profit, 2));
            }
            else if(profit < 0)
            {
               g_LosingTrades++;
               g_ConsecutiveLosses++;
               g_CooldownUntil = TimeCurrent() + InpCooldownAfterLossSec;
               if(g_ConsecutiveLosses >= InpMaxConsecutiveLosses)
               {
                  g_CooldownUntil = TimeCurrent() + InpConsecLossPauseMin * 60;
                  Print("🛑 ", g_ConsecutiveLosses, " losses — pause ", InpConsecLossPauseMin, " min");
               }
            }
            break;
         }
      }
   }
   ArrayResize(g_LastSeenPositions, curCount);
   for(int i = 0; i < curCount; i++) g_LastSeenPositions[i] = currentTickets[i];
}

void CheckNewDay()
{
   MqlDateTime a, b;
   TimeToStruct(g_DayStartTime, a);
   TimeToStruct(TimeCurrent(), b);
   if(a.day != b.day || a.mon != b.mon || a.year != b.year)
   {
      g_DayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      g_DayStartTime = TimeCurrent();
      g_DailyLimitHit = false;
      g_ConsecutiveLosses = 0;
      g_CooldownUntil = 0;
      Print("📅 New day.");
   }
}

bool DailyLimitReached()
{
   CheckNewDay();
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double pnl = equity - g_DayStartBalance;
   double pct = (g_DayStartBalance > 0) ? (pnl / g_DayStartBalance) * 100.0 : 0.0;
   if(pct <= -InpMaxDailyLossPct)
   {
      if(!g_DailyLimitHit) { Print("🛑 DAILY LOSS ", DoubleToString(pct,2), "%"); g_DailyLimitHit = true; }
      return true;
   }
   if(pct >= InpMaxDailyProfitPct)
   {
      if(!g_DailyLimitHit) { Print("🎯 DAILY PROFIT ", DoubleToString(pct,2), "%"); g_DailyLimitHit = true; }
      return true;
   }
   return false;
}

double CalculateLotSize(double slDistancePrice)
{
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(!InpUseRiskSizing || slDistancePrice <= 0)
   {
      double l = MathMax(minLot, MathMin(maxLot, InpFixedLot));
      return MathRound(l / step) * step;
   }
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double risk = balance * (InpRiskPercent / 100.0);
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(ts <= 0 || tv <= 0) return MathMax(minLot, InpFixedLot);
   double valuePerPrice = tv / ts;
   double lossPerLot = slDistancePrice * valuePerPrice;
   if(lossPerLot <= 0) return MathMax(minLot, InpFixedLot);
   double lots = risk / lossPerLot;
   lots = MathMin(lots, InpMaxLotCap);
   lots = MathMax(minLot, MathMin(maxLot, lots));
   lots = MathRound(lots / step) * step;
   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
bool CanOpenNewTrade(string &reason, color &reasonColor)
{
   reasonColor = ClrValue;

   if(g_TradingPaused)  { reason = "PAUSED BY USER"; reasonColor = ClrWarning; return false; }
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
                        { reason = "TERMINAL DISABLED"; reasonColor = ClrSell; return false; }
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
                        { reason = "EA TRADING OFF"; reasonColor = ClrSell; return false; }
   if(DailyLimitReached()) { reason = "DAILY LIMIT HIT"; reasonColor = ClrSell; return false; }

   if(g_MarketPauseUntil > TimeCurrent())
   {
      reason = "MARKET PAUSE " + IntegerToString((int)(g_MarketPauseUntil - TimeCurrent())) + "s";
      reasonColor = ClrSell;
      return false;
   }

   if(g_MarketState == MKT_SLOW) { reason = "MARKET SLOW"; reasonColor = ClrWarning; return false; }
   if(g_MarketState == MKT_DOWN) { reason = "MARKET DOWN"; reasonColor = ClrSell; return false; }
   if(g_MarketState == MKT_COLLAPSE) { reason = "MARKET COLLAPSE"; reasonColor = ClrSell; return false; }
   if(g_MarketState == MKT_SPIKE) { reason = "VOLATILITY SPIKE"; reasonColor = ClrWarning; return false; }

   if(g_CooldownUntil > TimeCurrent())
   {
      reason = "COOLDOWN " + IntegerToString((int)(g_CooldownUntil - TimeCurrent())) + "s";
      reasonColor = ClrWarning;
      return false;
   }

   if(TimeCurrent() - g_LastTradeTime < InpMinSecondsBetweenTrades)
   {
      reason = "WAIT " + IntegerToString(InpMinSecondsBetweenTrades - (int)(TimeCurrent() - g_LastTradeTime)) + "s";
      reasonColor = ClrNeutral;
      return false;
   }

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double spreadPts = (ask - bid) / g_SymbolPoint;
   if(spreadPts > InpMaxSpreadPoints)
   {
      reason = "SPREAD " + DoubleToString(spreadPts, 0) + " > " + IntegerToString(InpMaxSpreadPoints);
      reasonColor = ClrSell;
      return false;
   }

   if(CountTotalOpenPositions() >= InpMaxPositions)
   {
      reason = "MAX POSITIONS (" + IntegerToString(CountTotalOpenPositions()) + ")";
      reasonColor = ClrNeutral;
      return false;
   }

   if(!InGoodSession()) { reason = "POOR SESSION QUALITY"; reasonColor = ClrNeutral; return false; }
   if(!VolumeOK())      { reason = "LOW VOLUME"; reasonColor = ClrNeutral; return false; }

   double atr = 0.0;
   if(CopyBuffer(g_HandleATR, 0, 0, 1, g_BufferATR) >= 1) atr = g_BufferATR[0];
   if(!ATRInGoodRange(atr)) { reason = "ATR OUT OF RANGE"; reasonColor = ClrWarning; return false; }

   reason = "";
   return true;
}

//+------------------------------------------------------------------+
void ProcessTradingEngine()
{
   string reason;
   color  reasonColor;

   if(!CanOpenNewTrade(reason, reasonColor))
   {
      g_BlockReason = reason;
      g_BlockColor = reasonColor;
      return;
   }

   if(CopyBuffer(g_HandleRSI, 0, 0, 1, g_BufferRSI) < 1) return;
   if(CopyBuffer(g_HandleMAFast, 0, 0, 1, g_BufferMAFast) < 1) return;
   if(CopyBuffer(g_HandleMASlow, 0, 0, 1, g_BufferMASlow) < 1) return;
   if(CopyBuffer(g_HandleATR, 0, 0, 1, g_BufferATR) < 1) return;

   double rsi = g_BufferRSI[0];
   double atr = g_BufferATR[0];
   if(atr <= 0) return;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   bool maBull = (g_BufferMAFast[0] > g_BufferMASlow[0]);
   bool htfBull = HTFTrendBullish();
   bool mtfBull = MTFTrendBullish();
   bool mtfBear = MTFTrendBearish();

   // === AI mode ===
   if(InpUseAI && g_AIIsActive)
   {
      if(g_AISignal == "BUY" && g_AIConfidence >= InpAIConfidenceMin)
      {
         if(InpRequireTrendConfirm && !maBull)
         { g_BlockReason = "AI BUY vs M1 BEAR"; g_BlockColor = ClrWarning; return; }
         if(InpUseHTF && !htfBull)
         { g_BlockReason = "AI BUY vs HTF BEAR"; g_BlockColor = ClrWarning; return; }
         if(InpUseMTF && !mtfBull)
         { g_BlockReason = "AI BUY vs MTF BEAR"; g_BlockColor = ClrWarning; return; }
         if(rsi > 55)
         { g_BlockReason = "AI BUY but RSI > 55"; g_BlockColor = ClrWarning; return; }

         ExecuteBuyOrder(ask, atr);
         g_BlockReason = "TRADE OPENED: BUY (AI)"; g_BlockColor = ClrBuy;
         return;
      }
      if(g_AISignal == "SELL" && g_AIConfidence >= InpAIConfidenceMin)
      {
         if(InpRequireTrendConfirm && maBull)
         { g_BlockReason = "AI SELL vs M1 BULL"; g_BlockColor = ClrWarning; return; }
         if(InpUseHTF && htfBull)
         { g_BlockReason = "AI SELL vs HTF BULL"; g_BlockColor = ClrWarning; return; }
         if(InpUseMTF && !mtfBear)
         { g_BlockReason = "AI SELL vs MTF BULL"; g_BlockColor = ClrWarning; return; }
         if(rsi < 45)
         { g_BlockReason = "AI SELL but RSI < 45"; g_BlockColor = ClrWarning; return; }

         ExecuteSellOrder(bid, atr);
         g_BlockReason = "TRADE OPENED: SELL (AI)"; g_BlockColor = ClrSell;
         return;
      }
      g_BlockReason = "AI: " + g_AISignal + " (need " + DoubleToString(InpAIConfidenceMin*100,0) + "%)";
      g_BlockColor = ClrNeutral;
      return;
   }

   // === Mechanical mode with MULTI-CONDITION ===
   bool buyConditions =
      (rsi < 30) &&
      maBull &&
      (!InpUseHTF || htfBull) &&
      (!InpUseMTF || mtfBull) &&
      VolumeOK() &&
      ATRInGoodRange(atr);

   bool sellConditions =
      (rsi > 70) &&
      !maBull &&
      (!InpUseHTF || !htfBull) &&
      (!InpUseMTF || mtfBear) &&
      VolumeOK() &&
      ATRInGoodRange(atr);

   if(buyConditions)
   {
      ExecuteBuyOrder(ask, atr);
      g_BlockReason = "TRADE OPENED: BUY";
      g_BlockColor = ClrBuy;
   }
   else if(sellConditions)
   {
      ExecuteSellOrder(bid, atr);
      g_BlockReason = "TRADE OPENED: SELL";
      g_BlockColor = ClrSell;
   }
   else
   {
      string whyNot = "";
      if(rsi >= 30 && rsi <= 70) whyNot = "RSI " + DoubleToString(rsi,1) + " neutral";
      else if(rsi < 30 && !maBull) whyNot = "RSI over-bought but BEAR trend";
      else if(rsi > 70 && maBull) whyNot = "RSI overbought but BULL trend";
      else if(InpUseMTF && rsi < 30 && !mtfBull) whyNot = "MTF bearish vs BUY";
      else if(InpUseMTF && rsi > 70 && !mtfBear) whyNot = "MTF bullish vs SELL";
      else whyNot = "No multi-condition alignment";
      g_BlockReason = whyNot;
      g_BlockColor = ClrNeutral;
   }
}

//+------------------------------------------------------------------+
void ExecuteBuyOrder(double entryPrice, double atr)
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(ask <= 0) return;
   double slDist = atr * InpSL_ATR_Mult;
   double sl = NormalizeDouble(ask - slDist, g_SymbolDigits);
   double minStop = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * g_SymbolPoint;
   if(minStop > 0 && (ask - sl) < minStop) sl = NormalizeDouble(ask - minStop, g_SymbolDigits);
   double tp = 0.0;
   if(InpTP_ATR_Mult > 0) tp = NormalizeDouble(ask + atr * InpTP_ATR_Mult, g_SymbolDigits);
   double lots = CalculateLotSize(slDist);
   Print("═══ BUY ═══ Lots=", DoubleToString(lots, 2), " SL=", sl, " TP=", tp);
   if(g_Trade.Buy(lots, _Symbol, ask, sl, tp, "GOLDPRO BUY"))
   { g_LastTradeTime = TimeCurrent(); Print("✅ BUY #", g_Trade.ResultOrder()); }
   else Print("❌ BUY fail: ", g_Trade.ResultRetcodeDescription());
}

void ExecuteSellOrder(double entryPrice, double atr)
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(bid <= 0) return;
   double slDist = atr * InpSL_ATR_Mult;
   double sl = NormalizeDouble(bid + slDist, g_SymbolDigits);
   double minStop = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * g_SymbolPoint;
   if(minStop > 0 && (sl - bid) < minStop) sl = NormalizeDouble(bid + minStop, g_SymbolDigits);
   double tp = 0.0;
   if(InpTP_ATR_Mult > 0) tp = NormalizeDouble(bid - atr * InpTP_ATR_Mult, g_SymbolDigits);
   double lots = CalculateLotSize(slDist);
   Print("═══ SELL ═══ Lots=", DoubleToString(lots, 2), " SL=", sl, " TP=", tp);
   if(g_Trade.Sell(lots, _Symbol, bid, sl, tp, "GOLDPRO SELL"))
   { g_LastTradeTime = TimeCurrent(); Print("✅ SELL #", g_Trade.ResultOrder()); }
   else Print("❌ SELL fail: ", g_Trade.ResultRetcodeDescription());
}

void ManageBreakEvenAndTrailing()
{
   if(!InpUseBreakEven && !InpUseTrailing) return;
   double atr = 0.0;
   if(CopyBuffer(g_HandleATR, 0, 0, 1, g_BufferATR) >= 1) atr = g_BufferATR[0];
   if(atr <= 0) return;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double minStop = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * g_SymbolPoint;
   if(minStop <= 0) minStop = 10 * g_SymbolPoint;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double entry = PositionGetDouble(POSITION_PRICE_OPEN);
      double curSL = PositionGetDouble(POSITION_SL);
      double curTP = PositionGetDouble(POSITION_TP);

      if(type == POSITION_TYPE_BUY)
      {
         double pd = bid - entry;
         if(InpUseBreakEven && pd >= atr * InpBE_TriggerATR)
         {
            double be = NormalizeDouble(entry + InpBE_OffsetPts * g_SymbolPoint, g_SymbolDigits);
            if(be < bid - minStop && curSL < be) g_Trade.PositionModify(t, be, curTP);
         }
         if(InpUseTrailing)
         {
            double ns = NormalizeDouble(bid - atr * InpTrail_ATR_Mult, g_SymbolDigits);
            if(ns < bid - minStop && ns > curSL + InpTrail_StepPts * g_SymbolPoint) g_Trade.PositionModify(t, ns, curTP);
         }
      }
      else if(type == POSITION_TYPE_SELL)
      {
         double pd = entry - ask;
         if(InpUseBreakEven && pd >= atr * InpBE_TriggerATR)
         {
            double be = NormalizeDouble(entry - InpBE_OffsetPts * g_SymbolPoint, g_SymbolDigits);
            if(be > ask + minStop && (curSL > be || curSL == 0)) g_Trade.PositionModify(t, be, curTP);
         }
         if(InpUseTrailing)
         {
            double ns = NormalizeDouble(ask + atr * InpTrail_ATR_Mult, g_SymbolDigits);
            if(ns > ask + minStop && (curSL == 0 || ns < curSL - InpTrail_StepPts * g_SymbolPoint)) g_Trade.PositionModify(t, ns, curTP);
         }
      }
   }
}

int CountOpenBuyPositions()
{
   int c = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == InpMagicNumber &&
         PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) c++;
   }
   return c;
}
int CountOpenSellPositions()
{
   int c = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == InpMagicNumber &&
         PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) c++;
   }
   return c;
}
int CountTotalOpenPositions() { return CountOpenBuyPositions() + CountOpenSellPositions(); }

void UpdateAllData()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double spread = (ask - bid) / g_SymbolPoint;

   UpdateUI("BidPrice", DoubleToString(bid, g_SymbolDigits), ClrValue);
   UpdateUI("AskPrice", DoubleToString(ask, g_SymbolDigits), ClrValue);
   UpdateUI("Spread", DoubleToString(spread, 0) + " pts", (spread > InpMaxSpreadPoints) ? ClrWarning : ClrValue);

   double rsi = 50.0, atr = 0.0;
   if(CopyBuffer(g_HandleRSI, 0, 0, 1, g_BufferRSI) < 1) return;
   if(CopyBuffer(g_HandleMAFast, 0, 0, 1, g_BufferMAFast) < 1) return;
   if(CopyBuffer(g_HandleMASlow, 0, 0, 1, g_BufferMASlow) < 1) return;
   if(CopyBuffer(g_HandleATR, 0, 0, 1, g_BufferATR) < 1) return;
   rsi = g_BufferRSI[0]; atr = g_BufferATR[0];

   UpdateUI("Velocity", IntegerToString(g_TicksPerSecond) + " t/s", (g_TicksPerSecond > 10) ? ClrBuy : ClrValue);
   UpdateUI("RSI", DoubleToString(rsi, 1), (rsi < 30) ? ClrBuy : (rsi > 70) ? ClrSell : ClrValue);
   UpdateUI("MAFast", DoubleToString(g_BufferMAFast[0], g_SymbolDigits), ClrValue);
   UpdateUI("MASlow", DoubleToString(g_BufferMASlow[0], g_SymbolDigits), ClrValue);
   UpdateUI("ATR", DoubleToString(atr, g_SymbolDigits), ClrValue);

   string mkt = "OK"; color mktc = ClrBuy;
   switch(g_MarketState)
   {
      case MKT_SLOW:     mkt = "SLOW";     mktc = ClrWarning; break;
      case MKT_DOWN:     mkt = "DOWN";     mktc = ClrSell;    break;
      case MKT_COLLAPSE: mkt = "COLLAPSE"; mktc = ClrSell;    break;
      case MKT_SPIKE:    mkt = "SPIKE";    mktc = ClrWarning; break;
      default: break;
   }
   if(g_MarketPauseUntil > TimeCurrent())
      mkt += " (" + IntegerToString((int)(g_MarketPauseUntil - TimeCurrent())) + "s)";
   UpdateUI("MarketState", mkt, mktc);

   string dir = "??"; color dirc = ClrNeutral;
   switch(g_MarketDir)
   {
      case DIR_UP:       dir = "▲ UP";       dirc = ClrBuy;     break;
      case DIR_DOWN:     dir = "▼ DOWN";     dirc = ClrSell;    break;
      case DIR_SIDEWAYS: dir = "► SIDEWAYS"; dirc = ClrWarning; break;
      default:           dir = "ANALYZING";  dirc = ClrNeutral; break;
   }
   UpdateUI("MarketDir", dir, dirc);

   int op = CountTotalOpenPositions();
   string tradeState = (op > 0) ? "OPEN (" + IntegerToString(op) + ")" : "FLAT";
   color tradeColor = (op > 0) ? ClrBuy : ClrNeutral;
   UpdateUI("TradeState", tradeState, tradeColor);

   string st = InpEnableTrading ? "ACTIVE" : "DISABLED";
   color  stc = ClrBuy;
   if(g_TradingPaused) { st = "USER PAUSED"; stc = ClrWarning; }
   if(g_DailyLimitHit) { st = "DAILY LIMIT HIT"; stc = ClrSell; }
   UpdateUI("TradingStatus", st, stc);
   UpdateUI("BlockReason", g_BlockReason, g_BlockColor);

   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   double pnl = eq - g_DayStartBalance;
   double pct = (g_DayStartBalance > 0) ? (pnl/g_DayStartBalance)*100.0 : 0.0;
   UpdateUI("DailyPnL", DoubleToString(pnl, 2) + " (" + DoubleToString(pct, 2) + "%)", (pnl >= 0) ? ClrBuy : ClrSell);

   if(InpUseAI) UpdateAIAnalysis(rsi, bid, ask, atr);
   else { UpdateUI("AISignal", "OFF", ClrNeutral); UpdateUI("AIStatus", "AI: DISABLED", ClrNeutral); }
}

void UpdateAIAnalysis(double rsi, double bid, double ask, double atr)
{
   datetime now = TimeCurrent();
   if(now - g_LastAICheck >= InpAIUpdateSeconds || g_LastAICheck == 0)
   {
      g_LastAICheck = now;
      string resp = CallOpenAI(BuildMarketContext(rsi, bid, ask, atr));
      ParseAIResponse(resp);
   }
   color c = (g_AISignal == "BUY") ? ClrBuy : (g_AISignal == "SELL") ? ClrSell : ClrWarning;
   UpdateUI("AISignal", g_AISignal, c);
   UpdateUI("AIConfidence", (g_AIConfidence > 0 ? DoubleToString(g_AIConfidence*100,1)+"%" : "--"),
            (g_AIConfidence >= InpAIConfidenceMin ? ClrBuy : ClrWarning));
   string stat = "AI: " + g_AIStatus;
   color sc = (g_AIStatus == "ACTIVE") ? ClrBuy : (g_AIStatus == "ERROR") ? ClrSell : ClrWarning;
   UpdateUI("AIStatus", stat, sc);
   string exp = "--";
   if(StringLen(g_AIReasoning) > 0)
   { exp = StringSubstr(g_AIReasoning, 0, 50); if(StringLen(g_AIReasoning) > 50) exp += "..."; }
   UpdateUI("AIExpectation", exp, c);
}

string BuildMarketContext(double rsi, double bid, double ask, double atr)
{
   bool maBull = (g_BufferMAFast[0] > g_BufferMASlow[0]);
   bool htfBull = HTFTrendBullish();
   bool mtfBull = MTFTrendBullish();
   bool mtfBear = MTFTrendBearish();
   double wr = (g_TotalTrades > 0) ? (double(g_WinningTrades)/g_TotalTrades)*100.0 : 0.0;
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   double eq  = AccountInfoDouble(ACCOUNT_EQUITY);
   double dp  = eq - g_DayStartBalance;
   double dpp = (g_DayStartBalance > 0) ? (dp/g_DayStartBalance)*100.0 : 0.0;

   string dirStr = "SIDEWAYS";
   if(g_MarketDir == DIR_UP) dirStr = "UPTREND";
   else if(g_MarketDir == DIR_DOWN) dirStr = "DOWNTREND";

   string ctx = "You are a conservative M1 XAUUSD scalper. Reply ONLY:\n"
                "SIGNAL|CONFIDENCE|REASONING|SUMMARY\n"
                "SIGNAL in {BUY,SELL,WAIT}. CONFIDENCE in [0,1].\n\n";
   ctx += "PERF: Trades=" + IntegerToString(g_TotalTrades) + " W=" + IntegerToString(g_WinningTrades)
        + " L=" + IntegerToString(g_LosingTrades) + " WR=" + DoubleToString(wr, 1) + "%\n";
   ctx += "ACC: Bal=" + DoubleToString(bal, 2) + " Eq=" + DoubleToString(eq, 2)
        + " Day=" + DoubleToString(dp, 2) + " (" + DoubleToString(dpp, 2) + "%)\n";
   ctx += "MKT: Bid=" + DoubleToString(bid, g_SymbolDigits) + " Ask=" + DoubleToString(ask, g_SymbolDigits)
        + " Spr=" + DoubleToString((ask - bid)/g_SymbolPoint, 0) + "pts\n";
   ctx += "DIR: " + dirStr + "\n";
   ctx += "IND: RSI=" + DoubleToString(rsi, 2)
        + " MA20=" + DoubleToString(g_BufferMAFast[0], g_SymbolDigits)
        + " MA50=" + DoubleToString(g_BufferMASlow[0], g_SymbolDigits)
        + " ATR=" + DoubleToString(atr, g_SymbolDigits)
        + " M1=" + (maBull ? "BULL" : "BEAR")
        + " M5/M15=" + (mtfBull ? "BULL" : (mtfBear ? "BEAR" : "MIX"))
        + " H4=" + (htfBull ? "BULL" : "BEAR") + "\n";
   ctx += "POS: " + IntegerToString(CountTotalOpenPositions()) + "/" + IntegerToString(InpMaxPositions) + "\n";
   return ctx;
}

string CallOpenAI(string marketData)
{
   if(StringLen(InpOpenAIAPIKey) < 20)
   { g_AIStatus = "SIMULATED"; g_AIIsActive = false; return SimulatedAI(); }

   string esc = EscapeJSON(marketData);
   string req = "{\"model\":\"" + InpOpenAIModel
              + "\",\"messages\":[{\"role\":\"user\",\"content\":\"" + esc + "\"}]}";
   string hdrs = "Content-Type: application/json\r\nAuthorization: Bearer " + InpOpenAIAPIKey + "\r\n";

   char post[], result[]; string rh;
   int len = StringLen(req);
   ArrayResize(post, len);
   StringToCharArray(req, post, 0, len);

   ResetLastError();
   int res = WebRequest("POST", "https://api.openai.com/v1/chat/completions", hdrs, 20000, post, result, rh);
   if(res == -1)
   { Print("❌ WebRequest err ", GetLastError()); g_AIStatus = "ERROR"; g_AIIsActive = false; return SimulatedAI(); }
   if(res != 200)
   { Print("❌ HTTP ", res); g_AIStatus = "ERROR"; g_AIIsActive = false; return SimulatedAI(); }

   string content = ExtractContent(CharArrayToString(result));
   if(StringLen(content) > 0) { g_AIStatus = "ACTIVE"; g_AIIsActive = true; return content; }
   Print("⚠ Extract failed"); g_AIStatus = "ERROR"; g_AIIsActive = false; return SimulatedAI();
}

string ExtractContent(string json)
{
   int k = StringFind(json, "\"content\"");
   if(k < 0) return "";
   int c = StringFind(json, ":", k);
   if(c < 0) return "";
   int q = c + 1;
   while(q < StringLen(json))
   {
      ushort ch = StringGetCharacter(json, q);
      if(ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n') { q++; continue; }
      break;
   }
   if(q >= StringLen(json) || StringGetCharacter(json, q) != '"') return "";
   int s = q + 1, e = s, pos = s; bool found = false;
   while(pos < StringLen(json))
   {
      int nq = StringFind(json, "\"", pos);
      if(nq < 0) break;
      int bs = 0, kk = nq - 1;
      while(kk >= s && StringGetCharacter(json, kk) == '\\') { bs++; kk--; }
      if(bs % 2 == 0) { e = nq; found = true; break; }
      pos = nq + 1;
   }
   if(!found) return "";
   string out = StringSubstr(json, s, e - s);
   StringReplace(out, "\\\\", "\x01");
   StringReplace(out, "\\\"", "\"");
   StringReplace(out, "\\n", "\n");
   StringReplace(out, "\\r", "\r");
   StringReplace(out, "\\t", "\t");
   StringReplace(out, "\x01", "\\");
   return out;
}

string EscapeJSON(string t)
{
   string r = t;
   StringReplace(r, "\\", "\\\\");
   StringReplace(r, "\"", "\\\"");
   StringReplace(r, "\n", "\\n");
   StringReplace(r, "\r", "\\r");
   StringReplace(r, "\t", "\\t");
   return r;
}

string SimulatedAI()
{
   if(g_AIStatus != "ERROR") g_AIStatus = "SIMULATED";
   double rsi = g_BufferRSI[0];
   if(rsi < 30) return "BUY|0.80|RSI oversold|Long setup.";
   if(rsi > 70) return "SELL|0.80|RSI overbought|Short setup.";
   return "WAIT|0.50|Neutral|No clear edge.";
}

void ParseAIResponse(string resp)
{
   string p[];
   int n = StringSplit(resp, '|', p);
   if(n >= 4)
   {
      g_AISignal = p[0]; StringTrimLeft(g_AISignal); StringTrimRight(g_AISignal);
      g_AIConfidence = StringToDouble(p[1]);
      g_AIReasoning = p[2];
      if(g_AISignal != "BUY" && g_AISignal != "SELL" && g_AISignal != "WAIT") g_AISignal = "WAIT";
      if(g_AIConfidence < 0) g_AIConfidence = 0;
      if(g_AIConfidence > 1) g_AIConfidence = 1;
   }
   else { g_AISignal = "WAIT"; g_AIConfidence = 0; g_AIReasoning = "Invalid"; }
}

void RunTestMode()
{
   if(g_TestCompleted) return;
   if(g_TestStep == 0)
   {
      if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))
      { g_TestCompleted = true; return; }
      g_TestStep = 1;
   }
   if(g_TestStep == 1)
   {
      static int t = 0; t++;
      if(t < 2) return;
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double atr = 0;
      if(CopyBuffer(g_HandleATR, 0, 0, 1, g_BufferATR) >= 1) atr = g_BufferATR[0];
      if(atr <= 0) atr = (ask - SymbolInfoDouble(_Symbol, SYMBOL_BID)) * 10;
      ExecuteBuyOrder(ask, atr);
      g_TestStep = 2; g_TestLastAction = TimeCurrent(); t = 0;
   }
   if(g_TestStep == 2 && TimeCurrent() - g_TestLastAction >= 5)
   { Print("🤖 TEST complete."); g_TestStep = 4; g_TestCompleted = true; }
}

void DrawDashboard()
{
   int x = InpXLeft, y0 = InpYTop;
   CreateRectangle("BG_Left", x, y0, InpWidthLeft, InpPanelHeight, ClrBackground, CORNER_LEFT_UPPER);
   CreateTextLabel("Title_Left", "GOLD PRO v3.7", x + 10, y0 + 5, ClrHeader, true, 10, CORNER_LEFT_UPPER);

   int y = y0 + 30;
   CreateTextLabel("L_StatusHdr", "── STATUS ──", x + 10, y, ClrHeader, true, 9, CORNER_LEFT_UPPER); y += 18;
   CreateTextLabel("L_TradingStatus", "Trading:", x + 10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_TradingStatus", "INIT", x + 130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L_TradeState", "Positions:", x + 10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_TradeState", "FLAT", x + 130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L_BlockReason", "Why no trade:", x + 10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_BlockReason", "--", x + 130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 20;

   CreateTextLabel("L_MktHdr", "── MARKET ──", x + 10, y, ClrHeader, true, 9, CORNER_LEFT_UPPER); y += 18;
   CreateTextLabel("L_MarketState", "State:", x + 10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_MarketState", "OK", x + 130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L_MarketDir", "Direction:", x + 10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_MarketDir", "--", x + 130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L_Spread", "Spread:", x + 10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_Spread", "--", x + 130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L_Velocity", "Velocity:", x + 10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_Velocity", "--", x + 130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 20;

   CreateTextLabel("L_PriceHdr", "── PRICE ──", x + 10, y, ClrHeader, true, 9, CORNER_LEFT_UPPER); y += 18;
   CreateTextLabel("L_BidPrice", "Bid:", x + 10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_BidPrice", "--", x + 130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L_AskPrice", "Ask:", x + 10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_AskPrice", "--", x + 130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 20;

   CreateTextLabel("L_IndHdr", "── INDICATORS ──", x + 10, y, ClrHeader, true, 9, CORNER_LEFT_UPPER); y += 18;
   CreateTextLabel("L_RSI", "RSI:", x + 10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_RSI", "--", x + 130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L_MAFast", "MA Fast:", x + 10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_MAFast", "--", x + 130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L_MASlow", "MA Slow:", x + 10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_MASlow", "--", x + 130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L_ATR", "ATR:", x + 10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_ATR", "--", x + 130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 20;

   CreateTextLabel("L_AIHdr", "── AI ──", x + 10, y, ClrHeader, true, 9, CORNER_LEFT_UPPER); y += 18;
   CreateTextLabel("L_AIStatus", "Status:", x + 10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_AIStatus", "INIT", x + 130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L_AISignal", "Signal:", x + 10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_AISignal", "OFF", x + 130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L_AIConfidence", "Confidence:", x + 10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_AIConfidence", "--", x + 130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L_AIExpectation", "Reasoning:", x + 10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_AIExpectation", "--", x + 130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 20;

   CreateTextLabel("L_PnLHdr", "── PERFORMANCE ──", x + 10, y, ClrHeader, true, 9, CORNER_LEFT_UPPER); y += 18;
   CreateTextLabel("L_DailyPnL", "Day P/L:", x + 10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_DailyPnL", "--", x + 130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 22;

   CreateTextLabel("WarnLine1", "⚠ UNTESTED. Use on DEMO only.", x + 10, y, ClrWarning, false, 8, CORNER_LEFT_UPPER); y += 14;
   CreateTextLabel("WarnLine2", "No guaranteed win rate.", x + 10, y, ClrWarning, false, 8, CORNER_LEFT_UPPER);
}

void CreateRectangle(string name, int x, int y, int w, int h, color bg, int corner)
{
   string obj = g_Prefix + name;
   if(ObjectFind(0, obj) < 0) ObjectCreate(0, obj, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, obj, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, obj, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, obj, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, obj, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, obj, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, obj, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, obj, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, obj, OBJPROP_BACK, false);
   ObjectSetInteger(0, obj, OBJPROP_SELECTABLE, false);
}

void CreateTextLabel(string name, string text, int x, int y, color clr, bool bold, int size, int corner)
{
   string obj = g_Prefix + name;
   if(ObjectFind(0, obj) < 0) ObjectCreate(0, obj, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, obj, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, obj, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, obj, OBJPROP_TEXT, text);
   ObjectSetInteger(0, obj, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, obj, OBJPROP_FONTSIZE, size);
   ObjectSetString(0, obj, OBJPROP_FONT, bold ? "Consolas Bold" : "Consolas");
   ObjectSetInteger(0, obj, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, obj, OBJPROP_BACK, false);
   ObjectSetInteger(0, obj, OBJPROP_SELECTABLE, false);
}

void UpdateUI(string suffix, string value, color clr)
{
   string obj = g_Prefix + "V_" + suffix;
   if(ObjectFind(0, obj) >= 0)
   {
      ObjectSetString(0, obj, OBJPROP_TEXT, value);
      ObjectSetInteger(0, obj, OBJPROP_COLOR, clr);
   }
}
//+------------------------------------------------------------------+