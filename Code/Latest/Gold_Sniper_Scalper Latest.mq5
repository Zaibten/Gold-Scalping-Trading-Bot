//+------------------------------------------------------------------+
//|                                    GOLD DASHBOARD PRO v5.4       |
//|  Dual Engine: AI + Algorithm | EMA 9/21/200 | Profit Scaling     |
//|  SL 40 / TP 60 pips | 0.01 lot per $30 | small trades in profit  |
//+------------------------------------------------------------------+
#property copyright "Gold Dashboard v5.4"
#property version   "5.40"
#property strict

#include <Trade\Trade.mqh>

//═══════════════ INPUTS ═══════════════
input group "═══ Panel ═══"
input int      InpXLeft          = 300;
input int      InpYTop           = 40;
input int      InpWidthLeft      = 330;
input int      InpPanelHeight    = 1010;

input group "═══ Button ═══"
input int      InpBtnX           = 10;
input int      InpBtnY           = 40;
input int      InpBtnWidth       = 260;
input int      InpBtnHeight      = 40;

input group "═══ Colors ═══"
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

input group "═══ Indicators ═══"
input int      InpRSIPeriod      = 14;
input int      InpMAFast         = 20;
input int      InpMASlow         = 50;
input int      InpATRPeriod      = 14;
input int      InpStochK         = 5;
input int      InpStochD         = 3;
input int      InpStochSlowing   = 3;
input int      InpEMAFast        = 9;     // EMA 1
input int      InpEMASlow        = 21;    // EMA 2
input int      InpEMATrend       = 200;   // EMA 3 (trend filter)
input bool     InpUseEMA200Filter = true; // BUY only above EMA200, SELL only below

input group "═══ Pip Definition ═══"
input int      InpPointsPerPip   = 1;     // 1 = pip is 1 point ($0.01). Set 10 for standard gold pip ($0.10)

input group "═══ Dual Engine ═══"
input bool     InpUseAI           = true;
input string   InpOpenAIAPIKey    = "";   // PUT YOUR NEW KEY HERE (empty = simulated AI)
input string   InpOpenAIModel     = "gpt-4o-mini";
input int      InpAIUpdateSeconds = 30;
input double   InpAIConfidenceMin = 0.45;

input bool     InpUseAlgorithm    = true;
input string   InpEngineMode      = "EITHER_AGREE";

input group "═══ Trading Core ═══"
input bool     InpEnableTrading   = true;
input int      InpMagicNumber     = 20251002;
input int      InpMaxPositions    = 1;     // base max positions (extra allowed in Profit Mode)

input group "═══ SIGNAL THRESHOLDS ═══"
input int      InpAlgoMinScore    = 2;
input double   InpAIMinConfEITHER = 0.45;
input bool     InpUseBiasFallback = true;

input group "═══ SPREAD-ADAPTIVE (points) ═══"
input int      InpSpreadNormal     = 25;
input int      InpSpreadElevated   = 35;
input int      InpSpreadHigh       = 45;
input int      InpSpreadExtreme    = 50;   // above this = no new trades
input double   InpSpreadLotMultiplierElevated = 0.70;
input double   InpSpreadLotMultiplierHigh     = 0.50;
input double   InpSpreadLotMultiplierExtreme  = 0.30;
input int      InpSpreadBufferExtraPips       = 5;   // extra SL pips per tier
input double   InpMinProfitSpreadRatio        = 1.0;

input group "═══ Lot Sizing ═══"
input bool     InpUseBalanceTierLot = true;
input double   InpBalancePerLotStep = 30.0;  // every $30 ...
input double   InpLotPerStep        = 0.01;  // ... opens 0.01 lot
input double   InpFixedLot          = 0.01;
input double   InpMaxLotCap         = 0.20;
input double   InpMaxDailyLossPct   = 10.0;
input double   InpMaxDailyProfitPct = 20.0;

input group "═══ Exits (SL 40 / TP 40-60 pips) ═══"
input double   InpDollarTargetMin = 0.4;
input double   InpDollarTargetMax = 0.6;
input double   InpPipTargetMin    = 40.0;
input double   InpPipTargetMax    = 60.0;
input double   InpSLPips          = 40.0;
input bool     InpUseDollarTP     = false;
input bool     InpUsePipTP        = true;

input group "═══ PROFIT MODE (small trades while in profit) ═══"
input bool     InpUseProfitScaling      = true;
input int      InpProfitExtraPositions  = 3;     // extra positions allowed in Profit Mode
input double   InpProfitTradeLot        = 0.01;  // lot of each extra trade
input int      InpProfitModeGapSec      = 3;     // min seconds between trades in Profit Mode

input group "═══ Loss Protection ═══"
input int      InpCooldownAfterLossSec = 15;
input int      InpMaxConsecutiveLosses = 3;
input int      InpConsecLossPauseMin   = 2;
input int      InpMinSecondsBetweenTrades = 5;

input group "═══ Session Windows ═══"
input bool     InpUseSessionWindows = true;
input int      InpSession1StartHour = 2;
input int      InpSession1EndHour   = 8;
input int      InpSession2StartHour = 14;
input int      InpSession2EndHour   = 22;

input group "═══ Auto-Close ═══"
input bool     InpCloseOnOppositeAI = true;
input int      InpCloseMaxAgeMin    = 30;

input group "═══ Trailing ═══"
input bool     InpUseBreakEven    = true;
input double   InpBE_TriggerPips  = 20.0;
input double   InpBE_OffsetPips   = 5.0;
input bool     InpUseTrailing     = true;
input double   InpTrailPips       = 25.0;
input double   InpTrailStepPips   = 5.0;

input group "═══ Entry ═══"
input int      InpEntryCheckSec   = 1;

input group "═══ RSI Zones ═══"
input double   InpRSIBuyLevel     = 40.0;
input double   InpRSISellLevel    = 60.0;

//═══════════════ GLOBALS ═══════════════
string   g_Prefix = "GOLDPRO_v54_";
int      g_hRSI, g_hMAFast, g_hMASlow, g_hATR, g_hStoch, g_hEMAFast, g_hEMASlow, g_hEMATrend;
double   g_bRSI[], g_bMAFast[], g_bMASlow[], g_bATR[], g_bStochK[], g_bStochD[], g_bEMAFast[], g_bEMASlow[], g_bEMATrend[];
int      g_Digits = 0;
double   g_Point  = 0.0;
double   g_Pip    = 0.0;
CTrade   g_Trade;

bool     g_Paused = false;
datetime g_LastEntryCheck = 0, g_LastAICheck = 0;
datetime g_CooldownUntil = 0;
int      g_ConsecutiveLosses = 0;
int      g_ConsecutiveWins = 0;
datetime g_LastTradeTime = 0;
datetime g_ConsecLossPauseUntil = 0;

string   g_BlockReason = "";
color    g_BlockColor = ClrValue;
bool     g_InSessionNow = false;
bool     g_ProfitMode = false;

int      g_WaitSecondsRemaining = 0;
string   g_WaitCategory = "";

// Dual engine state
string   g_AISignal = "WAIT";
double   g_AIConfidence = 0.0;
string   g_AIReasoning = "";
bool     g_AIActive = false;
string   g_AIStatus = "INIT";

string   g_AlgoSignal = "WAIT";
double   g_AlgoConfidence = 0.0;
string   g_AlgoReason = "";
int      g_AlgoBuyScore = 0;
int      g_AlgoSellScore = 0;
int      g_AlgoMinScoreNeeded = 2;

string   g_FinalSignal = "WAIT";
string   g_FinalReason = "";
string   g_FireReason = "";

// Spread-adaptive state
int      g_CurrentSpread = 0;
string   g_SpreadTier = "NORMAL";
color    g_SpreadTierColor = ClrValue;
double   g_AdaptiveTP_Pips = 0.0;
double   g_AdaptiveSL_Pips = 0.0;
double   g_AdaptiveLotMult = 1.0;

// Tracking
int      g_TotalTrades = 0, g_Wins = 0, g_Losses = 0;
double   g_TotalProfit = 0.0;
double   g_DayStartBalance = 0.0;
datetime g_DayStartTime = 0;
bool     g_DailyHit = false;

ulong    g_LastSeen[];

//═══════════════ INIT ═══════════════
int OnInit()
{
   g_Digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   g_Point  = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   g_Pip    = g_Point * MathMax(1, InpPointsPerPip);
   SymbolSelect(_Symbol, true);

   g_hRSI      = iRSI(_Symbol, PERIOD_CURRENT, InpRSIPeriod, PRICE_CLOSE);
   g_hMAFast   = iMA(_Symbol, PERIOD_CURRENT, InpMAFast, 0, MODE_EMA, PRICE_CLOSE);
   g_hMASlow   = iMA(_Symbol, PERIOD_CURRENT, InpMASlow, 0, MODE_EMA, PRICE_CLOSE);
   g_hATR      = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);
   g_hStoch    = iStochastic(_Symbol, PERIOD_CURRENT, InpStochK, InpStochD, InpStochSlowing, MODE_SMA, STO_LOWHIGH);
   g_hEMAFast  = iMA(_Symbol, PERIOD_CURRENT, InpEMAFast, 0, MODE_EMA, PRICE_CLOSE);
   g_hEMASlow  = iMA(_Symbol, PERIOD_CURRENT, InpEMASlow, 0, MODE_EMA, PRICE_CLOSE);
   g_hEMATrend = iMA(_Symbol, PERIOD_CURRENT, InpEMATrend, 0, MODE_EMA, PRICE_CLOSE);

   if(g_hRSI==INVALID_HANDLE||g_hMAFast==INVALID_HANDLE||g_hMASlow==INVALID_HANDLE||
      g_hATR==INVALID_HANDLE||g_hStoch==INVALID_HANDLE||g_hEMAFast==INVALID_HANDLE||
      g_hEMASlow==INVALID_HANDLE||g_hEMATrend==INVALID_HANDLE)
   { Print("Indicator init failed"); return INIT_FAILED; }

   ArraySetAsSeries(g_bRSI,true); ArraySetAsSeries(g_bMAFast,true);
   ArraySetAsSeries(g_bMASlow,true); ArraySetAsSeries(g_bATR,true);
   ArraySetAsSeries(g_bStochK,true); ArraySetAsSeries(g_bStochD,true);
   ArraySetAsSeries(g_bEMAFast,true); ArraySetAsSeries(g_bEMASlow,true);
   ArraySetAsSeries(g_bEMATrend,true);

   g_Trade.SetExpertMagicNumber(InpMagicNumber);
   g_Trade.SetDeviationInPoints(50);
   long filling = SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((filling & SYMBOL_FILLING_FOK)==SYMBOL_FILLING_FOK) g_Trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if((filling & SYMBOL_FILLING_IOC)==SYMBOL_FILLING_IOC) g_Trade.SetTypeFilling(ORDER_FILLING_IOC);
   else g_Trade.SetTypeFilling(ORDER_FILLING_RETURN);

   DrawDashboard();
   CreateStartStopButton();
   EventSetTimer(1);

   g_DayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_DayStartTime = TimeCurrent();

   Print("═══ GOLD PRO v5.4 — EMA 9/21/200 + PROFIT SCALING ═══");
   Print("Mode: ", InpEngineMode);
   Print("SL: ", InpSLPips, " pips | TP: ", InpPipTargetMin, "-", InpPipTargetMax, " pips | 1 pip = ", InpPointsPerPip, " point(s)");
   Print("Lot: ", InpLotPerStep, " per $", InpBalancePerLotStep, " balance");
   Print("Profit mode: ", InpUseProfitScaling ? "ON" : "OFF", " | extra positions: ", InpProfitExtraPositions, " @ ", InpProfitTradeLot, " lot");
   Print("EMA200 filter: ", InpUseEMA200Filter ? "ON" : "OFF");
   Print("═══════════════════════════════════════════");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectsDeleteAll(0, g_Prefix);
   if(g_hRSI!=INVALID_HANDLE) IndicatorRelease(g_hRSI);
   if(g_hMAFast!=INVALID_HANDLE) IndicatorRelease(g_hMAFast);
   if(g_hMASlow!=INVALID_HANDLE) IndicatorRelease(g_hMASlow);
   if(g_hATR!=INVALID_HANDLE) IndicatorRelease(g_hATR);
   if(g_hStoch!=INVALID_HANDLE) IndicatorRelease(g_hStoch);
   if(g_hEMAFast!=INVALID_HANDLE) IndicatorRelease(g_hEMAFast);
   if(g_hEMASlow!=INVALID_HANDLE) IndicatorRelease(g_hEMASlow);
   if(g_hEMATrend!=INVALID_HANDLE) IndicatorRelease(g_hEMATrend);
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK) return;
   if(sparam == g_Prefix + "BtnStartStop")
   {
      g_Paused = !g_Paused;
      UpdateButtonLabel();
      Print(g_Paused ? "PAUSED" : "RESUMED");
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
   UpdateButtonLabel();
}

void UpdateButtonLabel()
{
   string name = g_Prefix + "BtnStartStop";
   if(ObjectFind(0, name) < 0) return;
   ObjectSetString(0, name, OBJPROP_TEXT, g_Paused ? "RESUME TRADING" : "PAUSE TRADING");
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, g_Paused ? ClrBtnStart : ClrBtnStop);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
}

bool IsInSession()
{
   if(!InpUseSessionWindows) return true;
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   int h = dt.hour;
   if(h >= InpSession1StartHour && h < InpSession1EndHour) return true;
   if(h >= InpSession2StartHour && h < InpSession2EndHour) return true;
   return false;
}

string SessionName()
{
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   int h = dt.hour;
   if(h >= InpSession1StartHour && h < InpSession1EndHour) return "SESSION 1";
   if(h >= InpSession2StartHour && h < InpSession2EndHour) return "SESSION 2";
   return "OUTSIDE";
}

//═══════════════ SPREAD-ADAPTIVE CORE ═══════════════
// TP always stays inside the 40-60 pip window; SL widens slightly on wider spreads
void UpdateSpreadProfile(double bid, double ask)
{
   g_CurrentSpread = (int)MathRound((ask - bid) / g_Point);

   double tp = MathMax(InpPipTargetMin, InpPipTargetMax);

   if(g_CurrentSpread <= InpSpreadNormal)
   {
      g_SpreadTier = "NORMAL";
      g_SpreadTierColor = ClrBuy;
      g_AdaptiveLotMult = 1.0;
      g_AdaptiveTP_Pips = tp;
      g_AdaptiveSL_Pips = InpSLPips;
   }
   else if(g_CurrentSpread <= InpSpreadElevated)
   {
      g_SpreadTier = "ELEVATED";
      g_SpreadTierColor = ClrValue;
      g_AdaptiveLotMult = InpSpreadLotMultiplierElevated;
      g_AdaptiveTP_Pips = tp;
      g_AdaptiveSL_Pips = InpSLPips + InpSpreadBufferExtraPips;
   }
   else if(g_CurrentSpread <= InpSpreadHigh)
   {
      g_SpreadTier = "HIGH";
      g_SpreadTierColor = ClrWarning;
      g_AdaptiveLotMult = InpSpreadLotMultiplierHigh;
      g_AdaptiveTP_Pips = tp;
      g_AdaptiveSL_Pips = InpSLPips + InpSpreadBufferExtraPips * 2;
   }
   else
   {
      g_SpreadTier = "EXTREME";
      g_SpreadTierColor = ClrSell;
      g_AdaptiveLotMult = InpSpreadLotMultiplierExtreme;
      g_AdaptiveTP_Pips = tp;
      g_AdaptiveSL_Pips = InpSLPips + InpSpreadBufferExtraPips * 3;
   }
}

//═══════════════ PROFIT MODE HELPERS ═══════════════
int OpenDirection()
{
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      return (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1;
   }
   return 0;
}

bool AllOpenInProfit()
{
   int n = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      n++;
      double p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if(p <= 0) return false;
   }
   return (n > 0);
}

// Profit mode: day is positive AND (last trade won OR all open trades are in profit)
bool ProfitModeActive()
{
   if(!InpUseProfitScaling) return false;
   double pnl = AccountInfoDouble(ACCOUNT_EQUITY) - g_DayStartBalance;
   if(pnl <= 0) return false;
   if(g_ConsecutiveWins >= 1) return true;
   if(AllOpenInProfit()) return true;
   return false;
}

//═══════════════ TICK ═══════════════
void OnTick()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   g_InSessionNow = IsInSession();
   UpdateSpreadProfile(bid, ask);

   DetectClosedPositions();
   UpdateAllData();

   if(InpEnableTrading)
   {
      ManageScalperExits();
      ManageBreakEvenAndTrailing();
      ManageAutoClose();
   }

   if(InpEnableTrading && !g_Paused &&
      TimeCurrent() - g_LastEntryCheck >= InpEntryCheckSec)
   {
      g_LastEntryCheck = TimeCurrent();
      ProcessDualEngine();
   }

   ChartRedraw(0);
}

void OnTimer()
{
   DetectClosedPositions();
   UpdateAllData();
   ChartRedraw(0);
}

//═══════════════ DUAL ENGINE ═══════════════
void ProcessDualEngine()
{
   g_ProfitMode = ProfitModeActive();

   string reason; color rc; int waitSec = 0; string waitCat = "";
   if(!CanOpenNewTrade(reason, rc, waitSec, waitCat))
   {
      g_BlockReason = reason; g_BlockColor = rc;
      g_WaitSecondsRemaining = waitSec;
      g_WaitCategory = waitCat;
      return;
   }
   g_WaitSecondsRemaining = 0;
   g_WaitCategory = "";

   if(CopyBuffer(g_hRSI,0,0,2,g_bRSI) < 2) return;
   if(CopyBuffer(g_hMAFast,0,0,2,g_bMAFast) < 2) return;
   if(CopyBuffer(g_hMASlow,0,0,2,g_bMASlow) < 2) return;
   if(CopyBuffer(g_hATR,0,0,2,g_bATR) < 2) return;
   if(CopyBuffer(g_hStoch,0,0,2,g_bStochK) < 2) return;
   if(CopyBuffer(g_hStoch,1,0,2,g_bStochD) < 2) return;
   if(CopyBuffer(g_hEMAFast,0,0,2,g_bEMAFast) < 2) return;
   if(CopyBuffer(g_hEMASlow,0,0,2,g_bEMASlow) < 2) return;
   if(CopyBuffer(g_hEMATrend,0,0,2,g_bEMATrend) < 2) return;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double atr = g_bATR[0];

   if(InpUseAlgorithm) EvaluateAlgorithm();
   else { g_AlgoSignal = "WAIT"; g_AlgoConfidence = 0; g_AlgoReason = "Algo OFF"; }

   if(InpUseAI) UpdateAIAnalysis(bid, ask, atr);
   else { g_AISignal = "WAIT"; g_AIConfidence = 0; g_AIReasoning = "AI OFF"; }

   ResolveFinalSignal();

   // Extra (small) trades must follow the direction of the trade already open
   int open = CountOpen();
   if(open > 0 && g_FinalSignal != "WAIT")
   {
      int dir = OpenDirection();
      if((g_FinalSignal == "BUY" && dir < 0) || (g_FinalSignal == "SELL" && dir > 0))
      {
         g_BlockReason = "WAIT: signal opposite to open trade";
         g_BlockColor = ClrNeutral;
         return;
      }
   }

   if(g_FinalSignal == "BUY")
   {
      ExecuteBuy(ask, atr);
      g_BlockReason = "OPENED BUY: " + g_FireReason;
      g_BlockColor = ClrBuy;
   }
   else if(g_FinalSignal == "SELL")
   {
      ExecuteSell(bid, atr);
      g_BlockReason = "OPENED SELL: " + g_FireReason;
      g_BlockColor = ClrSell;
   }
   else
   {
      g_BlockReason = "WAIT: " + g_FinalReason;
      g_BlockColor = ClrNeutral;
   }
}

//═══════════════ ALGORITHM ═══════════════
void EvaluateAlgorithm()
{
   double rsi = g_bRSI[0];
   double rsiPrev = g_bRSI[1];
   double emaF = g_bEMAFast[0];
   double emaS = g_bEMASlow[0];
   double emaFprev = g_bEMAFast[1];
   double emaSprev = g_bEMASlow[1];
   double stK = g_bStochK[0];
   double stD = g_bStochD[0];
   double stKprev = g_bStochK[1];
   double stDprev = g_bStochD[1];
   double maF = g_bMAFast[0];
   double maS = g_bMASlow[0];
   double ema200 = g_bEMATrend[0];
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   bool trendUp   = (price > ema200);
   bool trendDown = (price < ema200);

   int buyScore = 0, sellScore = 0;

   // RSI reversal
   if(rsi < InpRSIBuyLevel && rsi > rsiPrev) buyScore += 2;
   if(rsi > InpRSISellLevel && rsi < rsiPrev) sellScore += 2;

   // EMA 9/21 cross
   if(emaF > emaS && emaFprev <= emaSprev) buyScore += 2;
   if(emaF < emaS && emaFprev >= emaSprev) sellScore += 2;

   // Stoch cross
   if(stK > stD && stKprev <= stDprev && stK < 35) buyScore += 2;
   if(stK < stD && stKprev >= stDprev && stK > 65) sellScore += 2;

   // Trend alignment
   if(emaF > emaS) buyScore += 1;
   if(emaF < emaS) sellScore += 1;
   if(maF > maS) buyScore += 1;
   if(maF < maS) sellScore += 1;

   // EMA 200 alignment
   if(trendUp)   buyScore += 1;
   if(trendDown) sellScore += 1;

   // Momentum zone
   if(rsi < 55 && rsi > 30) buyScore += 1;
   if(rsi > 45 && rsi < 70) sellScore += 1;

   g_AlgoBuyScore = buyScore;
   g_AlgoSellScore = sellScore;

   int minScore = InpAlgoMinScore;
   if(g_SpreadTier == "ELEVATED") minScore += 1;
   if(g_SpreadTier == "HIGH")     minScore += 1;
   if(g_SpreadTier == "EXTREME")  minScore += 2;
   g_AlgoMinScoreNeeded = minScore;

   bool biasBuy = false, biasSell = false;
   if(InpUseBiasFallback)
   {
      if(rsi < InpRSIBuyLevel && emaF > emaS) biasBuy = true;
      if(rsi > InpRSISellLevel && emaF < emaS) biasSell = true;
   }

   // EMA200 trend filter on the algo itself
   if(InpUseEMA200Filter)
   {
      if(!trendUp)   { biasBuy = false;  buyScore = 0; }
      if(!trendDown) { biasSell = false; sellScore = 0; }
   }

   if((buyScore >= minScore && buyScore > sellScore) || biasBuy)
   {
      g_AlgoSignal = "BUY";
      g_AlgoConfidence = MathMin(1.0, MathMax(buyScore, 3) / 8.0);
      g_AlgoReason = (biasBuy && buyScore < minScore)
                     ? "BUY bias (RSI+EMA)"
                     : "Buy " + IntegerToString(buyScore) + "/" + IntegerToString(minScore);
   }
   else if((sellScore >= minScore && sellScore > buyScore) || biasSell)
   {
      g_AlgoSignal = "SELL";
      g_AlgoConfidence = MathMin(1.0, MathMax(sellScore, 3) / 8.0);
      g_AlgoReason = (biasSell && sellScore < minScore)
                     ? "SELL bias (RSI+EMA)"
                     : "Sell " + IntegerToString(sellScore) + "/" + IntegerToString(minScore);
   }
   else
   {
      g_AlgoSignal = "WAIT";
      g_AlgoConfidence = 0.0;
      g_AlgoReason = "B" + IntegerToString(buyScore) + "/S" + IntegerToString(sellScore) + " need " + IntegerToString(minScore);
   }
}

//═══════════════ SIGNAL RESOLUTION ═══════════════
void ResolveFinalSignal()
{
   ResolveFinalSignalRaw();

   // EMA200 filter applied to the final decision (covers AI signals too)
   if(InpUseEMA200Filter && g_FinalSignal != "WAIT" && ArraySize(g_bEMATrend) > 0)
   {
      double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ema200 = g_bEMATrend[0];
      if(g_FinalSignal == "BUY" && price < ema200)
      { g_FinalSignal = "WAIT"; g_FinalReason = "BUY blocked: below EMA200"; g_FireReason = ""; }
      else if(g_FinalSignal == "SELL" && price > ema200)
      { g_FinalSignal = "WAIT"; g_FinalReason = "SELL blocked: above EMA200"; g_FireReason = ""; }
   }
}

void ResolveFinalSignalRaw()
{
   string mode = InpEngineMode;
   g_FireReason = "";

   if(mode == "EITHER_AGREE")
   {
      bool algoBuy  = (g_AlgoSignal == "BUY");
      bool algoSell = (g_AlgoSignal == "SELL");
      bool aiBuy    = (g_AISignal == "BUY"  && g_AIConfidence >= InpAIMinConfEITHER);
      bool aiSell   = (g_AISignal == "SELL" && g_AIConfidence >= InpAIMinConfEITHER);

      if(algoBuy && aiBuy)   { g_FinalSignal = "BUY";  g_FireReason = "BOTH BUY";       g_FinalReason = "Both BUY"; return; }
      if(algoSell && aiSell) { g_FinalSignal = "SELL"; g_FireReason = "BOTH SELL";      g_FinalReason = "Both SELL"; return; }

      if(algoBuy)  { g_FinalSignal = "BUY";  g_FireReason = "Algo alone BUY";  g_FinalReason = "Algo BUY"; return; }
      if(algoSell) { g_FinalSignal = "SELL"; g_FireReason = "Algo alone SELL"; g_FinalReason = "Algo SELL"; return; }

      if(aiBuy)    { g_FinalSignal = "BUY";  g_FireReason = "AI alone BUY";    g_FinalReason = "AI BUY"; return; }
      if(aiSell)   { g_FinalSignal = "SELL"; g_FireReason = "AI alone SELL";   g_FinalReason = "AI SELL"; return; }

      g_FinalSignal = "WAIT";
      g_FinalReason = "Algo=" + g_AlgoSignal + " AI=" + g_AISignal;
      return;
   }

   if(mode == "AI_ONLY")
   {
      g_FinalSignal = (g_AISignal == "BUY" && g_AIConfidence >= InpAIConfidenceMin) ? "BUY" :
                      (g_AISignal == "SELL" && g_AIConfidence >= InpAIConfidenceMin) ? "SELL" : "WAIT";
      g_FinalReason = "AI:" + g_AISignal;
      g_FireReason = g_FinalReason;
      return;
   }
   if(mode == "ALGO_ONLY")
   {
      g_FinalSignal = g_AlgoSignal;
      g_FinalReason = "Algo:" + g_AlgoSignal;
      g_FireReason = g_FinalReason;
      return;
   }
   if(mode == "EITHER_HIGH_CONF")
   {
      if(g_AISignal == "BUY" && g_AIConfidence >= 0.70) { g_FinalSignal = "BUY"; g_FinalReason = "AI high conf BUY"; g_FireReason = g_FinalReason; return; }
      if(g_AISignal == "SELL" && g_AIConfidence >= 0.70) { g_FinalSignal = "SELL"; g_FinalReason = "AI high conf SELL"; g_FireReason = g_FinalReason; return; }
      if(g_AlgoSignal == "BUY" && g_AlgoConfidence >= 0.75) { g_FinalSignal = "BUY"; g_FinalReason = "Algo high conf BUY"; g_FireReason = g_FinalReason; return; }
      if(g_AlgoSignal == "SELL" && g_AlgoConfidence >= 0.75) { g_FinalSignal = "SELL"; g_FinalReason = "Algo high conf SELL"; g_FireReason = g_FinalReason; return; }
      g_FinalSignal = "WAIT"; g_FinalReason = "No high conf";
      return;
   }

   // BOTH_MUST_AGREE
   if(!InpUseAI && InpUseAlgorithm) { g_FinalSignal = g_AlgoSignal; g_FinalReason = "Algo only"; g_FireReason = g_FinalReason; return; }
   if(InpUseAI && !InpUseAlgorithm) { g_FinalSignal = (g_AISignal != "WAIT") ? g_AISignal : "WAIT"; g_FinalReason = "AI only"; g_FireReason = g_FinalReason; return; }
   if(!InpUseAI && !InpUseAlgorithm) { g_FinalSignal = "WAIT"; g_FinalReason = "Both OFF"; return; }

   if(g_AISignal == "BUY" && g_AlgoSignal == "BUY")
   { g_FinalSignal = "BUY"; g_FinalReason = "Both BUY"; g_FireReason = g_FinalReason; return; }
   if(g_AISignal == "SELL" && g_AlgoSignal == "SELL")
   { g_FinalSignal = "SELL"; g_FinalReason = "Both SELL"; g_FireReason = g_FinalReason; return; }

   g_FinalSignal = "WAIT";
   g_FinalReason = "AI=" + g_AISignal + " Algo=" + g_AlgoSignal;
}

//═══════════════ SCALPER EXITS ═══════════════
void ManageScalperExits()
{
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;

      double profit = PositionGetDouble(POSITION_PROFIT)
                    + PositionGetDouble(POSITION_SWAP);
      double volume = PositionGetDouble(POSITION_VOLUME);
      double entry  = PositionGetDouble(POSITION_PRICE_OPEN);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      ENUM_POSITION_TYPE ptype = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      double pipProfit = 0.0;
      if(ptype == POSITION_TYPE_BUY)  pipProfit = (bid - entry) / g_Pip;
      if(ptype == POSITION_TYPE_SELL) pipProfit = (entry - ask) / g_Pip;

      double spreadUSD = (double)g_CurrentSpread * 0.01 * (volume / 0.01);
      double minProfitRequired = spreadUSD * InpMinProfitSpreadRatio;

      double lotsFactor = volume / 0.01;
      double dynDollarMin = InpDollarTargetMin * MathMin(lotsFactor, 2.0);
      double dynDollarMax = InpDollarTargetMax * MathMin(lotsFactor, 2.0);

      // Adaptive pip TP (60 pips by default)
      if(InpUsePipTP && pipProfit >= g_AdaptiveTP_Pips && profit >= minProfitRequired)
      {
         PrintFormat("📈 PIP TP #%I64u pips=%.1f (target %.1f) $%.2f", t, pipProfit, g_AdaptiveTP_Pips, profit);
         g_Trade.PositionClose(t); continue;
      }
      // Optional dollar TP (off by default)
      if(InpUseDollarTP && profit >= dynDollarMax && pipProfit >= InpPipTargetMin)
      {
         PrintFormat("💰 DOLLAR TP #%I64u $%.2f pips=%.1f", t, profit, pipProfit);
         g_Trade.PositionClose(t); continue;
      }
      if(InpUseDollarTP && profit >= dynDollarMin && pipProfit >= InpPipTargetMin && profit >= minProfitRequired)
      {
         PrintFormat("✅ SAFE EXIT #%I64u $%.2f pips=%.1f", t, profit, pipProfit);
         g_Trade.PositionClose(t); continue;
      }
   }
}

//═══════════════ ORDER EXECUTION ═══════════════
void ExecuteBuy(double ask, double atr)
{
   if(ask <= 0) return;
   bool extra = (CountOpen() >= InpMaxPositions);

   double minStop = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * g_Point;
   double slDist = g_AdaptiveSL_Pips * g_Pip;
   double tpDist = g_AdaptiveTP_Pips * g_Pip;
   if(minStop > 0 && slDist < minStop) slDist = minStop;
   if(minStop > 0 && tpDist < minStop) tpDist = minStop;

   double sl = NormalizeDouble(ask - slDist, g_Digits);
   double tp = NormalizeDouble(ask + tpDist, g_Digits);
   double lots = CalculateLotSize(extra);

   PrintFormat("BUY lots=%.2f SL=%.1f TP=%.1f pips %s reason=%s",
               lots, g_AdaptiveSL_Pips, g_AdaptiveTP_Pips, extra ? "[PROFIT-MODE EXTRA]" : "", g_FireReason);
   if(g_Trade.Buy(lots, _Symbol, ask, sl, tp, extra ? "GOLDPRO BUY+" : "GOLDPRO BUY"))
   {
      g_LastTradeTime = TimeCurrent();
      Print("✅ BUY #", g_Trade.ResultOrder());
   }
   else Print("❌ BUY fail: ", g_Trade.ResultRetcodeDescription());
}

void ExecuteSell(double bid, double atr)
{
   if(bid <= 0) return;
   bool extra = (CountOpen() >= InpMaxPositions);

   double minStop = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * g_Point;
   double slDist = g_AdaptiveSL_Pips * g_Pip;
   double tpDist = g_AdaptiveTP_Pips * g_Pip;
   if(minStop > 0 && slDist < minStop) slDist = minStop;
   if(minStop > 0 && tpDist < minStop) tpDist = minStop;

   double sl = NormalizeDouble(bid + slDist, g_Digits);
   double tp = NormalizeDouble(bid - tpDist, g_Digits);
   double lots = CalculateLotSize(extra);

   PrintFormat("SELL lots=%.2f SL=%.1f TP=%.1f pips %s reason=%s",
               lots, g_AdaptiveSL_Pips, g_AdaptiveTP_Pips, extra ? "[PROFIT-MODE EXTRA]" : "", g_FireReason);
   if(g_Trade.Sell(lots, _Symbol, bid, sl, tp, extra ? "GOLDPRO SELL+" : "GOLDPRO SELL"))
   {
      g_LastTradeTime = TimeCurrent();
      Print("✅ SELL #", g_Trade.ResultOrder());
   }
   else Print("❌ SELL fail: ", g_Trade.ResultRetcodeDescription());
}

//═══════════════ LOT SIZING ═══════════════
// Normal trade: InpLotPerStep for every InpBalancePerLotStep of balance (0.01 per $30)
// Extra trade (profit mode): small fixed lot (InpProfitTradeLot)
double CalculateLotSize(bool extra = false)
{
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);

   double lots;
   if(extra)
   {
      lots = InpProfitTradeLot;
   }
   else if(InpUseBalanceTierLot)
   {
      lots = MathFloor(balance / InpBalancePerLotStep) * InpLotPerStep;
      if(lots < InpLotPerStep) lots = InpLotPerStep;
      if(lots > InpMaxLotCap) lots = InpMaxLotCap;
   }
   else
   {
      lots = InpFixedLot;
   }

   lots *= g_AdaptiveLotMult;

   lots = MathMax(minLot, MathMin(maxLot, lots));
   lots = MathRound(lots / step) * step;
   return NormalizeDouble(lots, 2);
}

//═══════════════ TRADE GUARDS ═══════════════
bool CanOpenNewTrade(string &reason, color &rc, int &waitSec, string &waitCat)
{
   rc = ClrValue;
   waitSec = 0;
   waitCat = "";

   if(g_Paused) { reason = "USER PAUSED"; rc = ClrWarning; return false; }
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) { reason = "TERMINAL DISABLED"; rc = ClrSell; return false; }
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED)) { reason = "EA OFF"; rc = ClrSell; return false; }
   if(DailyLimitReached()) { reason = "DAILY LIMIT"; rc = ClrSell; return false; }

   if(!g_InSessionNow)
   {
      reason = "OUTSIDE SESSION"; rc = ClrNeutral;
      waitCat = "SESSION"; waitSec = SecondsUntilNextSession();
      return false;
   }

   if(g_CooldownUntil > TimeCurrent())
   {
      int rem = (int)(g_CooldownUntil - TimeCurrent());
      reason = "COOLDOWN " + IntegerToString(rem) + "s";
      rc = ClrWarning; waitCat = "COOLDOWN"; waitSec = rem;
      return false;
   }

   if(g_ConsecLossPauseUntil > TimeCurrent())
   {
      int rem = (int)(g_ConsecLossPauseUntil - TimeCurrent());
      reason = "LOSS PAUSE " + IntegerToString(rem/60) + "m " + IntegerToString(rem%60) + "s";
      rc = ClrSell; waitCat = "LOSS-PAUSE"; waitSec = rem;
      return false;
   }

   int gap = g_ProfitMode ? InpProfitModeGapSec : InpMinSecondsBetweenTrades;
   if(TimeCurrent() - g_LastTradeTime < gap)
   {
      int rem = gap - (int)(TimeCurrent() - g_LastTradeTime);
      reason = "WAIT " + IntegerToString(rem) + "s";
      rc = ClrNeutral; waitCat = "TRADE-GAP"; waitSec = rem;
      return false;
   }

   int open = CountOpen();
   int maxPos = InpMaxPositions + (g_ProfitMode ? InpProfitExtraPositions : 0);
   if(open >= maxPos)
   {
      reason = "POSITION LIMIT (" + IntegerToString(open) + "/" + IntegerToString(maxPos) + ")";
      rc = ClrNeutral;
      return false;
   }

   // Adding beyond the base limit only while every open trade is in profit
   if(open >= InpMaxPositions && !AllOpenInProfit())
   {
      reason = "OPEN TRADE NOT IN PROFIT";
      rc = ClrNeutral;
      return false;
   }

   if(g_CurrentSpread > InpSpreadExtreme)
   {
      reason = "SPREAD TOO HIGH " + IntegerToString(g_CurrentSpread);
      rc = ClrSell; waitCat = "SPREAD"; waitSec = 5;
      return false;
   }

   reason = ""; return true;
}

int SecondsUntilNextSession()
{
   if(!InpUseSessionWindows) return 0;
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   int curSec = dt.hour * 3600 + dt.min * 60 + dt.sec;

   int starts[2];
   starts[0] = InpSession1StartHour * 3600;
   starts[1] = InpSession2StartHour * 3600;

   int best = 24*3600;
   for(int i=0;i<2;i++)
   {
      int diff = starts[i] - curSec;
      if(diff <= 0) diff += 24*3600;
      if(diff < best) best = diff;
   }
   return best;
}

int CountOpen()
{
   int c = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == InpMagicNumber) c++;
   }
   return c;
}

//═══════════════ DAILY LIMITS ═══════════════
void CheckNewDay()
{
   MqlDateTime a, b;
   TimeToStruct(g_DayStartTime, a);
   TimeToStruct(TimeCurrent(), b);
   if(a.day != b.day || a.mon != b.mon || a.year != b.year)
   {
      g_DayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      g_DayStartTime = TimeCurrent();
      g_DailyHit = false;
      g_ConsecutiveLosses = 0;
      g_ConsecutiveWins = 0;
      g_CooldownUntil = 0;
      g_ConsecLossPauseUntil = 0;
      Print("─── NEW DAY ───");
   }
}

bool DailyLimitReached()
{
   CheckNewDay();
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   double pnl = eq - g_DayStartBalance;
   double pct = (g_DayStartBalance > 0) ? (pnl / g_DayStartBalance) * 100.0 : 0.0;
   if(pct <= -InpMaxDailyLossPct) { if(!g_DailyHit) { Print("🛑 DAILY LOSS LIMIT ", DoubleToString(pct,2), "%"); g_DailyHit = true; } return true; }
   if(pct >= InpMaxDailyProfitPct) { if(!g_DailyHit) { Print("🎯 DAILY PROFIT LIMIT ", DoubleToString(pct,2), "%"); g_DailyHit = true; } return true; }
   return false;
}

//═══════════════ TRADE HISTORY ═══════════════
void DetectClosedPositions()
{
   ulong current[];
   int curCount = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      ArrayResize(current, curCount + 1);
      current[curCount++] = t;
   }

   for(int i = 0; i < ArraySize(g_LastSeen); i++)
   {
      ulong old = g_LastSeen[i];
      bool stillOpen = false;
      for(int j = 0; j < curCount; j++) if(current[j] == old) { stillOpen = true; break; }
      if(stillOpen) continue;

      if(HistorySelect(TimeCurrent() - 86400, TimeCurrent() + 60))
      {
         int deals = HistoryDealsTotal();
         for(int d = deals-1; d >= 0; d--)
         {
            ulong dt = HistoryDealGetTicket(d);
            if(dt == 0) continue;
            if(HistoryDealGetString(dt, DEAL_SYMBOL) != _Symbol) continue;
            if(HistoryDealGetInteger(dt, DEAL_MAGIC) != InpMagicNumber) continue;
            if(HistoryDealGetInteger(dt, DEAL_POSITION_ID) != old) continue;
            double profit = HistoryDealGetDouble(dt, DEAL_PROFIT)
                          + HistoryDealGetDouble(dt, DEAL_SWAP)
                          + HistoryDealGetDouble(dt, DEAL_COMMISSION);
            g_TotalTrades++;
            g_TotalProfit += profit;
            if(profit > 0)
            {
               g_Wins++;
               g_ConsecutiveLosses = 0;
               g_ConsecutiveWins++;
               Print("✅ WIN +", DoubleToString(profit, 2), " (streak ", g_ConsecutiveWins, ")");
            }
            else if(profit < 0)
            {
               g_Losses++; g_ConsecutiveLosses++;
               g_ConsecutiveWins = 0;
               g_CooldownUntil = TimeCurrent() + InpCooldownAfterLossSec;
               if(g_ConsecutiveLosses >= InpMaxConsecutiveLosses)
               {
                  g_ConsecLossPauseUntil = TimeCurrent() + InpConsecLossPauseMin * 60;
                  Print("⚠ ", g_ConsecutiveLosses, " losses → paused ", InpConsecLossPauseMin, "min");
               }
               Print("❌ LOSS ", DoubleToString(profit, 2));
            }
            break;
         }
      }
   }
   ArrayResize(g_LastSeen, curCount);
   for(int i = 0; i < curCount; i++) g_LastSeen[i] = current[i];
}

//═══════════════ AI ENGINE ═══════════════
void UpdateAIAnalysis(double bid, double ask, double atr)
{
   datetime now = TimeCurrent();
   if(now - g_LastAICheck >= InpAIUpdateSeconds || g_LastAICheck == 0)
   {
      g_LastAICheck = now;
      string resp = CallOpenAI(BuildContext(bid, ask, atr));
      ParseAI(resp);
   }
}

string BuildContext(double bid, double ask, double atr)
{
   double rsi = g_bRSI[0];
   bool maBull = (g_bMAFast[0] > g_bMASlow[0]);
   bool above200 = (bid > g_bEMATrend[0]);
   double wr = (g_TotalTrades > 0) ? ((double)g_Wins / g_TotalTrades) * 100.0 : 0.0;
   string ctx = "XAUUSD M1 scalper. Reply ONLY: SIGNAL|CONFIDENCE|REASONING|SUMMARY\nSIGNAL ∈ {BUY,SELL,WAIT}.\n\n";
   ctx += "PERF: Trades=" + IntegerToString(g_TotalTrades) + " WR=" + DoubleToString(wr,1) + "%\n";
   ctx += "MKT: Bid=" + DoubleToString(bid, g_Digits) + " RSI=" + DoubleToString(rsi,2)
        + " ATR=" + DoubleToString(atr, g_Digits) + " Trend=" + (maBull?"BULL":"BEAR")
        + " EMA200=" + (above200?"PRICE_ABOVE":"PRICE_BELOW")
        + " SpreadTier=" + g_SpreadTier + "\n";
   ctx += "Be willing to trade with moderate confidence. Bias on RSI extremes and trend alignment. Prefer trades in direction of EMA200.\n";
   return ctx;
}

string CallOpenAI(string data)
{
   if(StringLen(InpOpenAIAPIKey) < 20)
   {
      g_AIStatus = "SIMULATED";
      g_AIActive = false;
      return SimulatedAI();
   }
   string esc = EscapeJSON(data);
   string req = "{\"model\":\"" + InpOpenAIModel
              + "\",\"messages\":[{\"role\":\"user\",\"content\":\"" + esc + "\"}],\"temperature\":0.3}";
   string hdrs = "Content-Type: application/json\r\nAuthorization: Bearer " + InpOpenAIAPIKey + "\r\n";
   char post[], result[]; string rh;
   int len = StringLen(req);
   ArrayResize(post, len);
   StringToCharArray(req, post, 0, len);
   ResetLastError();
   int res = WebRequest("POST", "https://api.openai.com/v1/chat/completions", hdrs, 15000, post, result, rh);
   if(res != 200)
   {
      Print("WebRequest err res=", res, " err=", GetLastError());
      g_AIStatus = "ERROR"; g_AIActive = false;
      return SimulatedAI();
   }
   string content = ExtractContent(CharArrayToString(result));
   if(StringLen(content) > 0) { g_AIStatus = "ACTIVE"; g_AIActive = true; return content; }
   g_AIStatus = "ERROR"; g_AIActive = false;
   return SimulatedAI();
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

//═══════════════ SIMULATED AI ═══════════════
string SimulatedAI()
{
   if(g_AIStatus != "ERROR") g_AIStatus = "SIMULATED";
   double rsi = g_bRSI[0];
   double emaF = g_bEMAFast[0];
   double emaS = g_bEMASlow[0];

   if(rsi < 45 && emaF > emaS) return "BUY|0.55|RSI+trend bull|Long";
   if(rsi > 55 && emaF < emaS) return "SELL|0.55|RSI+trend bear|Short";
   if(rsi < 40) return "BUY|0.50|RSI oversold|Long";
   if(rsi > 60) return "SELL|0.50|RSI overbought|Short";
   return "WAIT|0.45|Neutral|No edge";
}

void ParseAI(string resp)
{
   string p[];
   int n = StringSplit(resp, '|', p);
   if(n >= 4)
   {
      g_AISignal = p[0]; StringTrimLeft(g_AISignal); StringTrimRight(g_AISignal);
      StringToUpper(g_AISignal);
      g_AIConfidence = StringToDouble(p[1]);
      g_AIReasoning = p[2];
      if(g_AISignal != "BUY" && g_AISignal != "SELL" && g_AISignal != "WAIT") g_AISignal = "WAIT";
      if(g_AIConfidence < 0) g_AIConfidence = 0;
      if(g_AIConfidence > 1) g_AIConfidence = 1;
   }
   else { g_AISignal = "WAIT"; g_AIConfidence = 0; g_AIReasoning = "Invalid"; }
}

//═══════════════ BREAK-EVEN & TRAILING ═══════════════
void ManageBreakEvenAndTrailing()
{
   if(!InpUseBreakEven && !InpUseTrailing) return;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double minStop = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * g_Point;
   if(minStop <= 0) minStop = 10 * g_Point;

   for(int i = PositionsTotal()-1; i >= 0; i--)
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
         double pipDist = (bid - entry) / g_Pip;
         if(InpUseBreakEven && pipDist >= InpBE_TriggerPips)
         {
            double be = NormalizeDouble(entry + InpBE_OffsetPips * g_Pip, g_Digits);
            if(be < bid - minStop && (curSL < be || curSL == 0)) g_Trade.PositionModify(t, be, curTP);
         }
         if(InpUseTrailing && pipDist >= InpTrailPips)
         {
            double ns = NormalizeDouble(bid - InpTrailPips * g_Pip, g_Digits);
            if(ns < bid - minStop && (curSL == 0 || ns > curSL + InpTrailStepPips * g_Pip))
               g_Trade.PositionModify(t, ns, curTP);
         }
      }
      else if(type == POSITION_TYPE_SELL)
      {
         double pipDist = (entry - ask) / g_Pip;
         if(InpUseBreakEven && pipDist >= InpBE_TriggerPips)
         {
            double be = NormalizeDouble(entry - InpBE_OffsetPips * g_Pip, g_Digits);
            if(be > ask + minStop && (curSL > be || curSL == 0)) g_Trade.PositionModify(t, be, curTP);
         }
         if(InpUseTrailing && pipDist >= InpTrailPips)
         {
            double ns = NormalizeDouble(ask + InpTrailPips * g_Pip, g_Digits);
            if(ns > ask + minStop && (curSL == 0 || ns < curSL - InpTrailStepPips * g_Pip))
               g_Trade.PositionModify(t, ns, curTP);
         }
      }
   }
}

//═══════════════ AUTO-CLOSE ═══════════════
void ManageAutoClose()
{
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
      string reason = ""; bool shouldClose = false;

      if(InpCloseOnOppositeAI && g_AIActive && g_AIConfidence >= InpAIConfidenceMin)
      {
         if(type == POSITION_TYPE_BUY && g_FinalSignal == "SELL") { shouldClose = true; reason = "AI flipped"; }
         if(type == POSITION_TYPE_SELL && g_FinalSignal == "BUY") { shouldClose = true; reason = "AI flipped"; }
      }
      if(InpCloseMaxAgeMin > 0 && (TimeCurrent() - openTime) > InpCloseMaxAgeMin * 60)
      { shouldClose = true; reason = "Age"; }

      if(shouldClose)
      {
         Print("AUTO-CLOSE #", t, ": ", reason);
         g_Trade.PositionClose(t);
      }
   }
}

//═══════════════ UI ═══════════════
void UpdateAllData()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double spread = (ask - bid) / g_Point;

   UpdateUI("BidPrice", DoubleToString(bid, g_Digits), ClrValue);
   UpdateUI("AskPrice", DoubleToString(ask, g_Digits), ClrValue);
   UpdateUI("Spread", DoubleToString(spread, 0) + " pts", g_SpreadTierColor);
   UpdateUI("SpreadTier", g_SpreadTier, g_SpreadTierColor);
   UpdateUI("SessionStatus", SessionName(), g_InSessionNow ? ClrBuy : ClrNeutral);

   double lots = CalculateLotSize(false);
   double spreadUSDperTrade = (double)g_CurrentSpread * 0.01 * (lots / 0.01);
   UpdateUI("SpreadCost", "$" + DoubleToString(spreadUSDperTrade, 2) + " @ " + DoubleToString(lots,2) + " lot", g_SpreadTierColor);
   UpdateUI("AdaptiveTP", DoubleToString(g_AdaptiveTP_Pips, 0) + " pips", ClrValue);
   UpdateUI("AdaptiveSL", DoubleToString(g_AdaptiveSL_Pips, 0) + " pips", ClrValue);
   UpdateUI("MinProfit", "$" + DoubleToString(spreadUSDperTrade * InpMinProfitSpreadRatio, 2) + " (" + DoubleToString(InpMinProfitSpreadRatio,1) + "x spread)", ClrWarning);

   if(CopyBuffer(g_hRSI,0,0,2,g_bRSI) < 2) return;
   if(CopyBuffer(g_hATR,0,0,2,g_bATR) < 2) return;
   if(CopyBuffer(g_hMAFast,0,0,2,g_bMAFast) < 2) return;
   if(CopyBuffer(g_hMASlow,0,0,2,g_bMASlow) < 2) return;
   if(CopyBuffer(g_hEMAFast,0,0,2,g_bEMAFast) < 2) return;
   if(CopyBuffer(g_hEMASlow,0,0,2,g_bEMASlow) < 2) return;
   if(CopyBuffer(g_hEMATrend,0,0,2,g_bEMATrend) < 2) return;

   double rsi = g_bRSI[0], atr = g_bATR[0];

   UpdateUI("RSI", DoubleToString(rsi, 1),
            (rsi < InpRSIBuyLevel) ? ClrBuy : (rsi > InpRSISellLevel) ? ClrSell : ClrValue);
   UpdateUI("ATR", DoubleToString(atr, g_Digits), ClrValue);
   UpdateUI("MAFast", DoubleToString(g_bMAFast[0], g_Digits), ClrValue);
   UpdateUI("MASlow", DoubleToString(g_bMASlow[0], g_Digits), ClrValue);
   UpdateUI("EMA200", DoubleToString(g_bEMATrend[0], g_Digits) + (bid > g_bEMATrend[0] ? "  ABOVE" : "  BELOW"),
            bid > g_bEMATrend[0] ? ClrBuy : ClrSell);

   string scoreBar = "B" + IntegerToString(g_AlgoBuyScore) + " / S" + IntegerToString(g_AlgoSellScore)
                   + "  need " + IntegerToString(g_AlgoMinScoreNeeded);
   color scoreClr = ClrNeutral;
   if(g_AlgoBuyScore >= g_AlgoMinScoreNeeded || g_AlgoSellScore >= g_AlgoMinScoreNeeded) scoreClr = ClrBuy;
   else if(g_AlgoBuyScore >= g_AlgoMinScoreNeeded - 1 || g_AlgoSellScore >= g_AlgoMinScoreNeeded - 1) scoreClr = ClrWarning;

   color cAI = (g_AISignal == "BUY") ? ClrBuy : (g_AISignal == "SELL") ? ClrSell : ClrWarning;
   UpdateUI("AISignal", g_AISignal, cAI);
   UpdateUI("AIConf", g_AIConfidence > 0 ? DoubleToString(g_AIConfidence*100,0)+"%" : "--",
            g_AIConfidence >= InpAIConfidenceMin ? ClrBuy : ClrWarning);
   UpdateUI("AIStatus", g_AIStatus, g_AIStatus == "ACTIVE" ? ClrBuy : ClrWarning);

   color cAlgo = (g_AlgoSignal == "BUY") ? ClrBuy : (g_AlgoSignal == "SELL") ? ClrSell : ClrWarning;
   UpdateUI("AlgoSignal", g_AlgoSignal, cAlgo);
   UpdateUI("AlgoConf", DoubleToString(g_AlgoConfidence*100, 0) + "%", ClrValue);
   UpdateUI("AlgoReason", g_AlgoReason, scoreClr);

   color cFin = (g_FinalSignal == "BUY") ? ClrBuy : (g_FinalSignal == "SELL") ? ClrSell : ClrNeutral;
   UpdateUI("FinalSignal", g_FinalSignal, cFin);
   UpdateUI("FinalReason", g_FinalReason, ClrValue);

   int op = CountOpen();
   string state = (op > 0) ? "OPEN (" + IntegerToString(op) + ")" : "FLAT";
   UpdateUI("TradeState", state, op > 0 ? ClrBuy : ClrNeutral);

   string pm = "OFF";
   color pmc = ClrNeutral;
   if(InpUseProfitScaling)
   {
      if(g_ProfitMode) { pm = "ACTIVE  streak " + IntegerToString(g_ConsecutiveWins); pmc = ClrBuy; }
      else { pm = "standby"; pmc = ClrWarning; }
   }
   UpdateUI("ProfitMode", pm, pmc);

   string posInfo = "--";
   if(op > 0)
   {
      double totalP = 0.0;
      for(int i = PositionsTotal()-1; i >= 0; i--)
      {
         ulong t = PositionGetTicket(i);
         if(t == 0) continue;
         if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
         if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
         totalP += PositionGetDouble(POSITION_PROFIT);
      }
      posInfo = "$" + DoubleToString(totalP,2) + " (" + IntegerToString(op) + " pos)";
   }
   UpdateUI("PosProfit", posInfo, op > 0 ? ClrBuy : ClrValue);

   string st = InpEnableTrading ? "ACTIVE" : "DISABLED";
   color stc = ClrBuy;
   if(g_Paused) { st = "PAUSED"; stc = ClrWarning; }
   if(g_DailyHit) { st = "DAILY LIMIT"; stc = ClrSell; }
   UpdateUI("TradingStatus", st, stc);
   UpdateUI("BlockReason", g_BlockReason, g_BlockColor);

   string waitText = "--";
   color waitClr = ClrNeutral;
   if(g_WaitSecondsRemaining > 0)
   {
      int mm = g_WaitSecondsRemaining / 60;
      int ss = g_WaitSecondsRemaining % 60;
      waitText = (mm > 0) ? StringFormat("%s %d:%02d", g_WaitCategory, mm, ss)
                          : StringFormat("%s %ds", g_WaitCategory, ss);
      waitClr = (g_WaitCategory == "COOLDOWN") ? ClrWarning :
                (g_WaitCategory == "LOSS-PAUSE") ? ClrSell :
                (g_WaitCategory == "SESSION") ? ClrNeutral : ClrWarning;
   }
   else
   {
      if(g_FinalSignal != "WAIT" || CountOpen() > 0) { waitText = "READY"; waitClr = ClrBuy; }
      else if(g_AlgoBuyScore >= g_AlgoMinScoreNeeded - 1 || g_AlgoSellScore >= g_AlgoMinScoreNeeded - 1)
      { waitText = "READY TO FIRE"; waitClr = ClrBuy; }
      else { waitText = "SIGNAL SEARCH"; waitClr = ClrNeutral; }
   }
   UpdateUI("WaitTime", waitText, waitClr);

   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   double pnl = eq - g_DayStartBalance;
   double pct = (g_DayStartBalance > 0) ? (pnl/g_DayStartBalance)*100.0 : 0.0;
   UpdateUI("DailyPnL", DoubleToString(pnl,2) + " (" + DoubleToString(pct,2) + "%)", pnl >= 0 ? ClrBuy : ClrSell);

   double wr = (g_TotalTrades > 0) ? ((double)g_Wins / g_TotalTrades) * 100.0 : 0.0;
   UpdateUI("Stats", IntegerToString(g_Wins) + "W/" + IntegerToString(g_Losses) + "L (" + DoubleToString(wr,0) + "%)", ClrValue);

   UpdateUI("Lot", DoubleToString(lots, 2) + " (×" + DoubleToString(g_AdaptiveLotMult,2) + ")", ClrValue);
}

void DrawDashboard()
{
   int x = InpXLeft, y0 = InpYTop;
   CreateRectangle("BG", x, y0, InpWidthLeft, InpPanelHeight, ClrBackground, CORNER_LEFT_UPPER);
   CreateTextLabel("Title", "GOLD PRO v5.4 — EMA200 + PROFIT MODE", x + 10, y0 + 5, ClrHeader, true, 10, CORNER_LEFT_UPPER);

   int y = y0 + 30;
   // STATUS
   CreateTextLabel("H1", "STATUS", x+10, y, ClrHeader, true, 9, CORNER_LEFT_UPPER); y += 18;
   CreateTextLabel("L1", "Trading:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_TradingStatus", "INIT", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L2", "Session:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_SessionStatus", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L3", "Positions:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_TradeState", "FLAT", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L4", "Pos P/L:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_PosProfit", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L5", "Lot size:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_Lot", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("LPM", "Profit Mode:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_ProfitMode", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("LW", "⏱ WAIT TIME:", x+10, y, ClrWarning, true, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_WaitTime", "--", x+130, y, ClrWarning, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L6", "Why:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_BlockReason", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 20;

   // SPREAD ADAPTIVE
   CreateTextLabel("HSP", "SPREAD ADAPTIVE", x+10, y, ClrHeader, true, 9, CORNER_LEFT_UPPER); y += 18;
   CreateTextLabel("LSP1", "Spread Tier:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_SpreadTier", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("LSP2", "Spread Cost:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_SpreadCost", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("LSP3", "TP:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_AdaptiveTP", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("LSP4", "SL:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_AdaptiveSL", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("LSP5", "Min Profit:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_MinProfit", "--", x+130, y, ClrWarning, true, 9, CORNER_LEFT_UPPER); y += 20;

   // DUAL ENGINE
   CreateTextLabel("H2", "DUAL ENGINE (EITHER)", x+10, y, ClrHeader, true, 9, CORNER_LEFT_UPPER); y += 18;
   CreateTextLabel("LA", "AI Signal:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_AISignal", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("LA2", "AI Conf:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_AIConf", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("LA3", "AI Status:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_AIStatus", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("LA4", "Algo Signal:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_AlgoSignal", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("LA5", "Algo Conf:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_AlgoConf", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("LA6", "Score:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_AlgoReason", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("LA7", ">>> FINAL:", x+10, y, ClrHeader, true, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_FinalSignal", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("LA8", "Final note:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_FinalReason", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 20;

   // MARKET
   CreateTextLabel("H3", "MARKET", x+10, y, ClrHeader, true, 9, CORNER_LEFT_UPPER); y += 18;
   CreateTextLabel("L7", "Bid:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_BidPrice", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L8", "Ask:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_AskPrice", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L9", "Spread:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_Spread", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L10", "RSI:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_RSI", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L11", "ATR:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_ATR", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L12", "MA Fast:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_MAFast", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L13", "MA Slow:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_MASlow", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L13b", "EMA 200:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_EMA200", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 20;

   // PERFORMANCE
   CreateTextLabel("H4", "PERFORMANCE", x+10, y, ClrHeader, true, 9, CORNER_LEFT_UPPER); y += 18;
   CreateTextLabel("L14", "Day P/L:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_DailyPnL", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 16;
   CreateTextLabel("L15", "Total:", x+10, y, ClrLabel, false, 9, CORNER_LEFT_UPPER);
   CreateTextLabel("V_Stats", "--", x+130, y, ClrValue, true, 9, CORNER_LEFT_UPPER); y += 22;

   CreateTextLabel("W1", "SL 40 / TP 60 | EMA 9-21-200", x+10, y, ClrWarning, false, 8, CORNER_LEFT_UPPER); y += 14;
   CreateTextLabel("W2", "In profit: small 0.01 trades stack", x+10, y, ClrWarning, false, 8, CORNER_LEFT_UPPER);
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