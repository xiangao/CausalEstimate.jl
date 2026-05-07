# CausalEstimate.jl

`CausalEstimate.jl` is the unified front-end for causal effect estimation in
Julia.

The package absorbs the overlapping roles of `NPCausal.jl` and `TMLE.jl` under
one API:

- estimands: `ATE`, `ATT`, `LATE`, `EffectCurve`, `IncrementalPS`
- identification layers: `Unconfounded`, `InstrumentalVariables`, `GraphID`
- estimators: `AIPW`, `TMLE`, `Plugin`, `ANIPW`

Implemented routes:

- `estimate(ATE(...), TMLE(...), data)` for binary-treatment TMLE
- `estimate(ATE(...), AIPW(...), data)` for binary-treatment AIPW
- `estimate(ATT(...), AIPW(...), data)` for ATT
- `estimate(..., GraphID(graph=...), ...)` for graph-implied backdoor adjustment

## Design

The long-term user-facing pattern is:

```julia
using CausalEstimate, DataFrames, Random

Random.seed!(42)
n = 1000
W = randn(n)
A = Int.(rand(n) .< 1.0 ./ (1.0 .+ exp.(-W)))
Y = 2.0 .* A .+ W .+ randn(n)
df = DataFrame(Y = Y, A = A, W = W)

psi = ATE(outcome = :Y, treatment = :A, confounders = [:W])
res = estimate(psi, TMLE(crossfit = 3), df)

estimate(res)
confint(res)
```

For graph-identified effects:

```julia
using CausalEstimate, CausalGraphs, DataFrames, Random

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
res = estimate(psi, GraphID(graph = g), AIPW(crossfit = 3), df)

estimate(res)
```

## Graph-Based Route

```julia
using CausalEstimate, CausalGraphs, DataFrames, Random

Random.seed!(7)
n = 1000
X = randn(n)
A = Int.(rand(n) .< 1.0 ./ (1.0 .+ exp.(-X)))
Y = 1.5 .* A .+ 0.8 .* X .+ randn(n)
df = DataFrame(Y = Y, A = A, X = X)

g = make_graph(vertices = [:A, :Y, :X],
               di_edges = [(:X, :A), (:X, :Y), (:A, :Y)])
psi = ATE(outcome = :Y, treatment = :A)
res = estimate(psi, GraphID(graph = g), AIPW(crossfit = 3), df)
```

`GraphID` currently supports a-fixable/backdoor routing. More graph-identified
estimators can be added behind the same interface.

## Migration Plan

1. Add p-fixable/front-door graph routing.
2. Add `LATE`, continuous-treatment, and incremental intervention backends.
3. Deprecate direct `TMLE.jl` and `NPCausal.jl` front-end entry points after parity.
