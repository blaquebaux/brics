#!/usr/bin/env julia
# ============================================================================
# brics_dollar_validation.jl — does a DOLLAR-regime overlay improve the Gulf book?
#
# brics is a USD-denominated EM book with a strong NEGATIVE beta to the dollar (research #4: basket
# beta -0.66 to UUP) — a rising dollar is a direct headwind. So the RIGHT overlay for brics keys off
# the DOLLAR trend, not the stock-bond correlation (that is bonds' signal, wrong for a low-US-beta
# Gulf book). Rule: when the dollar is TRENDING UP (UUP above its 100-day average — an EM headwind),
# de-risk the Gulf gross; when it is flat/falling, carry full.
#
# Fully causal walk-forward on the FULL 2016-2026 SIP history, net of cost, comparing FULL vs the
# overlay at several de-risk strengths. Lets the data decide whether the overlay ships on-by-default.
#   Run:  julia --project=engine live/brics_dollar_validation.jl
# ============================================================================
include(joinpath(@__DIR__, "brics_live.jl"))
using Dates, Printf, Statistics

_sh(r; ann = 252) = (x = r[isfinite.(r)]; s = std(x); s > 0 ? mean(x) / s * sqrt(ann) : NaN)
_dd(r) = (lvl = cumprod(1 .+ r); minimum(lvl ./ accumulate(max, lvl) .- 1))
_cagr(r) = (lvl = cumprod(1 .+ r); lvl[end]^(252 / length(r)) - 1)

function fetch_panel(U, lb = 2600)     # full SIP history (IEX only reaches ~2021); end 30d back to dodge recent-SIP limit
    try
        return panel_at(AlpacaPanelProvider(U; lookback = lb, calendar_days = 4300, feed = "sip"), Dates.today() - Day(30))
    catch e
        m = match(r"only (\d+) common", sprint(showerror, e)); m === nothing && rethrow(e)
        n = parse(Int, m.captures[1]) - 20; (n < 200 || n >= lb) && rethrow(e)
        return fetch_panel(U, n)
    end
end

function main_validate(; reb = 21, warmup = 130, ma = 100,
                       cost_bps = parse(Float64, get(ENV, "BB_COST_BPS", "5")))
    panel = fetch_panel(vcat(UNIVERSE, "UUP", "SPY"))
    R = panel.returns; syms = panel.symbols; T = size(R, 1); cost = cost_bps / 1e4
    si = Dict(s => i for (i, s) in enumerate(syms)); dummy = ones(length(syms))
    subpanel(t) = (returns = R[1:t, :], symbols = syms, prices = dummy)
    ret(w, day) = sum(get(w, s, 0.0) * R[day, si[s]] for s in keys(w); init = 0.0)
    # UUP price path (cumulative) for the trend signal
    uup_px = cumprod(vcat(1.0, 1 .+ R[:, si["UUP"]]))
    strong_dollar(t) = (t > ma) && (uup_px[t] > mean(uup_px[t-ma+1:t]))   # UUP above its 100d avg

    function book(derisk)
        out = Float64[]; wprev = Dict{String,Float64}(); nde = 0; npos = 0
        for t0 in warmup:reb:(T-1)
            scale = strong_dollar(t0) ? derisk : 1.0
            npos += 1; scale < 1.0 && (nde += 1)
            w = Dict(s => v * scale for (s, v) in brics_target(subpanel(t0), 1.0).net)
            turn = sum(abs(get(w, s, 0.0) - get(wprev, s, 0.0)) for s in union(keys(w), keys(wprev)); init = 0.0)
            for day in (t0+1):min(t0+reb, T)
                r = ret(w, day); day == t0 + 1 && (r -= turn * cost); push!(out, r)
            end
            wprev = w
        end
        out, nde / npos
    end

    full, _ = book(1.0)
    println("="^78, "\nBRICS — DOLLAR-regime overlay (de-risk the Gulf when the dollar is trending up)\n", "="^78)
    @printf("\n  full 2016-2026 SIP; UUP vs %dd MA; net %d bps/side\n", ma, round(Int, cost*1e4))
    @printf("  %-30s %8s %8s %7s %8s\n", "book", "Sharpe", "CAGR", "vol", "maxDD")
    @printf("  %-30s %+8.2f %7.1f%% %6.1f%% %7.0f%%\n", "FULL (always full gross)", _sh(full), _cagr(full)*100, std(full)*sqrt(252)*100, _dd(full)*100)
    best = nothing
    for d in (0.75, 0.50, 0.0)
        ov, frac = book(d)
        tag = d == 0.0 ? "to cash" : "x$d"
        @printf("  %-30s %+8.2f %7.1f%% %6.1f%% %7.0f%%   (de-risked %.0f%% of rebals)\n",
                "overlay $tag", _sh(ov), _cagr(ov)*100, std(ov)*sqrt(252)*100, _dd(ov)*100, frac*100)
        if best === nothing || _sh(ov) > best[2]; best = (d, _sh(ov), _dd(ov)); end
    end

    shF, ddF = _sh(full), _dd(full); d, shB, ddB = best
    println("\n  THE BAR (overlay must earn on-by-default): best de-risk = ", d == 0.0 ? "to cash" : "x$d")
    checks = [("Sharpe not worse (>= FULL - 0.03)", shB >= shF - 0.03, @sprintf("%.2f vs %.2f", shB, shF)),
              ("reduces max drawdown",              ddB > ddF + 0.005,  @sprintf("%.0f%% vs %.0f%%", ddB*100, ddF*100))]
    for (n, ok, v) in checks; @printf("    [%s] %-34s %s\n", ok ? "PASS" : "FAIL", n, v); end
    allpass = all(c -> c[2], checks)
    println("\n  DECISION (dollar-regime overlay on brics): ", allpass ?
        "ON by default at de-risk " * (d == 0.0 ? "to cash" : "x$d") * " — the right macro signal earns its place." :
        "OFF by default — it de-risks but does not improve the risk-adjusted result (echoes research #4:\n           the FX drag is structural and hard to time). Wired + published for the family via BB_DOLLAR_OVERLAY=1.")
    return (; pass = allpass, best_derisk = d)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main_validate()
end
