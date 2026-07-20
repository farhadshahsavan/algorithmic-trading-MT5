# -*- coding: utf-8 -*-
"""
Backtest Analysis Tools for MetaTrader 5 Strategy Reports
==========================================================
Parses MT5 backtest trade reports (CSV format) and computes
standard quantitative performance metrics.

Author: Dr. Farhad Shahsavan
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
from pathlib import Path


# ── Data loading ──────────────────────────────────────────────────────────────

def load_mt5_trades(filepath: str) -> pd.DataFrame:
    """
    Load MetaTrader 5 backtest trade report from CSV.

    The CSV should contain columns:
    Time, Type, Size, Price, S/L, T/P, Profit, Balance

    Parameters
    ----------
    filepath : str
        Path to the MT5 backtest CSV report.

    Returns
    -------
    pd.DataFrame
        DataFrame of closed trades with parsed columns.
    """
    df = pd.read_csv(filepath, parse_dates=['Time'])
    df.columns = [c.strip().lower().replace(' ', '_') for c in df.columns]

    # Keep only closed trades (rows with profit entries)
    df = df.dropna(subset=['profit']).copy()
    df['profit'] = pd.to_numeric(df['profit'], errors='coerce')
    df['balance'] = pd.to_numeric(df['balance'], errors='coerce')
    df = df.dropna(subset=['profit', 'balance'])
    df = df.sort_values('time').reset_index(drop=True)
    return df


# ── Performance metrics ───────────────────────────────────────────────────────

def compute_metrics(trades: pd.DataFrame, risk_free_rate: float = 0.0) -> dict:
    """
    Compute standard quantitative performance metrics from a trade log.

    Parameters
    ----------
    trades : pd.DataFrame
        Trade log with 'profit' and 'balance' columns.
    risk_free_rate : float
        Annual risk-free rate for Sharpe calculation (default 0.0).

    Returns
    -------
    dict
        Dictionary of performance metrics.
    """
    profits = trades['profit'].values
    balance = trades['balance'].values

    n_trades   = len(profits)
    n_wins     = np.sum(profits > 0)
    n_losses   = np.sum(profits < 0)
    win_rate   = n_wins / n_trades if n_trades > 0 else 0.0

    gross_profit = profits[profits > 0].sum()
    gross_loss   = abs(profits[profits < 0].sum())
    profit_factor = gross_profit / gross_loss if gross_loss > 0 else np.inf

    net_profit   = profits.sum()
    avg_win      = profits[profits > 0].mean() if n_wins > 0 else 0.0
    avg_loss     = profits[profits < 0].mean() if n_losses > 0 else 0.0
    expectancy   = (win_rate * avg_win) + ((1 - win_rate) * avg_loss)

    # Equity curve and drawdown
    equity       = balance
    peak         = np.maximum.accumulate(equity)
    drawdown     = (equity - peak) / peak * 100.0  # percentage
    max_drawdown = drawdown.min()

    # Returns per trade (percentage of balance before trade)
    returns = profits / (balance - profits)  # approximate per-trade return
    sharpe  = (returns.mean() - risk_free_rate / n_trades) / returns.std() \
              * np.sqrt(n_trades) if returns.std() > 0 else 0.0

    return {
        "n_trades"      : n_trades,
        "n_wins"        : n_wins,
        "n_losses"      : n_losses,
        "win_rate"      : round(win_rate * 100, 2),
        "profit_factor" : round(profit_factor, 3),
        "net_profit"    : round(net_profit, 2),
        "gross_profit"  : round(gross_profit, 2),
        "gross_loss"    : round(gross_loss, 2),
        "avg_win"       : round(avg_win, 2),
        "avg_loss"      : round(avg_loss, 2),
        "expectancy"    : round(expectancy, 4),
        "max_drawdown_pct": round(max_drawdown, 2),
        "sharpe_ratio"  : round(sharpe, 3),
    }


def print_metrics(metrics: dict, label: str = "Strategy Performance") -> None:
    """Pretty-print performance metrics."""
    print(f"\n{'='*45}")
    print(f"  {label}")
    print(f"{'='*45}")
    print(f"  Total trades     : {metrics['n_trades']}")
    print(f"  Wins / Losses    : {metrics['n_wins']} / {metrics['n_losses']}")
    print(f"  Win rate         : {metrics['win_rate']}%")
    print(f"  Profit factor    : {metrics['profit_factor']}")
    print(f"  Net profit       : {metrics['net_profit']}")
    print(f"  Avg win          : {metrics['avg_win']}")
    print(f"  Avg loss         : {metrics['avg_loss']}")
    print(f"  Expectancy       : {metrics['expectancy']}")
    print(f"  Max drawdown     : {metrics['max_drawdown_pct']}%")
    print(f"  Sharpe ratio     : {metrics['sharpe_ratio']}")
    print(f"{'='*45}\n")


# ── Walk-forward validation ───────────────────────────────────────────────────

def walk_forward_analysis(
    trades: pd.DataFrame,
    n_insample: int,
    n_outsample: int,
    step: int = None
) -> pd.DataFrame:
    """
    Perform walk-forward validation by splitting trades into rolling
    in-sample (optimisation) and out-of-sample (validation) windows.

    Parameters
    ----------
    trades : pd.DataFrame
        Full trade log sorted by time.
    n_insample : int
        Number of trades in each in-sample window.
    n_outsample : int
        Number of trades in each out-of-sample window.
    step : int, optional
        Step size between windows (default = n_outsample).

    Returns
    -------
    pd.DataFrame
        Table of in-sample vs out-of-sample metrics per window.
    """
    if step is None:
        step = n_outsample

    results = []
    start = 0
    window_num = 1

    while start + n_insample + n_outsample <= len(trades):
        in_sample  = trades.iloc[start : start + n_insample]
        out_sample = trades.iloc[start + n_insample : start + n_insample + n_outsample]

        m_in  = compute_metrics(in_sample)
        m_out = compute_metrics(out_sample)

        results.append({
            "window"              : window_num,
            "is_start_trade"      : start + 1,
            "is_end_trade"        : start + n_insample,
            "oos_start_trade"     : start + n_insample + 1,
            "oos_end_trade"       : start + n_insample + n_outsample,
            "is_sharpe"           : m_in["sharpe_ratio"],
            "oos_sharpe"          : m_out["sharpe_ratio"],
            "is_profit_factor"    : m_in["profit_factor"],
            "oos_profit_factor"   : m_out["profit_factor"],
            "is_win_rate"         : m_in["win_rate"],
            "oos_win_rate"        : m_out["win_rate"],
            "is_max_dd"           : m_in["max_drawdown_pct"],
            "oos_max_dd"          : m_out["max_drawdown_pct"],
        })

        start += step
        window_num += 1

    df_wf = pd.DataFrame(results)

    # Overfitting indicator: large IS/OOS Sharpe divergence
    df_wf["sharpe_degradation"] = df_wf["is_sharpe"] - df_wf["oos_sharpe"]
    return df_wf


# ── Visualisation ─────────────────────────────────────────────────────────────

def plot_equity_and_drawdown(trades: pd.DataFrame, title: str = "Strategy") -> None:
    """
    Plot equity curve and drawdown profile side by side.

    Parameters
    ----------
    trades : pd.DataFrame
        Trade log with 'balance', 'time', and 'profit' columns.
    title : str
        Plot title.
    """
    balance  = trades['balance'].values
    peak     = np.maximum.accumulate(balance)
    drawdown = (balance - peak) / peak * 100.0

    fig = plt.figure(figsize=(12, 7))
    gs  = gridspec.GridSpec(2, 1, height_ratios=[3, 1], hspace=0.05)

    ax1 = fig.add_subplot(gs[0])
    ax1.plot(trades['time'], balance, color='steelblue', linewidth=1.2, label='Equity')
    ax1.fill_between(trades['time'], balance, alpha=0.15, color='steelblue')
    ax1.set_ylabel('Balance')
    ax1.set_title(f'{title} — Equity Curve & Drawdown')
    ax1.legend()
    ax1.set_xticklabels([])
    ax1.grid(True, alpha=0.3)

    ax2 = fig.add_subplot(gs[1], sharex=ax1)
    ax2.fill_between(trades['time'], drawdown, 0, color='tomato', alpha=0.6)
    ax2.set_ylabel('Drawdown (%)')
    ax2.set_xlabel('Date')
    ax2.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.show()


def plot_walk_forward(df_wf: pd.DataFrame) -> None:
    """
    Plot in-sample vs out-of-sample Sharpe ratios across walk-forward windows.

    Parameters
    ----------
    df_wf : pd.DataFrame
        Output from walk_forward_analysis().
    """
    x = df_wf['window']
    fig, axes = plt.subplots(1, 2, figsize=(12, 4))

    axes[0].bar(x - 0.2, df_wf['is_sharpe'],  0.4, label='In-sample',     color='steelblue', alpha=0.8)
    axes[0].bar(x + 0.2, df_wf['oos_sharpe'], 0.4, label='Out-of-sample', color='tomato',    alpha=0.8)
    axes[0].axhline(0, color='black', linewidth=0.8, linestyle='--')
    axes[0].set_xlabel('Walk-forward window')
    axes[0].set_ylabel('Sharpe ratio')
    axes[0].set_title('Sharpe: In-sample vs Out-of-sample')
    axes[0].legend()
    axes[0].grid(True, alpha=0.3)

    axes[1].bar(x - 0.2, df_wf['is_profit_factor'],  0.4, label='In-sample',     color='steelblue', alpha=0.8)
    axes[1].bar(x + 0.2, df_wf['oos_profit_factor'], 0.4, label='Out-of-sample', color='tomato',    alpha=0.8)
    axes[1].axhline(1, color='black', linewidth=0.8, linestyle='--')
    axes[1].set_xlabel('Walk-forward window')
    axes[1].set_ylabel('Profit factor')
    axes[1].set_title('Profit Factor: In-sample vs Out-of-sample')
    axes[1].legend()
    axes[1].grid(True, alpha=0.3)

    plt.tight_layout()
    plt.show()


# ── Entry point ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: python backtest_analysis.py <path_to_mt5_report.csv>")
        print("\nExample with synthetic data:")

        # Generate synthetic trade data for demonstration
        np.random.seed(42)
        n = 200
        profits = np.random.normal(loc=0.5, scale=10.0, size=n)
        balance = 10000.0 + np.cumsum(profits)
        dates   = pd.date_range(start="2023-01-01", periods=n, freq="D")
        trades  = pd.DataFrame({"time": dates, "profit": profits, "balance": balance})

        metrics = compute_metrics(trades)
        print_metrics(metrics, label="Synthetic Strategy Demo")

        plot_equity_and_drawdown(trades, title="Synthetic Strategy Demo")

        df_wf = walk_forward_analysis(trades, n_insample=80, n_outsample=20)
        print("\nWalk-forward summary:")
        print(df_wf[["window", "is_sharpe", "oos_sharpe",
                      "is_profit_factor", "oos_profit_factor"]].to_string(index=False))
        plot_walk_forward(df_wf)

    else:
        trades  = load_mt5_trades(sys.argv[1])
        metrics = compute_metrics(trades)
        print_metrics(metrics)
        plot_equity_and_drawdown(trades)
