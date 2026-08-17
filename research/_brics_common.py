#!/usr/bin/python3
# =============================================================================
# _brics_common.py — shared helpers for the Blaque Baux BRICS sketches.
# Alpaca SIP daily bars; reads ALPACA_KEY_ID / ALPACA_SECRET_KEY from env. Read-only.
#
# The hard gate is TRADABILITY. Russia is EXCLUDED — not on opinion but on data:
# RSX delisted 2022-12-13 and ERUS froze 2022-03-03 (see brics_1). The investable
# BRICS / BRICS+ set is single-country ETFs with real US liquidity:
#   Brazil EWZ | India INDA | China MCHI | South Africa EZA          (original, tradable 4)
#   Saudi KSA  | UAE UAE    | Qatar QAT                              (BRICS+ 2024 additions)
# Benchmarks: EEM/VWO broad EM; ILF LatAm, AAXJ Asia ex-JP (regional-sleeve proxies);
# SPY market; UUP US dollar.
# =============================================================================
import os, json, urllib.request, math
import numpy as np

H = {"APCA-API-KEY-ID": os.environ["ALPACA_KEY_ID"], "APCA-API-SECRET-KEY": os.environ["ALPACA_SECRET_KEY"]}
START, END = "2016-01-01", "2026-08-01"
_cache = {}

BRICS4 = ["EWZ", "INDA", "MCHI", "EZA"]              # original BRICS, tradable (Russia excluded)
PLUS   = ["KSA", "UAE", "QAT"]                        # BRICS+ 2024 additions with liquid ETFs
BRICSX = BRICS4 + PLUS                                # full tradable BRICS+
COUNTRY = {"EWZ": "Brazil", "INDA": "India", "MCHI": "China", "EZA": "South Africa",
           "KSA": "Saudi", "UAE": "UAE", "QAT": "Qatar"}

def bars(s):
    if s in _cache: return _cache[s]
    u = (f"https://data.alpaca.markets/v2/stocks/bars?symbols={s}&timeframe=1Day"
         f"&start={START}&end={END}&adjustment=all&feed=sip&limit=10000")
    try:
        d = json.load(urllib.request.urlopen(urllib.request.Request(u, headers=H), timeout=40))
        _cache[s] = {b["t"][:10]: b for b in d.get("bars", {}).get(s, [])}
    except Exception:
        _cache[s] = {}
    return _cache[s]

def panel(syms):
    """aligned close panel over the common dates of syms -> (syms, dates, closes[T,N])."""
    D = {s: bars(s) for s in syms}; D = {s: v for s, v in D.items() if len(v) > 250}
    u = list(D); dates = sorted(set.intersection(*[set(D[s]) for s in u]))
    M = np.array([[D[s][d]["c"] for s in u] for d in dates], float)
    return u, dates, M

def rets(syms):
    u, dates, M = panel(syms)
    return u, dates[1:], M[1:] / M[:-1] - 1

def stats(r):
    r = np.asarray(r, float); r = r[np.isfinite(r)]
    if len(r) < 30 or r.std() == 0: return dict(sh=float('nan'), cagr=float('nan'), dd=float('nan'), vol=float('nan'))
    cum = np.cumprod(1 + r)
    return dict(sh=r.mean() / r.std() * math.sqrt(252), cagr=cum[-1] ** (252 / len(r)) - 1,
                dd=(cum / np.maximum.accumulate(cum) - 1).min(), vol=r.std() * math.sqrt(252))

def beta(y, x):
    y = np.asarray(y, float); x = np.asarray(x, float)
    m = np.isfinite(y) & np.isfinite(x); y, x = y[m], x[m]
    if len(y) < 30 or np.var(x) == 0: return float('nan')
    return np.cov(y, x)[0, 1] / np.var(x)

def month_ends(dates):
    """indices of the last trading day of each month."""
    out = []
    for i in range(len(dates) - 1):
        if dates[i][:7] != dates[i + 1][:7]: out.append(i)
    out.append(len(dates) - 1)
    return out
