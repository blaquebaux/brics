#!/usr/bin/python3
# =============================================================================
# brics_1_universe.py — BLAQUE BAUX BRICS #1: the tradable universe (and the graveyard).
#
# Before any strategy: what can a US book ACTUALLY hold? BRICS-as-a-bloc is not
# investable as written. This sketch (a) proves Russia is untradable on the data —
# RSX and ERUS both stopped trading in 2022 — and (b) profiles the country ETFs that
# remain, so the "best of the tradable" question in #2 rests on a real universe.
# Read-only. Prints its own results.
# =============================================================================
import os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _brics_common import bars, rets, stats, BRICSX, COUNTRY

print("=" * 76, "\nBRICS #1 — the tradable universe (Russia excluded on the data, not opinion)\n" + "=" * 76)

# (a) the graveyard — Russia funds stopped trading in 2022
print("  Russia — UNTRADABLE (excluded):")
for s in ["RSX", "ERUS"]:
    b = bars(s); d = sorted(b)
    if d:
        print(f"    {s}: last bar {d[-1]}  (frozen/delisted after the 2022 invasion — no US access since)")
    else:
        print(f"    {s}: no data")

# (b) the investable set
print("\n  Tradable BRICS+ single-country ETFs, 2016-2026:")
u, dates, R = rets(BRICSX); j = {s: u.index(s) for s in u}
print(f"  {'ETF':<6}{'country':<14}{'Sharpe':>8}{'CAGR':>8}{'vol':>7}{'maxDD':>8}")
for s in BRICSX:
    if s not in j: continue
    st = stats(R[:, j[s]])
    print(f"  {s:<6}{COUNTRY[s]:<14}{st['sh']:>+8.2f}{st['cagr']*100:>+7.1f}%{st['vol']*100:>6.1f}%{st['dd']*100:>+7.0f}%")

print("\nVERDICT: 'BRICS' the acronym is not the investable set. Russia is gone (RSX/ERUS died")
print("in 2022); onshore China A-shares are access-limited (MCHI/FXI are the tradable wrapper).")
print("What a US book can hold is 6-7 country ETFs with very different profiles — Gulf (KSA/UAE/")
print("QAT) low-vol and calm, the BRIC equities high-vol and drawdown-prone. #2 asks if picking")
print("the best of them beats just buying broad EM.")
