# Blaque Baux BRICS — research

First-pass Path-A research on a **tradable BRICS+** cross-section. All sketches read Alpaca SIP daily
bars, are read-only, and print their own results. 2016-01 – 2026-08. The hard gate throughout is
**tradability** — Russia is excluded on the data (see #1), not on opinion.

```bash
export $(grep -v '^#' ~/.config/blaquebaux/alpaca.env | xargs)   # or source it
python research/brics_1_universe.py       # the tradable universe (and the Russia graveyard)
python research/brics_2_cross_section.py  # best-of-group vs equal-weight vs broad EM
python research/brics_3_redundancy.py     # is it additive, or just EM beta?  (the key result)
python research/brics_4_currency.py       # the dollar drag, and can a regime overlay dodge it?
```

## Scorecard

| # | Question | Result | Verdict |
|---|----------|--------|---------|
| 1 | What is actually tradable? | **Russia dead** (RSX last bar 2022-12-13, ERUS 2022-03-03); 7 liquid country ETFs remain — Gulf calm (18-20% vol), BRIC equities wild (27-34% vol, −57/−63% DD) | ✅ universe established |
| 2 | Does "best of group" beat broad EM? | best-of-group momentum **+0.36 Sharpe** < equal-weight **+0.58** < ... ≈ EEM **+0.55**; net of 10bps | ❌ **momentum-picking fails**; curated basket only *ties* EM |
| 3 | Is BRICS+ additive or just EM beta? | corr to EEM **+0.90**, beta +0.77; but **3.2 eff-bets/7** internally — Gulf pocket only +0.58 corr to the BRIC-4 | ⚠️ mostly EM beta; **the additive piece is the Gulf** |
| 4 | Can you dodge the dollar drag? | basket beta to USD **−0.66**; dollar-regime overlay cuts vol 17.6→10.6% & DD −38→−20% but Sharpe +0.53→**+0.48** | ⚠️ FX drag structural; overlay de-risks, adds no alpha |

## The synthesis

**A qualified, mostly-deflating result — with one genuine, non-obvious keeper idea.** The tradable
question does most of the work: "BRICS" is not an investable set. **Russia is gone** — RSX and ERUS
literally stopped trading in 2022 and never came back — and onshore China is access-limited, so a US
book holds 6–7 country ETFs, not a bloc.

Given that universe, the user's framing — *"view only the best from this group"* — was the right
question, and the honest answer is **no, not by momentum.** Best-of-group rotation (hold the top-3 by
trailing 6-month return) returned **+0.36 Sharpe**, *worse* than simply equal-weighting all of them
(+0.58) and worse than just buying broad EM via EEM (+0.55). Picking the recent winners in EM is a
reversion trap, not an edge. And the equal-weight curated basket only **ties** EEM (+0.58 vs +0.55) —
on lower vol, not higher return — because it is **0.90 correlated to EEM with a 0.77 beta**: mostly
broad-EM beta in a narrower, costlier wrapper.

The one thing that is genuinely additive is structural, not a strategy: **the Gulf pocket
(KSA / UAE / QAT).** BRICS+ is *not* one factor internally — it carries **3.2 effective bets across 7
countries**, and that comes from the Gulf, which is only **0.58 correlated** to the BRIC-4 equities
and far calmer (18–20% vol vs 27–34%). The Gulf is a low-vol, low-correlation EM diversifier; "the
best of the BRICs" is EM beta you already own. Finally, the **dollar is a structural headwind**
(−0.66 beta to UUP): a dollar-regime overlay meaningfully *de-risks* the book (vol 17.6→10.6%, drawdown
−38→−20%) but does not improve risk-adjusted return — a sizing lever, consistent with the
[EMEA](https://github.com/blaquebaux/emea) / [APAC](https://github.com/blaquebaux/apac) /
[LATAM](https://github.com/blaquebaux/latam) FX findings.

**Net:** not a standalone alpha sleeve. If BRICS contributes anything to the family, it is a narrow,
honest one — **the Gulf as an EM diversifier, sized for the dollar regime** — not "the best of BRICS."

## Status
**Research: first pass complete — qualified** (`research/`). "Best of BRICS" via momentum is rejected;
the curated basket is ~0.9 EM beta; the single additive, non-obvious finding is the Gulf (KSA/UAE/QAT)
low-correlation pocket. No standalone keeper, no live driver; nothing validated to the spine's bar.
