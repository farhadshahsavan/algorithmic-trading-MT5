//+------------------------------------------------------------------+
//|                                     RiskManagement.mqh           |
//|                                                                  |
//|  Position-sizing and risk-management utilities for MQL5.         |
//|                                                                  |
//|  Two main approaches implemented:                                |
//|    1. Fixed-lot with stop-loss-distance normalisation.           |
//|       Larger stop -> smaller lots, keeping risk consistent.      |
//|    2. Percentage-of-balance risk with pip-value calculation.     |
//|       Directly targets a defined % of account per trade.         |
//|                                                                  |
//|  A minimum stop-loss floor protects against overleveraging       |
//|  during periods of exceptionally low volatility.                 |
//|                                                                  |
//|  Author: Dr. Farhad Shahsavan                                    |
//+------------------------------------------------------------------+
#ifndef RISK_MANAGEMENT_MQH
#define RISK_MANAGEMENT_MQH

//+------------------------------------------------------------------+
//| Fixed-lot approach with stop-loss-distance normalisation.        |
//|                                                                  |
//|  The reference lot size (base_lot) is defined for a "reference"  |
//|  stop-loss distance (norm_lot pips). The actual lot size is      |
//|  then scaled inversely to the actual stop-loss distance, keeping |
//|  monetary risk approximately constant across setups.             |
//|                                                                  |
//|   entry_price     : trade entry price                            |
//|   stop_loss_price : stop-loss price                              |
//|   base_lot        : reference lot size                           |
//|   norm_lot        : reference SL distance in pips                |
//|   minimum_SL      : minimum SL distance in pips (floor)          |
//|   stop_loss_extra : additional buffer to add to SL in pips       |
//|                                                                  |
//|   returns : normalised lot size (rounded to 0.01)                |
//+------------------------------------------------------------------+
double normalised_lots_from_SL (double entry_price,
                                 double stop_loss_price,
                                 double base_lot,
                                 int norm_lot,
                                 int minimum_SL,
                                 int stop_loss_extra)
   {
   entry_price = NormalizeDouble(entry_price, _Digits);
   stop_loss_price = NormalizeDouble(stop_loss_price, _Digits);
   double stop_loss_distance = MathAbs(entry_price - stop_loss_price);
   double stop_loss_pips = stop_loss_distance / _Point + stop_loss_extra;
   stop_loss_pips = fmax(stop_loss_pips, minimum_SL);
   double factor_lots = stop_loss_pips / norm_lot;
   double lots = NormalizeDouble(base_lot / factor_lots, 2);
   return lots;
   }

//+------------------------------------------------------------------+
//| Percentage-of-balance risk sizing.                               |
//|                                                                  |
//|  Sizes the trade so that if the stop-loss hits, the account      |
//|  loses exactly risk_pct % of its current balance.                |
//|                                                                  |
//|   stop_loss_pips : stop-loss distance in pips                    |
//|   risk_pct       : % of account balance to risk (e.g. 1.0)       |
//|   min_lots       : lower clamp for lot size                      |
//|   max_lots       : upper clamp for lot size                      |
//+------------------------------------------------------------------+
double percentage_risk_lots (double stop_loss_pips,
                              double risk_pct,
                              double min_lots,
                              double max_lots)
   {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double risk_money = balance * (risk_pct / 100.0);
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
//| Reward-to-risk ratio check.                                      |
//|                                                                  |
//|  Common filter that rejects trades whose potential reward is     |
//|  smaller than a chosen multiple of the risk.                     |
//|                                                                  |
//|   entry_price       : trade entry price                          |
//|   stop_loss_price   : SL price                                   |
//|   take_profit_price : TP price                                   |
//|   required_ratio    : minimum reward-to-risk (e.g. 1.5)          |
//|                                                                  |
//|   returns : true if reward/risk >= required_ratio                |
//+------------------------------------------------------------------+
bool reward_risk_passes (double entry_price,
                          double stop_loss_price,
                          double take_profit_price,
                          double required_ratio)
   {
   double risk = MathAbs(entry_price - stop_loss_price);
   double reward = MathAbs(take_profit_price - entry_price);
   bool pass = false;
   if (risk > 0)
      {
      double ratio = reward / risk;
      if (ratio >= required_ratio)
         {pass = true;}
      }
   return pass;
   }

//+------------------------------------------------------------------+
//| Convert a pip distance to a monetary risk value for the symbol.  |
//|                                                                  |
//|  Useful for reporting the actual EUR/USD/etc. amount at risk on  |
//|  a trade for logging or dashboards.                              |
//+------------------------------------------------------------------+
double monetary_risk (double stop_loss_pips, double lots)
   {
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double pip_value = tick_value * (_Point / tick_size);
   double risk_money = stop_loss_pips * pip_value * lots;
   return NormalizeDouble(risk_money, 2);
   }

#endif   // RISK_MANAGEMENT_MQH
//+------------------------------------------------------------------+
