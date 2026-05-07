estimate(x::EffectEstimate) = x.value
estimate(x::CausalEstimateResult) = estimate(x.primary)

estimand(x::CausalEstimateResult) = x.estimand
identification(x::CausalEstimateResult) = x.identification
estimator(x::CausalEstimateResult) = x.estimator

function pvalue(x::EffectEstimate)
    x.standard_error === nothing && error("p-value unavailable; standard error is missing.")
    x.standard_error <= 0 && error("p-value unavailable; standard error must be positive.")
    2 * (1 - cdf(Normal(), abs(x.value / x.standard_error)))
end

pvalue(x::CausalEstimateResult) = pvalue(x.primary)

function confint(x::EffectEstimate; level::Float64 = 0.95)
    if x.lower_ci !== nothing && x.upper_ci !== nothing
        return (x.lower_ci, x.upper_ci)
    end

    if x.standard_error !== nothing
        z = _z_score(level)
        half_width = z * x.standard_error
        return (x.value - half_width, x.value + half_width)
    end

    error("Confidence interval unavailable; provide CI bounds or a standard error.")
end

confint(x::CausalEstimateResult; level::Float64 = 0.95) = confint(x.primary; level = level)

function Base.show(io::IO, x::EffectEstimate)
    print(io, string(x.label), ": ", x.value)
    if x.standard_error !== nothing
        print(io, " (SE=", x.standard_error, ")")
    end
end

function Base.show(io::IO, r::CausalEstimateResult)
    print(io, "CausalEstimateResult(")
    print(io, nameof(typeof(r.estimand)))
    print(io, ", ")
    print(io, nameof(typeof(r.identification)))
    print(io, ", ")
    print(io, nameof(typeof(r.estimator)))
    print(io, ", estimate=")
    print(io, estimate(r))
    print(io, ")")
end
