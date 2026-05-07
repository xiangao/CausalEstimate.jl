# Getting Started with CausalEstimate.jl

```@meta
CurrentModule = CausalEstimate
```

`CausalEstimate.jl` gives you one interface for causal effect estimation:

- define an estimand such as `ATE` or `ATT`
- optionally specify an identification layer such as `GraphID`
- choose an estimator such as `TMLE` or `AIPW`
- call `estimate(...)`

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/xiangao/CausalEstimate.jl")
```

## A First ATE Example

```@example ce_getting_started
using CausalEstimate
using DataFrames
using Random

Random.seed!(42)

n = 1000
W = randn(n)
A = Int.(rand(n) .< 1.0 ./ (1.0 .+ exp.(-W)))
Y = 2.0 .* A .+ W .+ randn(n)
df = DataFrame(Y = Y, A = A, W = W)

psi = ATE(outcome = :Y, treatment = :A, confounders = [:W])
result = estimate(psi, TMLE(crossfit = 2), df)

estimate(result)
```

You can then extract standard inferential summaries:

```@example ce_getting_started
confint(result)
```

```@example ce_getting_started
pvalue(result)
```

## Switching Estimators Without Changing the Estimand

The front-end API stays stable even when you change the estimator:

```@example ce_getting_started
result_aipw = estimate(psi, AIPW(crossfit = 2), df)
estimate(result_aipw)
```

## ATT Example

```@example ce_getting_started
Y0 = W .+ randn(n)
Y1 = 1.5 .+ W .+ randn(n)
Y_att = A .* Y1 .+ (1 .- A) .* Y0
df_att = DataFrame(Y = Y_att, A = A, W = W)

psi_att = ATT(outcome = :Y, treatment = :A, confounders = [:W])
result_att = estimate(psi_att, AIPW(crossfit = 2), df_att)

estimate(result_att)
```

## What Is Implemented Now

Current implemented routes:

- `ATE` with `TMLE`
- `ATE` with `AIPW`
- `ATT` with `AIPW`
- graph-implied backdoor adjustment with `GraphID`

Additional estimands from the older `NPCausal.jl` codebase are planned to move
under the same interface.
