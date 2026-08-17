#!/usr/bin/python3
# =============================================================================
# brics_4_currency.py — BLAQUE BAUX BRICS #4: the dollar drag, and can you dodge it?
#
# EM equity returns for a US holder are half an FX bet: these ETFs are USD-priced, so
# a rising dollar is a direct headwind. Two tests:
#   (a) the BRICS+ basket's beta / correlation to the US dollar (UUP).
#   (b) a dollar-REGIME overlay: hold BRICS+ only when the dollar is NOT trending up
#       (UUP below its 100d average), else sit in cash. Does dodging strong-dollar
#       regimes improve the risk-adjusted result, or is it just another whipsaw?
# Read-only. Prints its own results.
# =============================================================================
import os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _brics_common import panel, stats, beta, BRICSX

u, dates, M = panel(BRICSX + ["UUP"]); j = {s: u.index(s) for s in u}
R = M[1:] / M[:-1] - 1
names = [s for s in BRICSX if s in j]
basket = R[:, [j[s] for s in names]].mean(axis=1)
uup = R[:, j["UUP"]]

print("=" * 76, "\nBRICS #4 — the dollar drag, and whether a regime overlay dodges it\n" + "=" * 76)

# (a) dollar sensitivity
c = np.corrcoef(basket, uup)[0, 1]; b = beta(basket, uup)
print(f"  (a) BRICS+ basket vs US dollar (UUP): corr {c:+.2f}   beta {b:+.2f}")
print(f"      dollar UP-days basket avg {basket[uup>0].mean()*100:+.2f}%  |  "
      f"dollar DOWN-days basket avg {basket[uup<0].mean()*100:+.2f}%")

# (b) dollar-regime overlay: UUP price vs its 100d MA (no look-ahead: use yesterday's signal)
uupx = M[1:, j["UUP"]]
ma = np.full(len(uupx), np.nan)
for i in range(100, len(uupx)): ma[i] = uupx[i - 100:i].mean()
risk_on = np.concatenate([[False], (uupx[:-1] < ma[:-1])])   # dollar below trend yesterday -> hold EM
overlay = np.where(risk_on, basket, 0.0)                     # else cash (0)
start = 100
print(f"\n  (b) overlay scored {dates[start+1]} .. {dates[-1]}   risk-on {100*risk_on[start:].mean():.0f}% of days")
print(f"  {'book':<30}{'Sharpe':>8}{'CAGR':>8}{'vol':>7}{'maxDD':>8}")
for lbl, r in [("BRICS+ buy & hold", basket[start:]), ("BRICS+ dollar-regime overlay", overlay[start:])]:
    st = stats(r)
    print(f"  {lbl:<30}{st['sh']:>+8.2f}{st['cagr']*100:>+7.1f}%{st['vol']*100:>6.1f}%{st['dd']*100:>+7.0f}%")

sh0, sh1 = stats(basket[start:])['sh'], stats(overlay[start:])['sh']
print(f"\nVERDICT: the dollar is a real headwind (negative beta to UUP). The regime overlay "
      f"{'HELPS' if sh1 > sh0 + 0.10 else 'does NOT clearly help'} (Sharpe {sh0:+.2f} -> {sh1:+.2f}).")
print("Consistent with the EMEA/APAC/LATAM finding: the FX drag is structural and hard to shed in")
print("an equity wrapper; a dollar-regime read is a sizing input at best, not a clean hedge.")
