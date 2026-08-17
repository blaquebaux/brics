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

## Research plan (Path A — not yet built)

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

Nothing above is implemented or validated. This is the map, not the territory.

## Status
**Concept.** Thesis and research plan only — no sketches run, no driver, nothing validated to the
spine's bar. A growth-engine cross-section, gated hard on what is actually tradable.

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
research/   the research plan (Path A) — sketches land here once run
live/       governed live drivers (once a sleeve graduates to paper A/B)
```

## License
[MIT](LICENSE). (c) 2026 Carter Warrens.
