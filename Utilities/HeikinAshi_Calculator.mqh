//+------------------------------------------------------------------+
//|                                     HeikinAshi_Calculator.mqh    |
//|                                                                  |
//|  Standalone Heikin-Ashi calculator for MQL5.                     |
//|                                                                  |
//|  Heikin-Ashi is a modified candle representation that smooths    |
//|  price action and highlights trends. It is calculated from the   |
//|  standard OHLC data using recursive relations:                   |
//|                                                                  |
//|     HA_Close = (Open + High + Low + Close) / 4                   |
//|     HA_Open  = (HA_Open[prev] + HA_Close[prev]) / 2              |
//|     HA_High  = max(High, HA_Open, HA_Close)                      |
//|     HA_Low   = min(Low,  HA_Open, HA_Close)                      |
//|                                                                  |
//|  Because HA_Open depends on the previous HA candle, the          |
//|  calculation must be performed iteratively from an initialisation|
//|  point forward to the present.                                   |
//|                                                                  |
//|  Usage:                                                          |
//|     double ha_open[], ha_close[];                                |
//|     Heiken_ashi_calculator_for_start(PERIOD_H4, 2000,            |
//|                                       ha_open, ha_close);        |
//|                                                                  |
//|  Author: Dr. Farhad Shahsavan                                    |
//+------------------------------------------------------------------+
#ifndef HEIKINASHI_CALCULATOR_MQH
#define HEIKINASHI_CALCULATOR_MQH

//+------------------------------------------------------------------+
//| Compute Heikin-Ashi open and close arrays from a starting bar.   |
//|                                                                  |
//|   time_period    : timeframe to compute on (PERIOD_H4 etc.)      |
//|   NO_last_candle : starting bar index (looking back from index 0)|
//|                    Calculation runs from this index towards 0.   |
//|   H_A_open       : output array of HA open values                |
//|   H_A_close      : output array of HA close values               |
//+------------------------------------------------------------------+
void Heiken_ashi_calculator_for_start (ENUM_TIMEFRAMES time_period,
                                        int NO_last_candle,
                                        double &H_A_open[],
                                        double &H_A_close[])
   {
   double H_A_O[3000] = {0};
   double H_A_C[3000] = {0};
   for (int i = NO_last_candle; i > 0; --i)
      {
      if (i == NO_last_candle)
         {
         //--- seed the recursion with the standard close/open average
         H_A_C[i] = NormalizeDouble(((iClose(NULL, time_period, i)
                                       + iOpen(NULL, time_period, i)
                                       + iHigh(NULL, time_period, i)
                                       + iLow(NULL, time_period, i)) / 4), _Digits);
         H_A_O[i] = NormalizeDouble(((iClose(NULL, time_period, i)
                                       + iOpen(NULL, time_period, i)) / 2), _Digits);
         }
      else
         {
         //--- HA_Open is the average of previous HA candle's open and close
         H_A_C[i] = NormalizeDouble(((iClose(NULL, time_period, i)
                                       + iOpen(NULL, time_period, i)
                                       + iHigh(NULL, time_period, i)
                                       + iLow(NULL, time_period, i)) / 4), _Digits);
         H_A_O[i] = NormalizeDouble(((H_A_C[i + 1] + H_A_O[i + 1]) / 2), _Digits);
         }
      }
   ArrayCopy(H_A_close, H_A_C, 0, 0, NO_last_candle + 1);
   ArrayCopy(H_A_open, H_A_O, 0, 0, NO_last_candle + 1);
   }

//+------------------------------------------------------------------+
//| Return true if the candle at 'place' is bullish (green HA)       |
//+------------------------------------------------------------------+
bool ha_candle_is_green (int place, double &H_A_open[], double &H_A_close[])
   {
   bool status = false;
   int len_HA = ArraySize(H_A_open);
   if (place < len_HA)
      {
      if (H_A_close[place] > H_A_open[place])
         {status = true;}
      }
   return status;
   }

//+------------------------------------------------------------------+
//| Return true if the candle at 'place' is bearish (red HA)         |
//+------------------------------------------------------------------+
bool ha_candle_is_red (int place, double &H_A_open[], double &H_A_close[])
   {
   bool status = false;
   int len_HA = ArraySize(H_A_open);
   if (place < len_HA)
      {
      if (H_A_close[place] < H_A_open[place])
         {status = true;}
      }
   return status;
   }

#endif   // HEIKINASHI_CALCULATOR_MQH
//+------------------------------------------------------------------+
