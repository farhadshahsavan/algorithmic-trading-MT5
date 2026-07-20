//+------------------------------------------------------------------+
//|                                     SwingPoint_Finder.mqh        |
//|                                                                  |
//|  Utility functions for detecting swing peaks and swing bottoms   |
//|  in Heikin-Ashi price sequences.                                 |
//|                                                                  |
//|  A "swing peak" is detected as the transition into two           |
//|  consecutive bearish (red) Heikin-Ashi candles, indicating a     |
//|  local reversal from an up-move.                                 |
//|                                                                  |
//|  A "swing bottom" is detected as the transition into two         |
//|  consecutive bullish (green) Heikin-Ashi candles.                |
//|                                                                  |
//|  These are common building blocks for market structure analysis  |
//|  and price-action strategies.                                    |
//|                                                                  |
//|  Usage:                                                          |
//|     int peak_bar  = peak_finder_Heiken_Ashi(50, ha_open, ha_close);  |
//|     int bottom_bar = bottom_finder_Heiken_Ashi(50, ha_open, ha_close); |
//|                                                                  |
//|  Author: Dr. Farhad Shahsavan                                    |
//+------------------------------------------------------------------+
#ifndef SWINGPOINT_FINDER_MQH
#define SWINGPOINT_FINDER_MQH

//+------------------------------------------------------------------+
//| Find the most recent swing peak in Heikin-Ashi data.             |
//|                                                                  |
//|   von          : starting bar (looking backwards from this)      |
//|   heiken_open  : Heikin-Ashi open array                          |
//|   heiken_close : Heikin-Ashi close array                         |
//|                                                                  |
//|   returns : bar index of the peak (0 if none found)              |
//+------------------------------------------------------------------+
int peak_finder_Heiken_Ashi (int von, double &heiken_open[], double &heiken_close[])
   {
   int len_Heiken = ArraySize(heiken_open);
   bool find = false;
   int place = 0;
   int i = von;
   while (i > 1 && !find)
      {
      if ((heiken_close[len_Heiken - i] < heiken_open[len_Heiken - i])
          && (heiken_close[len_Heiken - i + 1] < heiken_open[len_Heiken - i + 1]))
         {
         find = true;
         place = i;
         }
      --i;
      }
   return place;
   }

//+------------------------------------------------------------------+
//| Find the most recent swing bottom in Heikin-Ashi data.           |
//|                                                                  |
//|   von          : starting bar (looking backwards from this)      |
//|   heiken_open  : Heikin-Ashi open array                          |
//|   heiken_close : Heikin-Ashi close array                         |
//|                                                                  |
//|   returns : bar index of the bottom (0 if none found)            |
//+------------------------------------------------------------------+
int bottom_finder_Heiken_Ashi (int von, double &heiken_open[], double &heiken_close[])
   {
   int len_Heiken = ArraySize(heiken_open);
   bool find = false;
   int place = 0;
   int i = von;
   while (i > 1 && !find)
      {
      if ((heiken_close[len_Heiken - i] > heiken_open[len_Heiken - i])
          && (heiken_close[len_Heiken - i + 1] > heiken_open[len_Heiken - i + 1]))
         {
         find = true;
         place = i;
         }
      --i;
      }
   return place;
   }

//+------------------------------------------------------------------+
//| Stricter variant: require three consecutive red HA candles.      |
//|                                                                  |
//|   Reduces false signals in choppy markets by demanding stronger  |
//|   confirmation of the reversal.                                  |
//+------------------------------------------------------------------+
int three_peak_finder_Heiken_Ashi (int von, double &heiken_open[], double &heiken_close[])
   {
   int len_Heiken = ArraySize(heiken_open);
   bool find = false;
   int place = 0;
   int i = von;
   while (i > 2 && !find)
      {
      if ((heiken_close[len_Heiken - i] < heiken_open[len_Heiken - i])
          && (heiken_close[len_Heiken - i + 1] < heiken_open[len_Heiken - i + 1])
          && (heiken_close[len_Heiken - i + 2] < heiken_open[len_Heiken - i + 2]))
         {
         find = true;
         place = i;
         }
      --i;
      }
   return place;
   }

//+------------------------------------------------------------------+
//| Stricter variant: require three consecutive green HA candles.    |
//+------------------------------------------------------------------+
int three_bottom_finder_Heiken_Ashi (int von, double &heiken_open[], double &heiken_close[])
   {
   int len_Heiken = ArraySize(heiken_open);
   bool find = false;
   int place = 0;
   int i = von;
   while (i > 2 && !find)
      {
      if ((heiken_close[len_Heiken - i] > heiken_open[len_Heiken - i])
          && (heiken_close[len_Heiken - i + 1] > heiken_open[len_Heiken - i + 1])
          && (heiken_close[len_Heiken - i + 2] > heiken_open[len_Heiken - i + 2]))
         {
         find = true;
         place = i;
         }
      --i;
      }
   return place;
   }

#endif   // SWINGPOINT_FINDER_MQH
//+------------------------------------------------------------------+
