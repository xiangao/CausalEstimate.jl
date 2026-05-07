# Effect Estimators

```@meta
CurrentModule = CausalEstimate
```

This vignette compares the estimators available in `CausalEstimate.jl` and
explains when to use each one.

## Setup

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

r(x) = round(x, sigdigits = 4)
```

We work with a two-confounder data-generating process. The true ATE is **2.0**
and the true ATT is **1.25**.

```@example ce_estimators
using CausalEstimate, DataFrames, Random

Random.seed!(123)
n = 1200
w1 = rand(Bool, n)
w2 = randn(n)
pA = 1.0 ./ (1.0 .+ exp.(-(-0.3 .+ 0.6 .* Float64.(w1) .+ 0.4 .* w2)))
A = Int.(rand(n) .< pA)

Y_cont = 2.0 .* A .+ 0.5 .* Float64.(w1) .+ w2 .+ randn(n)
df_cont = DataFrame(Y = Y_cont, A = A, w1 = Float64.(w1), w2 = w2)

psi_ate = ATE(outcome = :Y, treatment = :A, confounders = [:w1, :w2])

r(x) = round(x, sigdigits = 4)

first(df_cont, 5)
```

## TMLE for ATE

**Targeted Maximum Likelihood Estimation** fits nuisance parameters (outcome
regression and propensity score) and then applies a one-dimensional targeting
step that solves the efficient score equation. This targeting step improves
finite-sample behavior relative to a naive plug-in estimator.

```@example ce_estimators
tmle_result = estimate(psi_ate, TMLE(crossfit = 2), df_cont)

(
    estimate  = r(estimate(tmle_result)),
    ci        = r.(confint(tmle_result)),
    one_step  = r(estimate(tmle_result.components[:onestep])),
)
```

`result.components[:onestep]` gives the pre-targeting AIPW one-step estimate,
useful for diagnosing how much the targeting step moved the estimate.

## AIPW for ATE

**Augmented Inverse Probability Weighting** (also known as the doubly robust
one-step estimator) corrects the plug-in estimator with an influence-function
term. It is consistent if either the outcome model or the propensity model is
correctly specified.

```@example ce_estimators
aipw_result = estimate(psi_ate, AIPW(crossfit = 2), df_cont)

(
    estimate      = r(estimate(aipw_result)),
    ci            = r.(confint(aipw_result)),
    treated_mean  = r(estimate(aipw_result.components[:treated])),
    control_mean  = r(estimate(aipw_result.components[:control])),
)
```

The `treated` and `control` components give the separately estimated potential
outcome means E[Y(1)] and E[Y(0)]. The ATE is their difference.

## AIPW for ATT

The ATT weights by the treated subpopulation rather than the full population.
Use the same AIPW estimator with the `ATT` estimand:

```@example ce_estimators
Y0 = 0.5 .* Float64.(w1) .+ w2 .+ randn(n)
Y1 = 1.25 .+ 0.5 .* Float64.(w1) .+ w2 .+ randn(n)
Y_att = A .* Y1 .+ (1 .- A) .* Y0
df_att = DataFrame(Y = Y_att, A = A, w1 = Float64.(w1), w2 = w2)

psi_att = ATT(outcome = :Y, treatment = :A, confounders = [:w1, :w2])
att_result = estimate(psi_att, AIPW(crossfit = 2), df_att)

(
    estimate            = r(estimate(att_result)),
    ci                  = r.(confint(att_result)),
    treated_mean        = r(estimate(att_result.components[:treated_mean])),
    counterfactual_ctrl = r(estimate(att_result.components[:counterfactual_control_mean])),
)
```

`counterfactual_control_mean` is the estimated mean of Y(0) among the treated —
that is, what their outcome would have been under control.

## Choosing Between TMLE and AIPW

| Property | TMLE | AIPW |
|----------|------|------|
| Doubly robust | ✓ | ✓ |
| Targeted update (targeting step) | ✓ | — |
| Respects outcome bounds | ✓ (via logistic targeting) | — |
| Simpler implementation | — | ✓ |
| Access to intermediate estimates | via `:onestep` | via `:treated`, `:control` |

In most settings the two estimators give similar results. TMLE is preferred
when the outcome is bounded (binary or in [0,1]) or when you want the
additional finite-sample guarantee from the targeting step. AIPW is a natural
first choice for continuous unbounded outcomes.

## Result Object

All calls return a `CausalEstimateResult`:

```@example ce_estimators
typeof(att_result)
```

The fields are:

```@example ce_estimators
propertynames(att_result)
```

Access the primary estimate directly via:

```@example ce_estimators
att_result.primary
```
