# Effect Estimators

```@meta
CurrentModule = CausalEstimate
```

This vignette shows the estimators that currently back the unified API.

```@setup ce_estimators
using CausalEstimate
using DataFrames
using Random

Random.seed!(123)

n = 1200
w1 = rand(Bool, n)
w2 = randn(n)
pA = 1.0 ./ (1.0 .+ exp.(-(-0.3 .+ 0.6 .* Float64.(w1) .+ 0.4 .* w2)))
A = Int.(rand(n) .< pA)

Y_cont = 2.0 .* A .+ 0.5 .* Float64.(w1) .+ w2 .+ randn(n)
df_cont = DataFrame(Y = Y_cont, A = A, w1 = Float64.(w1), w2 = w2)

Y0 = 0.5 .* Float64.(w1) .+ w2 .+ randn(n)
Y1 = 1.25 .+ 0.5 .* Float64.(w1) .+ w2 .+ randn(n)
Y_att = A .* Y1 .+ (1 .- A) .* Y0
df_att = DataFrame(Y = Y_att, A = A, w1 = Float64.(w1), w2 = w2)

psi_ate = ATE(outcome = :Y, treatment = :A, confounders = [:w1, :w2])
psi_att = ATT(outcome = :Y, treatment = :A, confounders = [:w1, :w2])
```

## TMLE for ATE

Use `TMLE` when you want the targeted update and the one-step comparison.

```@example ce_estimators
tmle_result = estimate(psi_ate, TMLE(crossfit = 2), df_cont)

(
    estimate = estimate(tmle_result),
    ci = confint(tmle_result),
    one_step = estimate(tmle_result.components[:onestep]),
)
```

## AIPW for ATE

Use `AIPW` when you want the doubly robust one-step estimator directly.

```@example ce_estimators
aipw_result = estimate(psi_ate, AIPW(crossfit = 2), df_cont)

(
    estimate = estimate(aipw_result),
    ci = confint(aipw_result),
    treated_mean = estimate(aipw_result.components[:treated]),
    control_mean = estimate(aipw_result.components[:control]),
)
```

## AIPW for ATT

`ATT` uses the same surface, with a different estimand object.

```@example ce_estimators
att_result = estimate(psi_att, AIPW(crossfit = 2), df_att)

(
    estimate = estimate(att_result),
    ci = confint(att_result),
    treated_mean = estimate(att_result.components[:treated_mean]),
    counterfactual_control = estimate(att_result.components[:counterfactual_control_mean]),
)
```

## Returned Object Shape

All estimation calls return a `CausalEstimateResult`.

```@example ce_estimators
typeof(att_result)
```
