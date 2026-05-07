# Graph-Based Estimation

```@meta
CurrentModule = CausalEstimate
```

`CausalEstimate.jl` uses `CausalGraphs.jl` as an optional identification layer.
Right now the implemented graph route is a-fixable/backdoor adjustment through
`GraphID`.

```@example ce_graph
using CausalEstimate
using CausalGraphs
using DataFrames
using Random

Random.seed!(7)

n = 1000
X = randn(n)
A = Int.(rand(n) .< 1.0 ./ (1.0 .+ exp.(-X)))
Y = 1.5 .* A .+ 0.8 .* X .+ randn(n)
df = DataFrame(Y = Y, A = A, X = X)

g = make_graph(
    vertices = [:A, :Y, :X],
    di_edges = [(:X, :A), (:X, :Y), (:A, :Y)],
)

psi = ATE(outcome = :Y, treatment = :A)
result = estimate(psi, GraphID(graph = g), AIPW(crossfit = 2), df)

estimate(result)
```

The graph route discovers the adjustment set from the graph and then dispatches
to the chosen estimator.

```@example ce_graph
result.components[:adjustment_set]
```

You can also use `TMLE` behind the same graph-derived adjustment:

```@example ce_graph
result_tmle = estimate(psi, GraphID(graph = g), TMLE(crossfit = 2), df)

(
    estimate = estimate(result_tmle),
    ci = confint(result_tmle),
)
```

## Scope

Implemented now:

- graph-implied backdoor adjustment for `ATE`
- graph-implied backdoor adjustment for `ATT`

Planned next:

- p-fixable / front-door routing
- broader ID-algorithm-backed estimation
- more ADMG-specific result summaries
