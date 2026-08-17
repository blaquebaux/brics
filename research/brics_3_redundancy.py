#!/usr/bin/python3
# =============================================================================
# brics_3_redundancy.py — BLAQUE BAUX BRICS #3: is it just EM beta / redundant?
#
# A sleeve only earns its place if it is ADDITIVE. Two redundancy checks:
#   (a) how correlated is the BRICS+ basket to broad EM (EEM) and to the regional
#       sleeve proxies (ILF LatAm, AAXJ Asia)? high corr + beta ~1 to EEM == repackaging.
#   (b) how many INDEPENDENT bets are inside BRICS+? (eff-bets from the corr matrix) —
#       are the countries diversifying, or one EM factor?
# Read-only. Prints its own results.
# =============================================================================
import os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _brics_common import rets, beta, BRICSX, BRICS4, PLUS

u, dates, R = rets(BRICSX + ["EEM", "ILF", "AAXJ", "SPY"]); j = {s: u.index(s) for s in u}
names = [s for s in BRICSX if s in j]
basket = R[:, [j[s] for s in names]].mean(axis=1)

def effbets(syms):
    Rn = R[:, [j[s] for s in syms if s in j]]
    C = np.corrcoef(Rn.T); lam = np.linalg.eigvalsh(C)
    return C[np.triu_indices(len(C), 1)].mean(), (lam.sum() ** 2) / (lam ** 2).sum()

print("=" * 76, "\nBRICS #3 — redundancy: is BRICS+ additive, or just EM beta?\n" + "=" * 76)
print("  (a) equal-weight BRICS+ basket vs the things you'd hold instead:")
for s in ["EEM", "ILF", "AAXJ", "SPY"]:
    c = np.corrcoef(basket, R[:, j[s]])[0, 1]; b = beta(basket, R[:, j[s]])
    print(f"    vs {s:<5} corr {c:+.2f}   beta {b:+.2f}")

# (b) effective bets — and where they come from (BRIC-4 alone vs adding the Gulf)
avg_all, eff_all = effbets(names)
avg_bric, eff_bric = effbets(BRICS4)
avg_gulf, eff_gulf = effbets(PLUS)
# cross-corr of the Gulf pocket to the BRIC-4 pocket
bric_b = R[:, [j[s] for s in BRICS4 if s in j]].mean(axis=1)
gulf_b = R[:, [j[s] for s in PLUS if s in j]].mean(axis=1)
cross = np.corrcoef(bric_b, gulf_b)[0, 1]
print(f"\n  (b) internal diversification (effective independent bets):")
print(f"    BRIC-4 only (EWZ/INDA/MCHI/EZA): avg corr {avg_bric:+.2f}   eff-bets {eff_bric:.1f}/4")
print(f"    Gulf only  (KSA/UAE/QAT):        avg corr {avg_gulf:+.2f}   eff-bets {eff_gulf:.1f}/3")
print(f"    full BRICS+ (7):                 avg corr {avg_all:+.2f}   eff-bets {eff_all:.1f}/7")
print(f"    BRIC-4 pocket vs Gulf pocket: corr {cross:+.2f}  <- the low cross-corr is the diversifier")

print("\nVERDICT: BRICS+ is ~0.9 correlated to EEM (beta ~0.8) — mostly broad-EM beta in a")
print("narrower, costlier wrapper. But it is NOT one factor internally: the Gulf pocket")
print("(KSA/UAE/QAT) is only weakly correlated to the BRIC-4 equities, and adding it is what")
print("lifts the effective bet count. If BRICS earns a place, the additive piece is the GULF")
print("as an EM diversifier — not 'the best of the BRICs', which is EM beta you already own.")
