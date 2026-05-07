# CausalEstimate.jl

`CausalEstimate.jl` is a unified API for treatment effect estimation and
graph-identified causal estimands in Julia.

Implemented routes:

- `ATE` with `TMLE`
- `ATE` with `AIPW`
- `ATT` with `AIPW`
- graph-implied backdoor adjustment via `GraphID`

The package is designed around a single dispatch surface:

```julia
estimate(estimand, estimator, data)
estimate(estimand, identification, estimator, data)
```

Start with:

- [Getting Started](vignettes/01_getting_started.md)
- [Effect Estimators](vignettes/02_effect_estimators.md)
- [Graph-Based Estimation](vignettes/03_graph_based_estimation.md)
