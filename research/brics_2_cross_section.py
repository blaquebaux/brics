#!/usr/bin/python3
# =============================================================================
# brics_2_cross_section.py — BLAQUE BAUX BRICS #2: does "best of group" beat broad EM?
#
# The real question. Three books, monthly rebalance, net of ~10bps/side:
#   (A) equal-weight tradable BRICS+ basket
#   (B) BEST-OF-GROUP — cross-sectional momentum: hold the top-K by trailing 6m return
#   (C) broad EM (EEM) buy & hold — the thing you'd own instead
# If (B) does not clear (C) net of cost, a curated BRICS book earns nothing over the
# cheap EM ETF, and the sleeve is a repackaging.
# Read-only. Prints its own results.
# =============================================================================
import os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _brics_common import panel, stats, month_ends, BRICSX

COST = 0.0010   # 10 bps/side — country ETFs are liquid but not free
K = 3           # best-of-group holds the top 3

u, dates, M = panel(BRICSX + ["EEM"]); j = {s: u.index(s) for s in u}
rall = M[1:] / M[:-1] - 1
names = [s for s in BRICSX if s in j]
me = month_ends(dates)

def run(select):
    """select(month_end_idx)->list of held names for the next month; returns daily net rets."""
    out = []; prev = set()
    for m in range(len(me) - 1):
        i0, i1 = me[m], me[m + 1]
        held = select(i0)
        w = {s: 1 / len(held) for s in held} if held else {}
        turn = sum(abs(w.get(s, 0) - (1 / len(prev) if s in prev else 0)) for s in set(w) | prev)
        for t in range(i0 + 1, i1 + 1):
            r = sum(w[s] * rall[t - 1, j[s]] for s in w)
            if t == i0 + 1: r -= COST * turn
            out.append(r)
        prev = set(w)
    return np.array(out)

def mom6(i0):   # trailing ~126d return per name, top-K
    if i0 < 130: return names[:K]
    sc = {s: M[i0, j[s]] / M[i0 - 126, j[s]] - 1 for s in names}
    return sorted(sc, key=sc.get, reverse=True)[:K]

A = run(lambda i: names)                         # equal-weight all
B = run(mom6)                                     # best-of-group momentum
# C: broad EM buy & hold over the same scored span
start = me[0] + 1
C = rall[start:len(A) + start, j["EEM"]]

print("=" * 76, "\nBRICS #2 — best-of-group vs equal-weight vs broad EM (net of cost)\n" + "=" * 76)
print(f"  {dates[me[0]]} .. {dates[-1]}  |  monthly rebalance, {int(COST*1e4)}bps/side, top-{K} for best-of-group\n")
print(f"  {'book':<34}{'Sharpe':>8}{'CAGR':>8}{'vol':>7}{'maxDD':>8}")
for lbl, r in [("A  equal-weight BRICS+", A), ("B  best-of-group (6m mom, top-3)", B),
               ("C  broad EM (EEM) buy&hold", C)]:
    st = stats(r)
    print(f"  {lbl:<34}{st['sh']:>+8.2f}{st['cagr']*100:>+7.1f}%{st['vol']*100:>6.1f}%{st['dd']*100:>+7.0f}%")

shB, shC = stats(B)['sh'], stats(C)['sh']
print(f"\nVERDICT: {'best-of-group CLEARS broad EM' if shB > shC + 0.10 else 'best-of-group does NOT clear broad EM'}"
      f" (B {shB:+.2f} vs C {shC:+.2f}). If curated BRICS does not beat the cheap EM ETF net of")
print("cost, the honest read is that the sleeve is EM beta in a costlier wrapper — keep it only if")
print("the rotation genuinely adds, and size it as such.")
