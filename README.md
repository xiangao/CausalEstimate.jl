# CausalEstimate.jl

`CausalEstimate.jl` is a unified front-end for causal effect estimation in
Julia, combining the nonparametric estimation methods of `NPCausal.jl` with
the targeted learning machinery of `TMLE.jl` under one consistent API.

Define an estimand, choose an estimator, and call `estimate`. The package
handles nuisance fitting, cross-fitting, and inference automatically.

## Install

```julia
using Pkg
Pkg.add(url="https://github.com/xiangao/CausalEstimate.jl")
```

For graph-identified effects, also install `CausalGraphs.jl`:

```julia
Pkg.add(url="https://github.com/xiangao/CausalGraphs.jl")
```

## Tutorials

Full documentation: **https://xiangao.github.io/CausalEstimate.jl/**

| Vignette | Description |
|----------|-------------|
| [Getting Started](https://xiangao.github.io/CausalEstimate.jl/vignettes/01_getting_started/) | ATE and ATT estimation with TMLE and AIPW |
| [Effect Estimators](https://xiangao.github.io/CausalEstimate.jl/vignettes/02_effect_estimators/) | Comparing TMLE and AIPW, doubly robust inference, and result components |
| [Graph-Based Estimation](https://xiangao.github.io/CausalEstimate.jl/vignettes/03_graph_based_estimation/) | Graph-implied identification with `CausalGraphs.jl` and `GraphID` |

## Quick Start

```julia
using CausalEstimate, DataFrames, Random

Random.seed!(42)
n = 1000
W = randn(n)
A = Int.(rand(n) .< 1.0 ./ (1.0 .+ exp.(-W)))
Y = 2.0 .* A .+ W .+ randn(n)
df = DataFrame(Y = Y, A = A, W = W)

# define the estimand
psi = ATE(outcome = :Y, treatment = :A, confounders = [:W])

# estimate with TMLE (3-fold cross-fitting)
result = estimate(psi, TMLE(crossfit = 3), df)

estimate(result)   # point estimate
confint(result)    # 95% confidence interval
pvalue(result)     # two-sided p-value
```

Switch to AIPW without changing anything else:

```julia
result_aipw = estimate(psi, AIPW(crossfit = 3), df)
estimate(result_aipw)
```

## Graph-Based Estimation

Load `CausalGraphs.jl` and pass a `GraphID` layer to discover the adjustment
set automatically from the graph structure:

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
result = estimate(psi, GraphID(graph = g), AIPW(crossfit = 3), df)

estimate(result)
result.components[:adjustment_set]
```

`GraphID` reads the Markov pillow of the treatment from the graph and uses it
as the adjustment set, then dispatches to the chosen estimator.

## Features

### Estimands

| Type | Description |
|------|-------------|
| `ATE` | Average Treatment Effect |
| `ATT` | Average Treatment Effect on the Treated |
| `LATE` | Local Average Treatment Effect (IV) |
| `EffectCurve` | Effect curve over a treatment grid |
| `IncrementalPS` | Incremental propensity score intervention |

### Identification

| Type | Description |
|------|-------------|
| `Unconfounded` | No unmeasured confounding (default) |
| `GraphID` | Graph-implied backdoor adjustment via `CausalGraphs.jl` |
| `InstrumentalVariables` | IV identification layer |

### Estimators

| Type | Description |
|------|-------------|
| `TMLE` | Targeted Maximum Likelihood Estimation |
| `AIPW` | Augmented Inverse Probability Weighting (doubly robust one-step) |
| `Plugin` | Plug-in / G-computation estimator |
| `ANIPW` | Augmented Nested IPW for nested-fixable effects |

All cross-fitted estimators accept a `crossfit` argument for the number of
folds and use default GLM nuisance fits that can be replaced with any MLJ model.

## API Surface

The long-term stable entry point is:

```julia
estimate(estimand, estimator, data)
estimate(estimand, identification, estimator, data)
```

The returned `CausalEstimateResult` exposes:

```julia
estimate(result)    # Float64 point estimate
confint(result)     # (lower, upper) tuple
pvalue(result)      # two-sided p-value
result.components   # Dict with intermediate estimates (one-step, treated mean, etc.)
```

## Background

`CausalEstimate.jl` merges and unifies two earlier packages:

- [`NPCausal.jl`](https://github.com/xiangao/NPCausal.jl) — nonparametric
  estimation of causal effects via influence functions and cross-fitting,
  based on Kennedy (2022).
- [`TMLE.jl`](https://github.com/xiangao/TMLE.jl) — targeted maximum
  likelihood estimation, following van der Laan and Rose (2011).

The graph-based identification layer integrates with
[`CausalGraphs.jl`](https://github.com/xiangao/CausalGraphs.jl), which handles
ADMG identification, fixability checks, and missing-data weighting.

## References

- Kennedy (2022). *Semiparametric doubly robust targeted double machine learning:
  a review.* arXiv:2203.06469.
- van der Laan and Rose (2011). *Targeted Learning: Causal Inference for
  Observational and Experimental Data.* Springer.
- Bhattacharya, Nabi, and Shpitser. *Semiparametric Inference for Causal
  Effects in Graphical Models with Hidden Variables.*
- Guo and Nabi. *Average Causal Effect Estimation in DAGs with Hidden
  Variables: Extensions of Back-Door and Front-Door Criteria.*
