#!/usr/bin/env julia
# ============================================================================
# brics_live.jl — BLAQUE BAUX BRICS live driver (the Gulf EM diversifier).
#
# Runs on the Blaque Baux ENGINE (engine/ submodule) — same governed order path + Layer-3 safety gate
# as the spine.  data(KSA, UAE, QAT) -> equal-weight Gulf book -> [ GATE ] -> orders.
#
# WHAT SURVIVED THE RESEARCH (and what did NOT):
#   - "best of BRICS" via momentum: REJECTED (+0.36 Sharpe < equal-weight +0.58 < broad EM/EEM +0.55).
#   - the full tradable BRICS+ basket: ~0.90 correlated / 0.77 beta to EEM — broad-EM beta you already own.
#   - THE KEEPER: the GULF pocket (KSA/UAE/QAT) — a LOW-CORRELATION, low-vol EM DIVERSIFIER. It is only
#     ~0.58 correlated to the BRIC-4 equities, calmer (18-20% vol), and it is what lifts a BRICS+ basket
#     from ~2 to ~3.2 effective bets. Russia is excluded on the data (RSX/ERUS delisted 2022).
# So this driver trades the Gulf pocket as a diversifier — NOT a market-beater. Its job is low
# correlation to the family's dominant US-equity exposure, not alpha.
#
# THE DOLLAR-REGIME OVERLAY (the RIGHT signal for this book): brics is a USD-denominated EM book with
# a strong negative beta to the dollar (research #4: -0.66 to UUP), so a rising dollar is a direct
# headwind. This driver consumes AND publishes a DOLLAR regime: when UUP is above its 100-day average
# (dollar trending up -> EM headwind) it de-risks the Gulf gross x0.5; otherwise full. Validated on the
# full 2016-2026 SIP history (brics_dollar_validation.jl): Sharpe +0.48 -> +0.51, maxDD -35% -> -20%.
# It does NOT use the bonds (stock-bond) overlay — that is the wrong signal for a low-US-beta book.
# The regime read is published to $BB_DOLLAR_REGIME_PATH so other USD/international sleeves can size on it.
# Toggle with BB_DOLLAR_OVERLAY=0; tune with BB_DOLLAR_DERISK.
#
# MODES: dry-run by default via the wrapper (BB_DRYRUN=1). Paper: unset BB_DRYRUN with paper keys.
# Real money requires BB_LIVE_CONFIRM=I_UNDERSTAND_THIS_IS_REAL_MONEY. Kill switch: ~/.config/blaquebaux/HALT.
# Run:  julia --project=engine live/brics_live.jl
# ============================================================================
using Dates, Printf, Statistics

const REPO   = normpath(joinpath(@__DIR__, ".."))
const ENGINE = joinpath(REPO, "engine")
include(joinpath(ENGINE, "src/module_7_execution/module_7_execution.jl"))
include(joinpath(ENGINE, "src/module_10_feedback/module_10_feedback.jl"))
include(joinpath(ENGINE, "src/module_13_portfolio/module_13_portfolio.jl"))
include(joinpath(ENGINE, "src/module_1_data/equity_panel.jl"))
include(joinpath(ENGINE, "src/module_1_data/alpaca_panel.jl"))
include(joinpath(ENGINE, "src/module_8_governance/safety_gate.jl"))
using .ExecutionLayer, .FeedbackLayer, .PortfolioOptModule, .EquityPanel, .AlpacaPanel, .SafetyGate
include(joinpath(ENGINE, "scripts/live_execution.jl"))

const UNIVERSE = ["KSA", "UAE", "QAT"]                 # the Gulf pocket — the research keeper
const SIGNAL_UNIVERSE = vcat(UNIVERSE, "UUP")          # + the dollar-trend signal
const GULF_W = 1.0 / length(UNIVERSE)                  # equal-weight (~1x gross)
const LIVE_SENTINEL = "I_UNDERSTAND_THIS_IS_REAL_MONEY"
const DOLLAR_MA = 100                                  # UUP trend window (research #4)
const DOLLAR_DERISK = 0.5                              # gross multiplier when the dollar is trending up

_readf(p) = isfile(p) ? (v = tryparse(Float64, strip(read(p, String))); v === nothing ? NaN : v) : NaN
_writef(p, x) = (mkpath(dirname(p)); write(p, string(x)))

"US-dollar trend regime from UUP vs its 100d average. strong = dollar above trend (EM headwind)."
function dollar_regime(panel; ma = DOLLAR_MA)
    i = findfirst(==("UUP"), panel.symbols); i === nothing && return (; ok = false)
    ur = panel.returns[:, i]; length(ur) < ma + 1 && return (; ok = false)
    px = cumprod(vcat(1.0, 1 .+ ur))
    cur = px[end]; avg = mean(px[end-ma+1:end])
    (; ok = true, strong = cur > avg, mom = cur / px[end-ma] - 1)
end

"Gross multiplier from the dollar regime (graceful: off/no-signal -> 1.0)."
function dollar_scale(dreg; derisk = parse(Float64, get(ENV, "BB_DOLLAR_DERISK", string(DOLLAR_DERISK))))
    get(ENV, "BB_DOLLAR_OVERLAY", "1") in ("0", "false", "no") && return (1.0, "dollar overlay OFF (full gross)")
    dreg.ok || return (1.0, "no dollar signal -> full gross")
    dreg.strong ? (derisk, "STRONG dollar (UUP > 100d MA, EM headwind) -> de-risk x$derisk") :
                  (1.0,    "weak/flat dollar (UUP <= 100d MA) -> full gross")
end

"Publish the dollar regime for the family's USD/international sleeves to size against."
function emit_dollar_regime(path, dreg, asof)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "# Blaque Baux — US dollar trend regime (published by brics; UUP vs 100d MA)")
        println(io, "asof=", asof)
        if !dreg.ok
            println(io, "regime=unknown"); println(io, "risk_on=1")
        else
            @printf(io, "uup_mom100=%.4f\n", dreg.mom)
            println(io, "regime=", dreg.strong ? "strong-dollar" : "weak-dollar")
            println(io, "risk_on=", dreg.strong ? 0 : 1)   # 1 = dollar tailwind (hold EM full); 0 = headwind (de-risk)
        end
    end
end

"Equal-weight Gulf EM diversifier book (KSA/UAE/QAT), scaled by the dollar-regime overlay."
function brics_target(panel, cap; gross_scale = 1.0)
    syms = panel.symbols
    idx(s) = findfirst(==(s), syms); px(s) = panel.prices[idx(s)]
    net = Dict(s => GULF_W * gross_scale for s in UNIVERSE)
    price = Dict(s => px(s) for s in UNIVERSE)
    targets = Dict(s => round(Float64, net[s] * cap / price[s]) for s in UNIVERSE)
    (targets = targets, prices = price, net = net)
end

function main(; capital = nothing, pool = "us", limits::SafetyLimits = SafetyLimits(),
              db_path     = get(ENV, "BB_LEDGER_PATH", joinpath(REPO, "alpaca_ledger_brics.sqlite")),
              audit_path  = get(ENV, "BB_AUDIT_PATH",  joinpath(REPO, "alpaca_audit_brics.jsonl")),
              hwm_path    = get(ENV, "BB_HWM_PATH",    joinpath(homedir(), ".config", "blaquebaux", "equity_hwm_brics.txt")),
              equity_path = get(ENV, "BB_EQUITY_PATH", joinpath(homedir(), ".config", "blaquebaux", "equity_last_brics.txt")),
              regime_path = get(ENV, "BB_DOLLAR_REGIME_PATH", joinpath(homedir(), ".config", "blaquebaux", "dollar_regime.txt")))
    (get(ENV, "ALPACA_KEY_ID", "") == "" || get(ENV, "ALPACA_SECRET_KEY", "") == "") &&
        error("Set ALPACA_KEY_ID and ALPACA_SECRET_KEY (read-only bars are needed even in dry-run).")
    dryrun = get(ENV, "BB_DRYRUN", "") in ("1", "true", "yes")

    if dryrun
        panel = panel_at(AlpacaPanelProvider(SIGNAL_UNIVERSE; lookback = 150))
        dreg = dollar_regime(panel); dscale, dnote = dollar_scale(dreg); emit_dollar_regime(regime_path, dreg, panel.asof)
        bk = brics_target(panel, capital === nothing ? 100_000.0 : capital; gross_scale = dscale)
        @info "BRICS dry run" asof=panel.asof
        println("\n  dollar regime -> ", dnote, "   (published to ", regime_path, ")")
        println("  Gulf EM diversifier (equal-weight, gross ", @sprintf("%.0f%%", 100sum(values(bk.net))), "):")
        for (s, w) in sort(collect(bk.net), by = x -> -x[2])
            @printf("    %-4s %5.1f%%  -> %d sh @ \$%.2f\n", s, 100w, Int(get(bk.targets, s, 0.0)), get(bk.prices, s, NaN))
        end
        ok, reasons = preflight(; account_status = "ACTIVE", equity = 100_000.0, hwm = 100_000.0,
            last_equity = 100_000.0, buying_power = 100_000.0, data_fresh = (Dates.today() - panel.asof) <= Day(5),
            targets = bk.targets, prices = bk.prices, limits = limits)
        println("\n  DRY RUN — no venue, no orders. Gate: ", ok ? "PASS" : "ABORT: " * join(reasons, "; "))
        return ok ? :dryrun_ok : :dryrun_gate_abort
    end

    live = get(ENV, "BB_LIVE_CONFIRM", "") == LIVE_SENTINEL; paper = !live
    mode = live ? "*** LIVE REAL MONEY ***" : "paper"
    @info "brics_live starting" mode
    live && alert("BRICS LIVE REAL-MONEY mode engaged"; level = :critical)
    venue = AlpacaVenue(AlpacaConfig(; paper = paper))
    built = build_live_controller(; venue = venue, ledger_config = LedgerConfig(; db_path = db_path), audit_path = audit_path)
    ctrl, ledger = built.ctrl, built.ledger
    try
        connect!(venue) || (alert("ABORT [$mode]: Alpaca connect failed (brics)"; level = :critical); return :connect_failed)
        acct = account_info(venue)
        acct === nothing && (alert("ABORT [$mode]: could not read account (brics)"; level = :critical); return :no_account)
        cap = capital === nothing ? acct.equity : capital
        hwm = max(load_hwm(hwm_path), acct.equity); last_eq = _readf(equity_path)
        panel = panel_at(AlpacaPanelProvider(SIGNAL_UNIVERSE; lookback = 150)); fresh = (Dates.today() - panel.asof) <= Day(5)
        dreg = dollar_regime(panel); dscale, dnote = dollar_scale(dreg); emit_dollar_regime(regime_path, dreg, panel.asof)
        @info "dollar regime overlay" note=dnote
        bk = brics_target(panel, cap; gross_scale = dscale)
        ok, reasons = preflight(; account_status = acct.status, trading_blocked = acct.trading_blocked,
            account_blocked = acct.account_blocked, equity = acct.equity, hwm = hwm, last_equity = last_eq,
            buying_power = acct.buying_power, data_fresh = fresh, targets = bk.targets, prices = bk.prices, limits = limits)
        save_hwm(hwm, hwm_path); _writef(equity_path, acct.equity)
        if !ok
            msg = "SAFETY ABORT [$mode] (brics): " * join(reasons, "; "); @error msg
            halt!(ctrl, "safety gate"); alert(msg; level = :critical); return :aborted
        end
        reset_daily!(ctrl)
        set_pool_budget!(ctrl, pool, limits.max_gross_leverage * acct.equity)
        set_pool_loss_limit!(ctrl, pool, limits.max_daily_loss)
        set_pool_staleness!(ctrl, pool, Day(5)); feed_staleness!(ctrl, pool; stale = !fresh)
        isfinite(last_eq) && update_pnl!(ctrl, pool, acct.equity - last_eq)
        ncanc = cancel_all_open!(venue); ncanc > 0 && sleep(2)
        for (sym, qty) in positions(venue, ctrl.account); apply_fill!(ctrl, sym, qty); end
        res = execute_rebalance!(ctrl, ledger; targets = bk.targets, prices = bk.prices,
            signal_id = "brics", regime = "gulf-diversifier-usdx$(round(dscale, digits=2))",
            solve_id = Dates.format(panel.asof, "yyyymmdd"), pool_id = pool, settle_secs = 20)
        !res.reconciled && (alert("RECONCILE FAILED [$mode] (brics) — halting"; level = :critical); halt!(ctrl, "reconcile mismatch"))
        summary = "[$mode] brics Gulf diversifier; orders=$(length(res.acks)) fills=$(length(res.fills)) reconciled=$(res.reconciled) equity=$(round(Int, acct.equity))"
        @info "brics_live complete" summary; alert(summary; level = :info)
        return res.reconciled ? :ok : :reconcile_failed
    finally
        disconnect!(venue); close_ledger(ledger)
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
