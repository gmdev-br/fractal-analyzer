//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "© GM, 2020, 2021, 2022, 2023"
#property description "Fractal Analyzer"

#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   2

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input string                  inputAtivo_1 = "PETR4";
input string                  inputAtivo_2 = "VALE3";
input string                  inputAtivo_3 = "SUZB3";
input string                  inputAtivo_4 = "RAIL3";
input int                     LevDP = 2;       // Fractal Period or Levels Demar Pint
input int                     BackStep = 0;  // Number of Steps Back
input int                     showBars = 10000; // Bars Back To Draw
input int                     ArrowCodeUp = 233;
input int                     ArrowCodeDown = 234;
input bool                    plotMarkers = true;
input color                   buyFractalColor = clrLime;
input color                   sellFractalColor = clrRed;
input int                     colorFactor = 160;
input int                     WaitMilliseconds = 10000;  // Timer (milliseconds) for recalculation
input bool                    enable1m = false;
input bool                    enable5m = false;
input bool                    enable15m = false;
input bool                    enable30m = false;
input bool                    enable60m = false;
input bool                    enable120m = false;
input bool                    enable240m = false;
input bool                    enableD = true;
input bool                    enableW = true;
input bool                    enableMN = true;
input int                     boxNumber = 3;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double temp1[], Buf1[], Fractal1[];
double temp2[], Buf2[], Fractal2[];
double precoAtual;

string ativos[];

string ativo_1, ativo_2, ativo_3, ativo_4;
int _showBars = showBars;
ENUM_TIMEFRAMES periodo;

int n_last = boxNumber;
int largura = 20;
int altura = 20;

int x = 5;
int y = 10;
int offset = 50;
int espaco_ativos = 30;
int linhas = 2;
int colunas = 3;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {

   ativo_1 = inputAtivo_1;
   StringToUpper(ativo_1);
   if (ativo_1 == "")
      ativo_1 = _Symbol;

   ativo_2 = inputAtivo_2;
   StringToUpper(ativo_2);
   if (ativo_2 == "")
      ativo_2 = NULL;

   ativo_3 = inputAtivo_3;
   StringToUpper(ativo_3);
   if (ativo_3 == "")
      ativo_3 = NULL;

   ativo_4 = inputAtivo_4;
   StringToUpper(ativo_4);
   if (ativo_4 == "")
      ativo_4 = NULL;

   ArrayResize(ativos, 4);

   ativos[0] = ativo_1;
   ativos[1] = ativo_2;
   ativos[2] = ativo_3;
   ativos[3] = ativo_4;
   
   int posicoes[4][2];

   for(int i = 0; i < colunas; i++) {
      for(int j = 0; j < linhas; j++) {

      }





   }
   SetText("label_" + ativo_1, ativo_1, offset, 0, clrWhite, 12, ativo_1);
   SetText("label_" + ativo_2, ativo_2, offset + (1 * (x + largura + espaco_ativos) * boxNumber), 0, clrWhite, 12, ativo_2);
   SetText("label_" + ativo_3, ativo_3, offset + (2 * (x + largura + espaco_ativos) * boxNumber), 0, clrWhite, 12, ativo_3);
   SetText("label_" + ativo_4, ativo_4, offset + (3 * (x + largura + espaco_ativos) * boxNumber), 0, clrWhite, 12, ativo_4);

   _updateTimer = new MillisecondTimer(WaitMilliseconds, false);

   SetIndexBuffer(0, Fractal1, INDICATOR_DATA);
   ArraySetAsSeries(Fractal1, true);

   SetIndexBuffer(1, Fractal2, INDICATOR_DATA);
   ArraySetAsSeries(Fractal2, true);

   SetIndexBuffer(2, Buf1, INDICATOR_CALCULATIONS);
   ArraySetAsSeries(Buf1, true);

   SetIndexBuffer(3, Buf2, INDICATOR_CALCULATIONS);
   ArraySetAsSeries(Buf2, true);

   SetIndexBuffer(4, temp1, INDICATOR_CALCULATIONS);
   ArraySetAsSeries(temp1, true);

   SetIndexBuffer(5, temp2, INDICATOR_CALCULATIONS);
   ArraySetAsSeries(temp2, true);

   if (plotMarkers) {
      PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_ARROW);
      PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_ARROW);
   } else {
      PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_NONE);
      PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_NONE);
   }

   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);

   PlotIndexSetInteger(0, PLOT_LINE_COLOR, sellFractalColor);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, buyFractalColor);

   PlotIndexSetInteger(0, PLOT_ARROW, ArrowCodeDown);
   PlotIndexSetInteger(1, PLOT_ARROW, ArrowCodeUp);

   EventSetMillisecondTimer(WaitMilliseconds);

   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int  reason) {

   delete(_updateTimer);
   ObjectsDeleteAll(0, "label_");
   ChartRedraw();

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Update(string p_ativo, ENUM_TIMEFRAMES p_tf, int row, int n_ativo) {


   long totalRates = SeriesInfoInteger(p_ativo, p_tf, SERIES_BARS_COUNT);
   double onetick = SymbolInfoDouble(p_ativo, SYMBOL_TRADE_TICK_VALUE);

   ArrayInitialize(temp1, 0.0);
   ArrayInitialize(temp2, 0.0);
   ArrayInitialize(Buf1, 0.0);
   ArrayInitialize(Buf2, 0.0);
   ArrayInitialize(Fractal1, 0.0);
   ArrayInitialize(Fractal2, 0.0);

//ArrayResize(Buf1, totalRates);

   string tipo[];

   precoAtual = iClose(p_ativo, PERIOD_CURRENT, 0);

   static datetime prevTime = 0;
//if(prevTime != iTime(_Symbol, PERIOD_CURRENT, 0)) { // New Bar
   int cnt = 0;
   if(_showBars == 0 || _showBars > totalRates - 1)
      _showBars = totalRates - 1;

   for(cnt = _showBars; cnt > LevDP; cnt--) {
      temp1[cnt] = DemHigh(p_ativo, cnt, LevDP, p_tf);
      temp2[cnt] = DemLow(p_ativo, cnt, LevDP, p_tf);
      Fractal1[cnt] = DemHigh(NULL, cnt, LevDP, PERIOD_CURRENT);
      Fractal2[cnt] = DemLow(NULL, cnt, LevDP, PERIOD_CURRENT);
      Buf1[cnt] =  temp1[cnt];
      Buf2[cnt] =  temp2[cnt];
   }

   int count = 0;

   ArrayResize(tipo, n_last);

//SetPanel("label_" + GetTimeFrame(p_tf), 0, x, y, largura * 2, altura - 3, clrNONE, clrWhite, 1);
//ObjectSetString(0, "label_" + GetTimeFrame(p_tf), OBJPROP_TEXT, GetTimeFrame(p_tf) );

   if (n_ativo == 1)
      SetText("label_" + GetTimeFrame(p_tf), GetTimeFrame(p_tf), x, (row * altura / 10) * y, clrWhite, 12, GetTimeFrame(p_tf));

   for(int i = 0; i < ArraySize(Buf1) - 1; i++) {
      if (count == n_last)
         break;

      int start_x = offset + ((n_ativo) * (x + largura + espaco_ativos) * boxNumber);
      start_x = offset + (x + largura) * boxNumber;
      int end_x = offset + ((n_ativo) * (x + largura + espaco_ativos) * boxNumber);

      if (Buf1[i] > 0 && !Buf2[i] > 0) {
         tipo[count] = "bearish";
         string name = "label_" + p_ativo +  "_" + GetTimeFrame(p_tf) + "_" + i;
         SetPanel(name, 0, end_x - (x + largura) * count, (row * altura / 10) * y, largura, altura - 1, clrRed, clrBlack, 1);
         Print(tipo[count]);
         count++;
      } else if (Buf2[i] > 0 && !Buf1[i] > 0) {
         tipo[count] = "bullish";
         string name = "label_" + p_ativo +  "_" + GetTimeFrame(p_tf) + "_" + i;
         SetPanel(name, 0, end_x - (x + largura) * count, (row * altura / 10) * y, largura, altura - 1, clrLime, clrBlack, 1);
         Print(tipo[count]);
         count++;
      }

   }

//prevTime = iTime(_Symbol, PERIOD_CURRENT, 0);
//}
   ChartRedraw();

   return true;
}

//+------------------------------------------------------------------+
//| Draw a Panel1with given color for a symbol                       |
//+------------------------------------------------------------------+
void SetPanel(string name, int sub_window, int x, int y, int width, int height, color bg_color, color border_clr, int border_width) {
   if(ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, sub_window, 0, 0)) {
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
      ObjectSetInteger(0, name, OBJPROP_COLOR, border_clr);
      ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      //ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, neutralColor);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, border_width);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, 0);
      ObjectSetInteger(0, name, OBJPROP_SELECTED, 0);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
   }
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg_color);
}

//+------------------------------------------------------------------+
//| Draw data about a symbol in a Panel1                             |
//+------------------------------------------------------------------+
void SetText(string name, string text, int x, int y, color colour, int fontsize = 12, string tooltip = "\n") {
   if(ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0)) {
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_COLOR, colour);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontsize);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetString(0, name, OBJPROP_TOOLTIP, tooltip);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
   }
   ObjectSetString(0, name, OBJPROP_TEXT, text);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[]) {
   return (1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   CheckTimer();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckTimer() {
   EventKillTimer();

   if(_updateTimer.Check() || !_lastOK) {
      int number = 0;
      if (enable1m) {
         number++;
         for(int i = 0; i < ArraySize(ativos); i++) {
            Update(ativos[i], PERIOD_M5, number, i);
         }
      }
      if (enable5m) {
         number++;
         Update(ativo_1, PERIOD_M5, number, 1);
      }
      if (enable15m) {
         number++;
         Update(ativo_1, PERIOD_M15, number, 1);
      }
      if (enable30m) {
         number++;
         Update(ativo_1, PERIOD_M30, number, 1);
      }
      if (enable60m) {
         number++;
         Update(ativo_1, PERIOD_H1, number, 1);
      }
      if (enable120m) {
         number++;
         Update(ativo_1, PERIOD_H2, number, 1);
      }
      if (enable240m) {
         number++;
         Update(ativo_1, PERIOD_H4, number, 1);
      }
      if (enableD) {
         number++;
         //for(int i = 0; i < ArraySize(ativos); i++) {
         //    Update(ativos[i], PERIOD_D1, number, i);
         // }
      }
      if (enableW) {
         number++;
         //for(int i = 0; i < ArraySize(ativos); i++) {
         //   Update(ativos[i], PERIOD_W1, number, i);
         //}
      }
      if (enableMN) {
         number++;
         //for(int i = 0; i < ArraySize(ativos); i++) {
         //   Update(ativos[i], PERIOD_MN1, number, i);
         //}
         Update(ativo_1, PERIOD_MN1, number, 1);
      }

      _lastOK = true;
      bool debug = true;
      if (debug) Print("Fractal Analyzer " + " " + _Symbol + ":" + GetTimeFrame(Period()) + " ok");

      EventSetMillisecondTimer(WaitMilliseconds);

      _updateTimer.Reset();
   } else {
      EventSetTimer(1);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double DemHigh(string p_ativo, int cnt, int sh, ENUM_TIMEFRAMES periodo) {
   if(iHigh(p_ativo, periodo, cnt) >= iHigh(p_ativo, periodo, cnt + sh) && iHigh(p_ativo, periodo, cnt) > iHigh(p_ativo, periodo, cnt - sh)) {
      if(sh > 1)
         return(DemHigh(p_ativo, cnt, sh - 1, periodo));
      else
         return(iHigh(p_ativo, periodo, cnt));
   } else
      return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double DemLow(string p_ativo, int cnt, int sh, ENUM_TIMEFRAMES periodo) {
   if(iLow(p_ativo, periodo, cnt) <= iLow(p_ativo, periodo, cnt + sh) && iLow(p_ativo, periodo, cnt) < iLow(p_ativo, periodo, cnt - sh)) {
      if(sh > 1)
         return(DemLow(p_ativo, cnt, sh - 1, periodo));
      else
         return(iLow(p_ativo, periodo, cnt));
   } else
      return(0);
}

//+------------------------------------------------------------------+

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {

   if(id == CHARTEVENT_CHART_CHANGE) {
      _lastOK = false;
      CheckTimer();
      return;
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MillisecondTimer {

 private:
   int               _milliseconds;
 private:
   uint              _lastTick;

 public:
   void              MillisecondTimer(const int milliseconds, const bool reset = true) {
      _milliseconds = milliseconds;

      if(reset)
         Reset();
      else
         _lastTick = 0;
   }

 public:
   bool              Check() {
      uint now = getCurrentTick();
      bool stop = now >= _lastTick + _milliseconds;

      if(stop)
         _lastTick = now;

      return(stop);
   }

 public:
   void              Reset() {
      _lastTick = getCurrentTick();
   }

 private:
   uint              getCurrentTick() const {
      return(GetTickCount());
   }

};

//+---------------------------------------------------------------------+
//| GetTimeFrame function - returns the textual timeframe               |
//+---------------------------------------------------------------------+
string GetTimeFrame(int lPeriod) {
   switch(lPeriod) {
   case PERIOD_M1:
      return("M1");
   case PERIOD_M2:
      return("M2");
   case PERIOD_M3:
      return("M3");
   case PERIOD_M4:
      return("M4");
   case PERIOD_M5:
      return("M5");
   case PERIOD_M6:
      return("M6");
   case PERIOD_M10:
      return("M10");
   case PERIOD_M12:
      return("M12");
   case PERIOD_M15:
      return("M15");
   case PERIOD_M20:
      return("M20");
   case PERIOD_M30:
      return("M30");
   case PERIOD_H1:
      return("H1");
   case PERIOD_H2:
      return("H2");
   case PERIOD_H3:
      return("H3");
   case PERIOD_H4:
      return("H4");
   case PERIOD_H6:
      return("H6");
   case PERIOD_H8:
      return("H8");
   case PERIOD_H12:
      return("H12");
   case PERIOD_D1:
      return("D1");
   case PERIOD_W1:
      return("W1");
   case PERIOD_MN1:
      return("MN1");
   }
   return IntegerToString(lPeriod);
}

bool _lastOK = false;
MillisecondTimer *_updateTimer;
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
