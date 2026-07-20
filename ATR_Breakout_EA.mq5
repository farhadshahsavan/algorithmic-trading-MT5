//+------------------------------------------------------------------+
//|                                            ATR_Breakout_EA.mq5   |
//|                                                                  |
//|  Portfolio example Expert Advisor demonstrating:                 |
//|    - Multi-timeframe price analysis                              |
//|    - Volatility-adaptive risk management (ATR-based)             |
//|    - Systematic entry/exit logic with confluence filters         |
//|    - Position sizing normalised by stop-loss distance            |
//|    - Trailing stop management                                    |
//|                                                                  |
//|  Strategy: Donchian channel breakout with ATR-based stop loss    |
//|            and trend filter based on EMA slope.                  |
//|            Public, well-known technique.                         |
//|                                                                  |
//|  Author: Dr. Farhad Shahsavan                                    |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
CTrade trade;

//--- input parameters
input int      breakout_period      = 20;      // Donchian channel length (bars)
input int      trend_ema_period     = 50;      // EMA for trend filter
input int      atr_period           = 14;      // ATR length for volatility
input double   atr_sl_multiplier    = 2.0;     // Stop loss = ATR * this factor
input double   atr_tp_multiplier    = 4.0;     // Take profit = ATR * this factor
input double   risk_per_trade_pct   = 1.0;     // Risk per trade as % of balance
input double   min_lots             = 0.01;    // Minimum lot size
input double   max_lots             = 10.0;    // Maximum lot size
input int      Start_time_hour      = 8;
input int      End_time_hour        = 20;
input int      max_open_position    = 3;
input bool     use_trailing_stop    = true;
input double   trailing_start_atr   = 1.5;     // Start trailing after price moves this * ATR
input double   trailing_step_atr    = 0.5;     // Trail by this * ATR

//----handler----
int handler_ATR;
int handler_EMA_trend;

//-----bars
int total_bars;
int total_bars_1M;

//----- state variables
double last_signal_high;
double last_signal_low;
int    last_trade_bar_index;

//+------------------------------------------------------------------+
//| Position sizing based on stop-loss distance and account risk     |
//+------------------------------------------------------------------+
double calculate_lot_size (double stop_loss_pips)
   {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double risk_money = balance * (risk_per_trade_pct / 100.0);
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double pip_value = tick_value * (_Point / tick_size);
   double lots = 0;
   if (stop_loss_pips > 0 && pip_value > 0)
      {lots = risk_money / (stop_loss_pips * pip_value);}
   lots = NormalizeDouble(lots, 2);
   lots = fmax(lots, min_lots);
   lots = fmin(lots, max_lots);
   return lots;
   }

//+------------------------------------------------------------------+
//| Buy position with ATR-based SL and TP                            |
//+------------------------------------------------------------------+
bool Buy_position (double atr_value)
   {
   bool position = false;
   double entry_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   entry_price = NormalizeDouble(entry_price, _Digits);
   double stop_loss_price = entry_price - (atr_sl_multiplier * atr_value);
   double take_profit_price = entry_price + (atr_tp_multiplier * atr_value);
   stop_loss_price = NormalizeDouble(stop_loss_price, _Digits);
   take_profit_price = NormalizeDouble(take_profit_price, _Digits);
   double sl_pips = (entry_price - stop_loss_price) / _Point;
   double lots = calculate_lot_size(sl_pips);
   Print("BUY setup: entry=", entry_price, " SL=", stop_loss_price, " TP=", take_profit_price, " lots=", lots);
   close_all_sell_position();
   position = trade.Buy(lots, NULL, entry_price, stop_loss_price, take_profit_price, "ATR_breakout_buy");
   return position;
   }

//+------------------------------------------------------------------+
//| Sell position with ATR-based SL and TP                           |
//+------------------------------------------------------------------+
bool Sell_position (double atr_value)
   {
   bool position = false;
   double entry_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   entry_price = NormalizeDouble(entry_price, _Digits);
   double stop_loss_price = entry_price + (atr_sl_multiplier * atr_value);
   double take_profit_price = entry_price - (atr_tp_multiplier * atr_value);
   stop_loss_price = NormalizeDouble(stop_loss_price, _Digits);
   take_profit_price = NormalizeDouble(take_profit_price, _Digits);
   double sl_pips = (stop_loss_price - entry_price) / _Point;
   double lots = calculate_lot_size(sl_pips);
   Print("SELL setup: entry=", entry_price, " SL=", stop_loss_price, " TP=", take_profit_price, " lots=", lots);
   close_all_buy_position();
   position = trade.Sell(lots, NULL, entry_price, stop_loss_price, take_profit_price, "ATR_breakout_sell");
   return position;
   }

//+------------------------------------------------------------------+
//| Donchian channel high finder                                     |
//+------------------------------------------------------------------+
double donchian_high (int period)
   {
   int highest_bar = iHighest(NULL, NULL, MODE_HIGH, period, 1);
   double dh = iHigh(NULL, NULL, highest_bar);
   return dh;
   }

//+------------------------------------------------------------------+
//| Donchian channel low finder                                      |
//+------------------------------------------------------------------+
double donchian_low (int period)
   {
   int lowest_bar = iLowest(NULL, NULL, MODE_LOW, period, 1);
   double dl = iLow(NULL, NULL, lowest_bar);
   return dl;
   }

//+------------------------------------------------------------------+
//| EMA-slope-based trend filter (buy = uptrend, sell = downtrend)   |
//+------------------------------------------------------------------+
int trend_direction ()
   {
   double ema[];
   CopyBuffer(handler_EMA_trend, 0, 1, 5, ema);
   ArrayReverse(ema);
   int trend = 0;
   if (ema[0] > ema[4])
      {trend = 1;}
   else if (ema[0] < ema[4])
      {trend = -1;}
   return trend;
   }

//+------------------------------------------------------------------+
//| Breakout detection on last closed bar                            |
//+------------------------------------------------------------------+
bool breakout_buy_detected (double donchian_h)
   {
   bool detected = false;
   double last_close = iClose(NULL, NULL, 1);
   double last_high = iHigh(NULL, NULL, 1);
   if ((last_close > donchian_h) && (last_high > donchian_h))
      {detected = true;}
   return detected;
   }

bool breakout_sell_detected (double donchian_l)
   {
   bool detected = false;
   double last_close = iClose(NULL, NULL, 1);
   double last_low = iLow(NULL, NULL, 1);
   if ((last_close < donchian_l) && (last_low < donchian_l))
      {detected = true;}
   return detected;
   }

//+------------------------------------------------------------------+
//| Trailing stop management for open positions                      |
//+------------------------------------------------------------------+
void trailing_stop_update (double atr_value)
   {
   double trail_distance = trailing_step_atr * atr_value;
   double activation = trailing_start_atr * atr_value;
   for (int i = PositionsTotal() - 1; i >= 0; --i)
      {
      ulong pos_ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(pos_ticket))
         {
         if (PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
            double entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
            double current_sl = PositionGetDouble(POSITION_SL);
            double current_tp = PositionGetDouble(POSITION_TP);
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
               {
               double bid_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
               double profit_distance = bid_price - entry_price;
               if (profit_distance > activation)
                  {
                  double new_sl = bid_price - trail_distance;
                  new_sl = NormalizeDouble(new_sl, _Digits);
                  if (new_sl > current_sl)
                     {trade.PositionModify(pos_ticket, new_sl, current_tp);}
                  }
               }
            else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
               {
               double ask_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
               double profit_distance = entry_price - ask_price;
               if (profit_distance > activation)
                  {
                  double new_sl = ask_price + trail_distance;
                  new_sl = NormalizeDouble(new_sl, _Digits);
                  if (new_sl < current_sl || current_sl == 0)
                     {trade.PositionModify(pos_ticket, new_sl, current_tp);}
                  }
               }
            }
         }
      }
   }

//+------------------------------------------------------------------+
//| Position counting helpers                                        |
//+------------------------------------------------------------------+
int count_open_positions ()
   {
   int count = 0;
   for (int i = PositionsTotal() - 1; i >= 0; --i)
      {
      ulong pos_ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(pos_ticket))
         {
         if (PositionGetString(POSITION_SYMBOL) == _Symbol)
            {++count;}
         }
      }
   return count;
   }

void close_all_buy_position ()
   {
   for (int i = PositionsTotal() - 1; i >= 0; --i)
      {
      ulong pos_ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(pos_ticket))
         {
         if (PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
               {trade.PositionClose(pos_ticket);}
            }
         }
      }
   }

void close_all_sell_position ()
   {
   for (int i = PositionsTotal() - 1; i >= 0; --i)
      {
      ulong pos_ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(pos_ticket))
         {
         if (PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
               {trade.PositionClose(pos_ticket);}
            }
         }
      }
   }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  //-----handler
   handler_ATR = iATR(NULL, NULL, atr_period);
   handler_EMA_trend = iMA(NULL, NULL, trend_ema_period, 0, MODE_EMA, PRICE_CLOSE);
   //------
   total_bars = iBars(NULL, NULL);
   total_bars_1M = iBars(NULL, PERIOD_M1);
   last_signal_high = 0;
   last_signal_low = 0;
   last_trade_bar_index = 0;
//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print("EA deinitialized");
   IndicatorRelease(handler_ATR);
   IndicatorRelease(handler_EMA_trend);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   datetime date1 = TimeGMT();
   MqlDateTime str1;
   TimeToStruct(date1, str1);
   bool istime = str1.hour >= Start_time_hour && str1.hour <= End_time_hour;
   int actual_bars = iBars(NULL, NULL);
   int actual_bars_1M = iBars(NULL, PERIOD_M1);

   //--- update trailing stops on every minute bar
   if (actual_bars_1M != total_bars_1M)
      {
      if (use_trailing_stop && count_open_positions() > 0)
         {
         double atr_val[];
         CopyBuffer(handler_ATR, 0, 1, 1, atr_val);
         trailing_stop_update(atr_val[0]);
         }
      total_bars_1M = actual_bars_1M;
      }

   //--- run signal logic once per new bar on entry timeframe
   if (actual_bars != total_bars)
      {
      total_bars = actual_bars;
      if (!istime)
         {return;}
      if (count_open_positions() >= max_open_position)
         {return;}
      double atr_val[];
      CopyBuffer(handler_ATR, 0, 1, 1, atr_val);
      double current_atr = atr_val[0];
      double dh = donchian_high(breakout_period);
      double dl = donchian_low(breakout_period);
      int trend = trend_direction();

      //--- long setup: uptrend + upside breakout
      if ((trend == 1) && breakout_buy_detected(dh))
         {
         if (last_signal_high != dh)
            {
            Buy_position(current_atr);
            last_signal_high = dh;
            last_trade_bar_index = actual_bars;
            }
         }

      //--- short setup: downtrend + downside breakout
      if ((trend == -1) && breakout_sell_detected(dl))
         {
         if (last_signal_low != dl)
            {
            Sell_position(current_atr);
            last_signal_low = dl;
            last_trade_bar_index = actual_bars;
            }
         }
      }
  }
//+------------------------------------------------------------------+
