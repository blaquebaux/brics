# Blaque Baux BRICS

**The tradable core of BRICS — the best of the emerging engines of world growth.**

BRICS is a member of the Blaque Baux family. The [core repo](https://github.com/blaquebaux/base)
is the **engine and blueprint** — a governed, systematic platform (Julia) with a venue-agnostic
execution controller and a Layer-3 live-money safety gate. BRICS points that engine in its own
direction and inherits the governance wholesale.

> **Not investment advice.** Educational/research software. Nothing here is validated. See [LICENSE](LICENSE).

```bash
git clone --recursive https://github.com/blaquebaux/brics.git
julia --project=engine -e 'using Pkg; Pkg.instantiate()'   # one-time engine setup
```

## The thesis

The family already has three regional sleeves — [LATAM](https://github.com/blaquebaux/latam),
[EMEA](https://github.com/blaquebaux/emea), [APAC](https://github.com/blaquebaux/apac) — cut by
geography. BRICS cuts differently: it isolates the **large emerging economies actually driving world
growth**, and keeps **only the parts a US-based book can genuinely trade**.

That last constraint does most of the work. "BRICS" as a bloc is not investable as written — **Russia
is effectively untradable** for a US book (sanctions, closed markets) and is excluded on those grounds
alone; China carries VIE / delisting / capital-control risk that must be sized, not waved away. What
remains tradable is a curated set: **Brazil, India, and China via liquid US-listed ADRs and country
ETFs, South Africa, and the BRICS+ additions (UAE, Saudi) where accessible.** The real question is
whether a *curated tradable-BRICS* basket earns its keep over just holding broad EM (EEM/VWO) — and
whether it adds anything the three regional sleeves do not already capture.

## Research plan (Path A)

- **The tradable universe.** Build the investable BRICS/BRICS+ set explicitly — ADRs + country ETFs
  with real liquidity — and document what is excluded and why (Russia: untradable; onshore A-shares:
  access-limited).
- **Best-of-group cross-section.** Rank within the tradable set on the base's factors (trend, value,
  quality) and test whether "the best of BRICS" beats equal-weight BRICS and beats broad EM, net of
  cost and net of the higher FX / borrow frictions.
- **Redundancy check vs. the regional sleeves.** Correlate a tradable-BRICS book against LATAM / EMEA
  / APAC. If it is just a repackaging, say so; keep it only if it is additive.
- **Currency and risk overlay.** EM returns are half FX. Measure the USD/EM-FX exposure and test
  whether hedging or curve-aware sizing improves the risk-adjusted result.

## Research — first pass done

Full detail in [`research/README.md`](research/README.md). The scorecard (Alpaca SIP, 2016–2026):

| # | Question | Verdict |
|---|----------|---------|
| 1 | What is actually tradable? | ✅ **Russia dead** (RSX last bar 2022-12-13, ERUS 2022-03-03); 7 liquid country ETFs remain |
| 2 | Does "best of group" beat broad EM? | ❌ **momentum-picking fails** — top-3 mom +0.36 Sharpe < equal-weight +0.58 ≈ EEM +0.55 |
| 3 | Additive, or just EM beta? | ⚠️ 0.90 corr / 0.77 beta to EEM (mostly EM beta) — but **3.2 eff-bets/7**; the Gulf is the diversifier |
| 4 | Can you dodge the dollar drag? | ⚠️ beta −0.66 to USD; overlay de-risks (vol 18→11%, DD −38→−20%) but adds no Sharpe |

**The synthesis:** a qualified, mostly-deflating result with one genuine keeper idea. "BRICS" isn't an
investable bloc — **Russia literally stopped trading in 2022** — so a US book holds 6–7 country ETFs.
The user's question, *"view only the best,"* was right to ask, and the honest answer is **not by
momentum**: best-of-group rotation (+0.36) underperforms both equal-weight (+0.58) and just buying
broad EM (+0.55), and the curated basket only *ties* EEM because it's **0.90 correlated** to it. The
one genuinely additive, non-obvious piece is structural — **the Gulf pocket (KSA/UAE/QAT)**, only 0.58
correlated to the BRIC-4 equities and far calmer, which lifts the basket to 3.2 effective bets. "The
best of the BRICs" is EM beta you already own; the Gulf is a low-vol EM *diversifier*. The dollar is a
structural headwind you can de-risk but not cheaply hedge (echoing
[EMEA](https://github.com/blaquebaux/emea)/[APAC](https://github.com/blaquebaux/apac)/[LATAM](https://github.com/blaquebaux/latam)).

## Live driver — built (paper/dry-run)

The research keeper — *the Gulf pocket as a low-correlation EM diversifier* — is now a governed driver
on the engine ([`live/brics_live.jl`](live/brics_live.jl)): an equal-weight book of **KSA / UAE / QAT**,
~1× gross, monthly rebalance, through the same Layer-3 safety gate, ledger, reconcile, kill switch and
HWM as the spine. "Best of BRICS" (momentum) and the full basket (EM beta) were rejected in research;
this trades only what survived. It is a **diversifier, not a market-beater**.

```bash
BB_DRYRUN=1 bash live/run_brics_daily.sh            # prints the Gulf book, places nothing
julia --project=engine live/brics_validation.jl     # the diversifier bar (full SIP history)
```

**Validation — PASS (as a diversifier).** The honest bar for a diversifier is *low correlation*, not a
Sharpe race. Causal walk-forward, net of cost, full 2016–2026 SIP history:

| book | Sharpe | CAGR | vol | maxDD | corr-SPY |
|------|--------|------|-----|-------|----------|
| **GULF (KSA/UAE/QAT)** | +0.46 | 5.9% | 15.0% | −35% | **+0.56** |
| broad EM (EEM) | +0.50 | 8.5% | 20.7% | −40% | +0.74 |
| SPY | +0.89 | 15.1% | 16.7% | −34% | +1.00 |

All four checks pass: low correlation to SPY (0.56), positive standalone Sharpe (+0.46), a **better
diversifier than broad EM** (0.56 vs 0.74 US-correlation), and calmer (15.0% vs 20.7% vol). Its job is
low correlation to the family's dominant US-equity exposure, not return.

> **Data note:** the validation uses `feed=sip` for the full 2016–2026 history (the engine's default
> IEX feed only reaches ~2021, which understated a full-cycle diversifier). The *driver* uses the
> default (recent) feed since it only needs current prices for an equal-weight book.

> **No bonds overlay.** The family's bonds-regime overlay keys off the US *stock-bond* correlation —
> the wrong signal for a low-US-beta Gulf book. Brics' own research (#4) found the **dollar regime** is
> its relevant macro (basket beta −0.66 to UUP); a dollar-regime overlay is the natural future addition.

## Status
**Research complete + live driver built — validation PASS (as a diversifier).** The Gulf pocket is a
genuine low-correlation, low-vol EM diversifier (the research keeper); "best of BRICS" (momentum) and
the full basket (EM beta) were rejected. A diversifier, **not** a standalone market-beater. Paper/dry-run;
nothing validated to the spine's bar, no real capital.

## About Blaque Baux

**Blaque Baux** is a quantitative research initiative and a subsidiary of **[Carter Warrens](https://carterwarrens.com)**.
[**BlaqueBaux.com**](https://blaquebaux.com) is the home for the work; the code lives here on GitHub — open to
study, test, and build bespoke strategies on top of.

Anyone can point an AI at a market. The edge is **understanding what the data actually says — and turning it
into something you can act on.** We test relentlessly and put most of it *on the record as rejected, with the
reason*; what survives is built, governed, and validated before it is ever called real. That combination —
honest research, reproducible evidence, and execution you can trust — is why Carter Warrens leads on
**strategy and implementation**, not merely uses the tools everyone now has.

## The Blaque Baux family
This repo is one sleeve of the **Blaque Baux** family — a single governed engine steered in
many directions. The [core repo](https://github.com/blaquebaux/base) is the
base/blueprint and holds the [full family roster](https://github.com/blaquebaux/base#the-blaquebaux-family).

## Layout
```
engine/     the Blaque Baux platform (git submodule -> blaquebaux/base)
research/   four Path-A sketches (universe, cross-section, redundancy, currency) + scorecard
live/       brics_live.jl (Gulf EM diversifier) + brics_validation.jl + wrapper + plist
```

## License
[MIT](LICENSE). (c) 2026 Carter Warrens.
