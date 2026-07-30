using DataFrames
using Statistics

function _effect_estimate(label::Symbol, value::Real, ic::AbstractVector{<:Real}; level::Float64 = 0.95)
    se = std(ic) / sqrt(length(ic))
    z = _z_score(level)
    EffectEstimate(
        label = label,
        value = Float64(value),
        standard_error = se,
        lower_ci = Float64(value - z * se),
        upper_ci = Float64(value + z * se),
        influence_curve = Float64.(ic),
    )
end

function _mean_potential_outcome(Y::Vector{Float64}, A::Vector{Float64},
                                 mu::Vector{Float64}, pi::Vector{Float64}, arm::Float64;
                                 level::Float64 = 0.95)
    indicator = A .== arm
    ic = (indicator ./ pi) .* (Y .- mu) .+ mu
    est = mean(ic)
    _effect_estimate(Symbol("EY$(Int(arm))"), est, ic .- est; level = level)
end

function estimate(psi::ATE, id::Unconfounded, method::AIPW, data::DataFrame; level::Float64 = 0.95, kwargs...)
    nuis = _binary_nuisances(psi, method.nuisances, data;
                             crossfit = method.crossfit, verbosity = method.verbosity)

    Y = nuis.Y
    A = nuis.A
    Q1 = nuis.Q1
    Q0 = nuis.Q0
    Qobs = nuis.Qobs
    ghat = nuis.ghat

    H = A ./ ghat .- (1 .- A) ./ (1 .- ghat)
    plugin = mean(Q1 .- Q0)
    ic_raw = H .* (Y .- Qobs) .+ (Q1 .- Q0) .- plugin
    ate = plugin + mean(ic_raw)
    ic = ic_raw .- mean(ic_raw)

    primary = _effect_estimate(:ATE, ate, ic; level = level)
    components = Dict{Symbol, Any}(
        :treated => _mean_potential_outcome(Y, A, Q1, ghat, 1.0; level = level),
        :control => _mean_potential_outcome(Y, 1 .- A, Q0, 1 .- ghat, 1.0; level = level),
        :plugin => plugin,
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

function estimate(psi::ATT, id::Unconfounded, method::AIPW, data::DataFrame; level::Float64 = 0.95, kwargs...)
    nuis = _att_nuisances(psi, method.nuisances, data;
                          crossfit = method.crossfit, verbosity = method.verbosity)

    Y = nuis.Y
    A = nuis.A
    pihat = nuis.pihat
    mu0hat = nuis.mu0hat

    mean_a = mean(A)

    # Both the regression and the augmentation term of the ATT are normalised by
    # P(A=1), not by P(A=0). The identity behind the augmentation is
    #     E[(1-A) * pi/(1-pi) * Y] = P(A=1) * E[Y(0) | A=1],
    # since E[(1-pi) * pi/(1-pi) * mu0] = E[pi * mu0]. Dividing the augmentation
    # by mean(1 .- A) instead scales that term by P(A=1)/P(A=0), which leaves the
    # point estimate almost untouched -- the term has mean zero when mu0hat is
    # consistent -- while inflating the influence-curve variance by the same
    # factor. That makes it a silent standard-error bug, so keep the two
    # denominators identical.
    aug = (1 .- A) .* (Y .- mu0hat) .* pihat ./ (1 .- pihat) ./ mean_a

    ey1 = mean(Y[A .== 1.0])
    ey01hat = mean((A ./ mean_a) .* mu0hat .+ aug)
    att = mean((A ./ mean_a) .* (Y .- mu0hat) .- aug)

    if1 = A .* (Y .- ey1) ./ mean_a
    if0 = (A ./ mean_a) .* (mu0hat .- ey01hat) .+ aug
    if_att = (A ./ mean_a) .* (Y .- mu0hat .- att) .- aug

    primary = _effect_estimate(:ATT, att, if_att; level = level)
    components = Dict{Symbol, Any}(
        :treated_mean => _effect_estimate(:EY1_A1, ey1, if1; level = level),
        :counterfactual_control_mean => _effect_estimate(:EY0_A1, ey01hat, if0; level = level),
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
