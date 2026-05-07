# Getting Started with CausalEstimate.jl

```@meta
CurrentModule = CausalEstimate
```

`CausalEstimate.jl` provides a unified interface for estimating causal effects.
The workflow has three steps:

1. **Define an estimand** — what causal quantity do you want? (`ATE`, `ATT`, …)
2. **Choose an estimator** — how should it be estimated? (`TMLE`, `AIPW`, …)
3. **Call `estimate`** — the package handles nuisance fitting, cross-fitting,
   and inference.

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/xiangao/CausalEstimate.jl")
```

## A First ATE Example

We simulate a simple observational study: a scalar confounder `W`, a binary
treatment `A`, and a continuous outcome `Y`. The true ATE is 2.

```@example ce_getting_started
using CausalEstimate
using DataFrames
using Random

Random.seed!(42)

n = 1000
W = randn(n)
A = Int.(rand(n) .< 1.0 ./ (1.0 .+ exp.(-W)))  # P(A=1|W) = expit(W)
Y = 2.0 .* A .+ W .+ randn(n)                   # true ATE = 2

df = DataFrame(Y = Y, A = A, W = W)
first(df, 5)
```

Define the estimand and estimate with TMLE using 2-fold cross-fitting:

```@example ce_getting_started
r(x) = round(x, sigdigits = 4)

psi = ATE(outcome = :Y, treatment = :A, confounders = [:W])
result = estimate(psi, TMLE(crossfit = 2), df)

r(estimate(result))
```

Extract inferential summaries:

```@example ce_getting_started
r.(confint(result))
```

```@example ce_getting_started
r(pvalue(result))
```

Both TMLE and AIPW are **doubly robust**: they remain consistent if either the
outcome model or the propensity score model is correctly specified (but not
necessarily both). TMLE additionally applies a targeting step that makes the
bias-variance tradeoff more favorable in finite samples.

## Switching Estimators

The `estimate` dispatch is the same regardless of which estimator you choose:

```@example ce_getting_started
result_aipw = estimate(psi, AIPW(crossfit = 2), df)
r(estimate(result_aipw))
```

Both should be close to the true ATE of 2. The estimand object `psi` never
changes — only the estimator does.

## ATT: Effect on the Treated

For the Average Treatment Effect on the Treated, use `ATT`. The identification
assumption is the same (no unmeasured confounding given `W`), but the
estimand weights by the treated subpopulation.

```@example ce_getting_started
Y0 = W .+ randn(n)
Y1 = 1.5 .+ W .+ randn(n)
Y_att = A .* Y1 .+ (1 .- A) .* Y0   # potential outcomes model, true ATT = 1.5
df_att = DataFrame(Y = Y_att, A = A, W = W)

psi_att = ATT(outcome = :Y, treatment = :A, confounders = [:W])
result_att = estimate(psi_att, AIPW(crossfit = 2), df_att)

r(estimate(result_att))
```

## Result Components

Every `CausalEstimateResult` carries a `components` dictionary with
intermediate estimates. For TMLE you can compare the one-step correction:

```@example ce_getting_started
r(estimate(result.components[:onestep]))
```

For AIPW you can inspect the treated and control potential outcome means:

```@example ce_getting_started
(
    treated = r(estimate(result_aipw.components[:treated])),
    control = r(estimate(result_aipw.components[:control])),
)
```

## What Is Implemented

| Estimand | Estimator | Status |
|----------|-----------|--------|
| `ATE`    | `TMLE`    | ✓ |
| `ATE`    | `AIPW`    | ✓ |
| `ATT`    | `AIPW`    | ✓ |
| `ATE` / `ATT` | `GraphID` + `AIPW` / `TMLE` | ✓ |

See the [Effect Estimators](02_effect_estimators.md) and
[Graph-Based Estimation](03_graph_based_estimation.md) vignettes for details.
