# Graph-Based Estimation

```@meta
CurrentModule = CausalEstimate
```

`CausalEstimate.jl` integrates with
[`CausalGraphs.jl`](https://github.com/xiangao/CausalGraphs.jl) to support
graph-identified causal effects. Rather than specifying confounders manually,
you build an ADMG and let the package discover the valid adjustment set from
the graph structure.

## Installation

Install both packages:

```julia
using Pkg
Pkg.add(url="https://github.com/xiangao/CausalEstimate.jl")
Pkg.add(url="https://github.com/xiangao/CausalGraphs.jl")
```

## A Simple Backdoor Example

Suppose you have a graph `X → A → Y ← X`. The confounder `X` creates a
backdoor path from `A` to `Y`. Conditioning on `X` blocks this path and
identifies the ATE.

```@example ce_graph
using CausalEstimate
using CausalGraphs
using DataFrames
using Random

Random.seed!(7)

n = 1000
X = randn(n)
A = Int.(rand(n) .< 1.0 ./ (1.0 .+ exp.(-X)))   # P(A=1|X) = expit(X)
Y = 1.5 .* A .+ 0.8 .* X .+ randn(n)             # true ATE = 1.5

df = DataFrame(Y = Y, A = A, X = X)

r(x) = round(x, sigdigits = 4)

g = make_graph(
    vertices = [:A, :Y, :X],
    di_edges = [(:X, :A), (:X, :Y), (:A, :Y)],
)

draw_graph(g; direction = "LR")
```

Pass the graph as a `GraphID` identification layer between the estimand and
the estimator:

```@example ce_graph
psi = ATE(outcome = :Y, treatment = :A)
result = estimate(psi, GraphID(graph = g), AIPW(crossfit = 2), df)

r(estimate(result))
```

```@example ce_graph
r.(confint(result))
```

The adjustment set that `GraphID` discovered:

```@example ce_graph
result.components[:adjustment_set]
```

`GraphID` reads the **Markov pillow** of the treatment from the graph — the
minimal valid adjustment set implied by the backdoor criterion — and passes it
to the estimator. You never need to list confounders by hand.

## How Graph Identification Works

`CausalGraphs.jl` implements the general fixability hierarchy for ADMGs:

| Graph property | Identification strategy |
|----------------|------------------------|
| a-fixable | Backdoor / Markov-pillow adjustment |
| p-fixable | Front-door / NPS TMLE |
| nested-fixable | ANIPW / nested IPW |
| ID-algorithm identified | Symbolic Pearl-Shpitser functional |

`GraphID` currently routes a-fixable (backdoor) effects. More graph routes can
be added behind the same `estimate` interface.

## Switching Estimators Behind GraphID

You can use `TMLE` instead of `AIPW` without changing anything else:

```@example ce_graph
result_tmle = estimate(psi, GraphID(graph = g), TMLE(crossfit = 2), df)

(
    estimate = r(estimate(result_tmle)),
    ci       = r.(confint(result_tmle)),
)
```

## Comparing Manual and Graph-Identified Adjustment

When confounders are known, both approaches should agree:

```@example ce_graph
psi_manual = ATE(outcome = :Y, treatment = :A, confounders = [:X])
result_manual = estimate(psi_manual, AIPW(crossfit = 2), df)

(
    graph_identified = r(estimate(result)),
    manual           = r(estimate(result_manual)),
)
```

## ATT with GraphID

The same graph-based identification works for ATT:

```@example ce_graph
psi_att = ATT(outcome = :Y, treatment = :A)
result_att = estimate(psi_att, GraphID(graph = g), AIPW(crossfit = 2), df)

r(estimate(result_att))
```

## Scope

Implemented now:

- Graph-implied backdoor adjustment for `ATE`
- Graph-implied backdoor adjustment for `ATT`

Planned next:

- p-fixable / front-door routing through `GraphID`
- Broader ID-algorithm-backed estimation for nested-fixable effects
- Full ADMG result summaries (ACE, confidence intervals, hedge diagnostics)

For full ADMG estimation (p-fixable, nested-fixable, ID-algorithm effects), see
[`CausalGraphs.jl`](https://xiangao.github.io/CausalGraphs.jl/dev/), which
provides the complete estimation pipeline directly.
