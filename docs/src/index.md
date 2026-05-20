# CausalEstimate.jl

`CausalEstimate.jl` separates the causal question from the estimator. I use it
when I want to define an estimand once and then try TMLE, AIPW, or a graph-based
adjustment route without rewriting the setup.

The current implementation covers TMLE and AIPW with cross-fitting. It also has
a `GraphID` layer for backdoor adjustment sets supplied by `CausalGraphs.jl`.

## Implemented Routes

| Estimand | Identification | Estimator |
|----------|----------------|-----------|
| `ATE`    | `Unconfounded` | `TMLE`, `AIPW` |
| `ATT`    | `Unconfounded` | `AIPW` |
| `ATE`, `ATT` | `GraphID` (backdoor) | `TMLE`, `AIPW` |

## API

```julia
estimate(estimand, estimator, data)
estimate(estimand, identification, estimator, data)
```

The returned `CausalEstimateResult` exposes:

```julia
estimate(result)    # Float64 point estimate
confint(result)     # (lower, upper) 95% CI
pvalue(result)      # two-sided p-value
result.components   # Dict of intermediate estimates
```

## Vignettes

- [Getting Started](vignettes/01_getting_started.md) — ATE and ATT with TMLE and AIPW
- [Effect Estimators](vignettes/02_effect_estimators.md) — when to use TMLE vs AIPW, result components
- [Graph-Based Estimation](vignettes/03_graph_based_estimation.md) — graph-implied identification with `CausalGraphs.jl`
