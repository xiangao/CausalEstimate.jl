# CausalEstimate.jl

`CausalEstimate.jl` is a unified API for causal effect estimation in Julia,
combining the nonparametric estimation methods of `NPCausal.jl` with the
targeted learning machinery of `TMLE.jl` under one consistent interface.

The package implements doubly robust semiparametric estimators — TMLE and
AIPW — with cross-fitting, and an optional graph-based identification layer
via `CausalGraphs.jl`.

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
