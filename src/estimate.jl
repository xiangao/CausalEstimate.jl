_MIGRATION_MESSAGE = """
That estimator route has not been migrated into CausalEstimate.jl yet.

Planned migration path:
- TMLE.jl -> `estimate(ATE(...), TMLE(...), data)` [implemented]
- NPCausal.jl ATE/ATT -> `estimate(ATE(...), AIPW(...), data)` and `estimate(ATT(...), AIPW(...), data)` [implemented]
- CausalGraphs.jl integration -> `estimate(estimand, GraphID(graph=...), estimator, data)` [a-fixable/backdoor route implemented]
"""

function _backend_not_ready(::Estimand, ::Estimator)
    error(_MIGRATION_MESSAGE)
end

function _backend_not_ready(::Estimand, ::Identification, ::Estimator)
    error(_MIGRATION_MESSAGE)
end

"""
    estimate(psi, method, data; kwargs...)

Estimate a causal estimand under the default identification assumptions implied
by `psi` and `method`.
"""
function estimate(psi::Estimand, method::Estimator, data::DataFrame; kwargs...)
    return estimate(psi, identify(_default_identification(psi), psi; kwargs...), method, data; kwargs...)
end

"""
    estimate(psi, id, method, data; kwargs...)

Estimate a causal estimand under an explicit identification strategy.
"""
function estimate(psi::Estimand, id::Identification, method::Estimator, data::DataFrame; kwargs...)
    _backend_not_ready(psi, id, method)
end

"""
    identify(id, psi; kwargs...)

Resolve the identification strategy for `psi`. Graph-based identification is
provided through an optional `CausalGraphs.jl` extension.
"""
function identify(id::Identification, psi::Estimand; kwargs...)
    id isa GraphID &&
        error("`GraphID` requires CausalGraphs.jl. Load both packages with `using CausalEstimate, CausalGraphs`.")
    id
end

_default_identification(::Union{ATE, ATT, EffectCurve, IncrementalPS}) = Unconfounded()
_default_identification(psi::LATE) = InstrumentalVariables(instrument = psi.instrument)
