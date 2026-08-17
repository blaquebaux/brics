#!/usr/bin/env julia
# ============================================================================
# brics_validation.jl — validate-before-live gate for the BRICS Gulf diversifier.
#
# BRICS is not an alpha play — research rejected "best of BRICS" (momentum) and found the full basket
# is ~0.9 EM beta. The keeper is the GULF pocket as a DIVERSIFIER, so the honest bar is a diversifier
# bar (low correlation to the family's dominant US-equity exposure), not a Sharpe bar:
#   1. genuinely low correlation to SPY (the diversification claim),
#   2. a positive standalone risk-adjusted return (a diversifier still shouldn't lose money), and
#   3. a BETTER diversifier than just buying broad EM (EEM) — lower US-equity correlation and calmer.
#
# Fully causal walk-forward reusing brics_target (the real book) net of cost. Reuses brics_target /
# UNIVERSE from brics_live.jl.  Run:  julia --project=engine live/brics_validation.jl
# ============================================================================
include(joinpath(@__DIR__, "brics_live.jl"))
using Dates, Printf, Statistics

_sh(r; ann = 252) = (x = r[isfinite.(r)]; s = std(x); s > 0 ? mean(x) / s * sqrt(ann) : NaN)
_dd(r) = (lvl = cumprod(1 .+ r); minimum(lvl ./ accumulate(max, lvl) .- 1))
_cagr(r) = (lvl = cumprod(1 .+ r); lvl[end]^(252 / length(r)) - 1)
_beta(y, x) = (var(x) > 0 ? cov(y, x) / var(x) : NaN)

function fetch_panel(U, lb = 2600)
    # feed=sip + wide calendar_days -> the full 2016-2026 history (the research window). The engine's
    # default IEX feed only reaches ~2021, which understates a diversifier whose case is full-cycle. SIP
    # bars end ~30d back to dodge the "recent SIP" subscription restriction (validation is historical).
    asof = Dates.today() - Day(30)
    try
        return panel_at(AlpacaPanelProvider(U; lookback = lb, calendar_days = 4300, feed = "sip"), asof)
    catch e
        m = match(r"only (\d+) common", sprint(showerror, e)); m === nothing && rethrow(e)
        n = parse(Int, m.captures[1]) - 20; (n < 200 || n >= lb) && rethrow(e)
        return fetch_panel(U, n)
    end
end

function main_validate(; reb = 21, warmup = 30, cost_bps = parse(Float64, get(ENV, "BB_COST_BPS", "5")))
    panel = fetch_panel(vcat(UNIVERSE, "SPY", "EEM"))
    R = panel.returns; syms = panel.symbols; T = size(R, 1); cost = cost_bps / 1e4
    si = Dict(s => i for (i, s) in enumerate(syms)); dummy = ones(length(syms))
    subpanel(t) = (returns = R[1:t, :], symbols = syms, prices = dummy)
    ret(w, day) = sum(get(w, s, 0.0) * R[day, si[s]] for s in keys(w); init = 0.0)

    gulf = Float64[]; oosidx = Int[]; wprev = Dict{String,Float64}()
    for t0 in warmup:reb:(T-1)
        w = brics_target(subpanel(t0), 1.0).net
        turn = sum(abs(get(w, s, 0.0) - get(wprev, s, 0.0)) for s in union(keys(w), keys(wprev)); init = 0.0)
        for day in (t0+1):min(t0+reb, T)
            r = ret(w, day); day == t0 + 1 && (r -= turn * cost)
            push!(gulf, r); push!(oosidx, day)
        end
        wprev = w
    end
    spy = [R[i, si["SPY"]] for i in oosidx]; eem = [R[i, si["EEM"]] for i in oosidx]
    cG = cor(gulf, spy); cE = cor(eem, spy)

    println("="^78, "\nBRICS — Gulf-diversifier validation (net $(round(Int,cost*1e4)) bps/side, causal)\n", "="^78)
    @printf("\n  OOS days %d   rebalances %d\n", length(gulf), length(warmup:reb:(T-1)))
    @printf("  %-28s %8s %8s %7s %8s %9s\n", "book", "Sharpe", "CAGR", "vol", "maxDD", "corr-SPY")
    for (lbl, r, c) in [("GULF (KSA/UAE/QAT)", gulf, cG), ("broad EM (EEM)", eem, cE), ("SPY", spy, 1.0)]
        @printf("  %-28s %+8.2f %7.1f%% %6.1f%% %7.0f%% %+9.2f\n", lbl, _sh(r), _cagr(r)*100, std(r)*sqrt(252)*100, _dd(r)*100, c)
    end
    @printf("  Gulf beta-to-SPY %+.2f\n", _beta(gulf, spy))

    println("\n  THE BAR (a diversifier, not an alpha play):")
    checks = [
        ("low correlation to SPY (< 0.60)",       cG < 0.60,                @sprintf("%.2f", cG)),
        ("positive standalone Sharpe (> 0.30)",   _sh(gulf) > 0.30,         @sprintf("%.2f", _sh(gulf))),
        ("better diversifier than EEM (lower US corr)", cG < cE,            @sprintf("%.2f vs %.2f", cG, cE)),
        ("calmer than EEM (lower vol)",           std(gulf) < std(eem),     @sprintf("%.1f%% vs %.1f%%", std(gulf)*sqrt(252)*100, std(eem)*sqrt(252)*100)),
    ]
    for (n, ok, v) in checks; @printf("    [%s] %-40s %s\n", ok ? "PASS" : "FAIL", n, v); end
    allpass = all(c -> c[2], checks)
    println("\n  VERDICT: ", allpass ?
        "PASS — a genuine low-correlation EM DIVERSIFIER (the research keeper). Graduates to the paper/\n           dry-run path as a diversifier, NOT a market-beater. Natural overlay is the dollar regime, not stock-bond." :
        "MIXED — does not clear the diversifier bar; stays dry-run.")
    return (; pass = allpass, corr_spy = cG, corr_eem = cE, sh = _sh(gulf))
end

if abspath(PROGRAM_FILE) == @__FILE__
    main_validate()
end
