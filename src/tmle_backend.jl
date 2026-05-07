using DataFrames
using Statistics

function estimate(psi::ATE, id::Unconfounded, method::TMLE, data::DataFrame; level::Float64 = 0.95, kwargs...)
    nuis = _binary_nuisances(psi, method.nuisances, data;
                             crossfit = method.crossfit, verbosity = method.verbosity)

    Y = nuis.Y
    A = nuis.A
    Q1 = nuis.Q1
    Q0 = nuis.Q0
    Qobs = nuis.Qobs
    ghat = nuis.ghat

    targeted = _targeting_step(Y, A, Q1, Q0, Qobs, ghat, nuis.is_binary_Y)
    Q1_star = targeted.Q1_star
    Q0_star = targeted.Q0_star
    H = targeted.H

    tmle_est = mean(Q1_star .- Q0_star)
    Qobs_star = A .* Q1_star .+ (1 .- A) .* Q0_star
    ic_tmle = H .* (Y .- Qobs_star) .+ (Q1_star .- Q0_star) .- tmle_est

    plugin = mean(Q1 .- Q0)
    ic_os_raw = H .* (Y .- Qobs) .+ (Q1 .- Q0) .- plugin
    onestep_est = plugin + mean(ic_os_raw)
    ic_os = ic_os_raw .- mean(ic_os_raw)

    primary = _effect_estimate(:ATE, tmle_est, ic_tmle; level = level)
    components = Dict{Symbol, Any}(
        :tmle => primary,
        :onestep => _effect_estimate(:OneStep, onestep_est, ic_os; level = level),
        :plugin => plugin,
        :targeting_epsilon => targeted.epsilon,
        :nuisance => nuis,
    )

    return CausalEstimateResult(
        estimand = psi,
        identification = id,
        estimator = method,
        primary = primary,
        components = components,
    )
end
