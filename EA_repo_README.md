Algorithmic Trading — Portfolio Examples
Selected MQL5 code samples from two years of independent algorithmic trading research using MetaTrader 5.
This repository contains portfolio examples intended to demonstrate coding style, technical structure, and quantitative approach — not the complete strategies used in ongoing personal trading research.
---
About This Work
This work is a collaboration with an experienced FX trader. My role focuses on the quantitative implementation side: translating trading concepts into rigorous, testable MQL5 code, building the technical analysis infrastructure, position-management logic, and systematic validation of ideas. The trading concepts and market intuition come from active trading experience contributed by the collaborator.
The full working strategies remain private for straightforward reasons: they represent genuine intellectual property developed jointly, and public distribution of live trading logic serves no purpose for either party.
What is shared here reflects the coding, structure, and analytical approach.
---
Contents
`EAs/ATR_Breakout_EA/ATR_Breakout_EA.mq5`
Complete standalone Expert Advisor implementing a classic Donchian channel breakout with ATR-based risk management and EMA-slope trend filter. This is a public, well-known strategy — used here to demonstrate a full EA structure:
Multi-timeframe signal architecture with tick and per-bar event handling
Volatility-adaptive stop-loss and take-profit sizing via ATR
Percentage-of-balance position sizing normalised by stop-loss distance
Trailing stop management triggered on profit thresholds
Trading-hour filtering and open-position limits
Clean separation between signal detection, order execution, and risk management
`Utilities/HeikinAshi_Calculator.mqh`
Standalone Heikin-Ashi price transformation utility. Implements the recursive Heikin-Ashi calculation from raw OHLC data, along with helper functions for identifying bullish and bearish HA candles. Includes documentation of the mathematical relations.
`Utilities/SwingPoint_Finder.mqh`
Swing peak and swing bottom detection based on consecutive Heikin-Ashi candle colour patterns. Includes both two-candle and three-candle (stricter) variants for use in market structure analysis and price-action strategies.
`Utilities/RiskManagement.mqh`
Position-sizing utilities:
Fixed-lot approach with stop-loss-distance normalisation
Percentage-of-balance risk sizing with pip-value calculation
Reward-to-risk ratio filter
Monetary risk conversion utility
These utility headers are self-contained and can be included in other MQL5 projects.
---
Development Methodology
Each strategy follows a disciplined research-to-evaluation pipeline:
Hypothesis — Define a market structure or inefficiency to exploit
Signal design — Translate the hypothesis into computable entry/exit conditions
Implementation — Code the EA in MQL5 with risk management and position sizing
In-sample backtest — Initial validation on historical data
Walk-forward validation — Test on out-of-sample windows to detect overfitting
Performance metrics — Sharpe, max drawdown, profit factor, expectancy, trade count
Key principle: a strategy that only performs well in-sample is a curve fit, not a trading edge. All strategies are evaluated primarily on out-of-sample performance.
---
Technical Stack
Tool	Purpose
MetaTrader 5	Trading platform and strategy tester
MQL5	EA and indicator programming (C++-based)
Python (pandas, numpy, matplotlib)	Backtest analysis and validation
Git / GitHub	Version control
---
Note on Trading
This repository is shared for portfolio and educational purposes. The full strategies used in personal research are not public. Live algorithmic trading involves substantial financial risk; past backtest performance does not guarantee future results.
---
Author
Dr. Farhad Shahsavan
PhD in Physics | Quantitative researcher & algorithmic trader
LinkedIn | GitHub
