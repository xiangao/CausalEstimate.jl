module CausalEstimateCausalGraphsExt

using CausalEstimate
using CausalGraphs
using DataFrames

function CausalEstimate.identify(id::CausalEstimate.GraphID, psi::CausalEstimate.Estimand; kwargs...)
    return (
        graph = id.graph,
        identification = CausalGraphs.identify(id.graph, psi.treatment, psi.outcome),
    )
end

function _graph_adjustment_set(g, treatment::Symbol)
    CausalGraphs.replace_vector(
        CausalGraphs.markov_pillow(g, treatment; treatment = treatment),
        g.multivariate_variables,
    )
end

function _graph_backdoor_result(psi, id::CausalEstimate.GraphID, method, data::DataFrame; kwargs...)
    route = CausalGraphs.identify(id.graph, psi.treatment, psi.outcome)
    route.strategy == :a_fixable ||
        error("`GraphID` estimation is currently implemented only for a-fixable/backdoor effects. Got `$(route.strategy)`.")

    adjust = _graph_adjustment_set(id.graph, psi.treatment)
    psi2 = typeof(psi)(
        outcome = psi.outcome,
        treatment = psi.treatment,
        treated = psi.treated,
        control = psi.control,
        confounders = Symbol.(adjust),
    )

    res = CausalEstimate.estimate(psi2, CausalEstimate.Unconfounded(), method, data; kwargs...)
    res.components[:graph] = id.graph
    res.components[:identification_result] = route
    res.components[:adjustment_set] = Symbol.(adjust)
    return res
end

function CausalEstimate.estimate(psi::Union{CausalEstimate.ATE, CausalEstimate.ATT},
                                 id::CausalEstimate.GraphID,
                                 method::Union{CausalEstimate.AIPW, CausalEstimate.TMLE},
                                 data::DataFrame; kwargs...)
    _graph_backdoor_result(psi, id, method, data; kwargs...)
end

end # module CausalEstimateCausalGraphsExt
