# CausalEstimate.jl — project notes for Claude

Unified causal-effect estimation API that keeps the estimand (what you're
asking) separate from the estimator (how you compute it). Merges/unifies two
earlier packages: `NPCausal.jl` (AIPW/influence-function estimators, Kennedy
2022) and `TMLE.jl` (targeted maximum likelihood, van der Laan & Rose 2011).

Call pattern: `estimate(estimand, [identification,] estimator, data)` returns
a `CausalEstimateResult` with `estimate()`, `confint()`, `pvalue()`, and a
`.components` `Dict` holding intermediate pieces (plugin estimate, one-step
estimate, nuisance fits, etc.).

## What's actually implemented (as of last read)

The `Project.toml`/README advertise a wide surface, but only a slice has a
working `estimate` method. Don't assume a type further down the table works
just because it's exported.

| Estimand | Identification | Estimator | Status |
|----------|----------------|-----------|--------|
| `ATE` | `Unconfounded` | `TMLE`, `AIPW` | implemented (`src/tmle_backend.jl`, `src/aipw.jl`) |
| `ATT` | `Unconfounded` | `AIPW` | implemented (`src/aipw.jl`); no TMLE ATT yet |
| `ATE`, `ATT` | `GraphID` | `TMLE`, `AIPW` | implemented via extension, backdoor/a-fixable only |
| `LATE`, `EffectCurve`, `IncrementalPS` | any | any | **not implemented** — hits `_backend_not_ready` in `src/estimate.jl`, raises a "not been migrated" error |
| any | `Frontdoor`, `GeneralID` | any | types exist in `src/types.jl`, no dispatch anywhere |
| any | any | `Plugin`, `ANIPW` | types exist, no `estimate` method defined |

`src/estimate.jl`'s `_MIGRATION_MESSAGE` is the authoritative source for what's
planned vs. done — check it before telling a user something works.

## What's where

- `src/types.jl` — all `Estimand`/`Identification`/`Estimator` structs
  (`ATE`, `ATT`, `LATE`, `EffectCurve`, `IncrementalPS`; `Unconfounded`,
  `GraphID`, `InstrumentalVariables`, `Frontdoor`, `GeneralID`; `TMLE`,
  `AIPW`, `Plugin`, `ANIPW`), plus `NuisanceSpec`, `EffectEstimate`,
  `CausalEstimateResult`. Pure data, no logic.
- `src/estimate.jl` — dispatch entry points + `_default_identification`
  (`ATE`/`ATT`/`EffectCurve`/`IncrementalPS` → `Unconfounded`; `LATE` →
  `InstrumentalVariables`) + the not-implemented fallback.
- `src/nuisance.jl` — cross-fitted nuisance regressions (`_binary_nuisances`
  for ATE, `_att_nuisances` for ATT). Default learner is
  `EvoTreeClassifier`/`EvoTreeRegressor` (depth 4, 100 rounds) via MLJ;
  swappable through `NuisanceSpec(outcome_model=..., treatment_model=...)`
  with any MLJ model.
- `src/aipw.jl` — AIPW estimator for `ATE` and `ATT`, doubly-robust one-step.
- `src/targeting.jl` — TMLE's logistic/linear fluctuation (`_targeting_step`);
  binary Y uses a GLM logit fluctuation with `Qobs` as offset, continuous Y
  uses a closed-form epsilon.
- `src/tmle_backend.jl` — TMLE estimator for `ATE` only (builds on
  `_binary_nuisances` + `_targeting_step`).
- `src/inference.jl` — `estimate`/`confint`/`pvalue`/`Base.show` methods on
  `EffectEstimate` and `CausalEstimateResult`. `confint` prefers stored
  `lower_ci`/`upper_ci`, falls back to `value ± z*SE`.
- `src/utils.jl` — cross-fit fold splitting, binary-treatment validation,
  default learner selection, z-score lookup.
- `ext/CausalEstimateCausalGraphsExt.jl` — the `CausalGraphs.jl` weak-dependency
  extension (see below).

## CausalGraphs.jl relationship (weak dependency / extension)

`CausalGraphs.jl` is declared under `[weakdeps]`/`[extensions]` in
`Project.toml` (`CausalEstimateCausalGraphsExt = "CausalGraphs"`), not a hard
dependency — CausalEstimate.jl loads and runs fine without it. The extension
module only activates when a user does
`using CausalEstimate, CausalGraphs` in the same session.

What the extension adds:
- `CausalEstimate.identify(::GraphID, psi)` — calls
  `CausalGraphs.identify(graph, treatment, outcome)` to get an identification
  strategy/route.
- `estimate(::Union{ATE,ATT}, ::GraphID, ::Union{AIPW,TMLE}, data)` — computes
  the adjustment set via `CausalGraphs.markov_pillow` (the treatment's Markov
  pillow, i.e. minimal backdoor set), rebuilds the estimand with that
  adjustment set as `confounders`, and delegates to the existing
  `Unconfounded` `estimate` method. Errors if the graph's identification
  `route.strategy` isn't `:a_fixable` (backdoor) — front-door/ID-algorithm
  routes are not wired up even though `Frontdoor`/`GeneralID` types exist.

Without the extension loaded, `identify(GraphID(...), psi)` raises
`"requires CausalGraphs.jl"` (tested in `test/runtests.jl`). **There is no
dedicated extension test file** — `GraphID` estimation is only exercised by
the docs vignette (`docs/src/vignettes/03_graph_based_estimation.md`), not by
`test/runtests.jl`. If you touch the extension, verify manually via the
vignette or add a test that loads `CausalGraphs`.

## Tests

```bash
cd ~/projects/software/CausalEstimate.jl
julia --project=. test/runtests.jl
```

25/25 passing (~2 min wall time, mostly MLJ/EvoTrees precompilation; the
actual test run is ~1 min). Single flat file, `test/runtests.jl` — covers
struct construction, TMLE ATE, AIPW ATE, AIPW ATT, the not-implemented error
path, and the GraphID-without-CausalGraphs error path. TMLE ATT, any
`GraphID` estimation, and everything in the "not implemented" table above are
untested by this file.

## CI

- `.github/workflows/CI.yml` (new) — runs `test/runtests.jl` on Julia `"1"`
  only (not `"1.10"`, despite `julia = "1.10"` in `[compat]`) because the
  committed `Manifest.toml` was resolved against a recent Julia and doesn't
  instantiate cleanly on 1.10 (stdlib UUID/version mismatches). If you bump
  the compat floor or want real 1.10 coverage, either drop the committed
  Manifest from CI or regenerate it on a 1.10 toolchain.
- `.github/workflows/docs.yml` — builds Documenter.jl docs and deploys to
  `gh-pages` on push to `main`. Installs `CausalGraphs.jl` from GitHub as an
  extra doc-build dependency (since the graph vignette needs it) via
  `Pkg.add(PackageSpec(url=...))` in `docs/Project.toml`'s environment, after
  `Pkg.develop`-ing this package itself.

## Docs

Documenter.jl-based, `docs/make.jl` builds. Structure:
- `docs/src/index.md` — landing page + the implemented-routes table (keep in
  sync with the table above and with `_MIGRATION_MESSAGE`).
- `docs/src/api.md` — `@docs` blocks for `estimate`/`identify`.
- `docs/src/vignettes/` — `01_getting_started.md` (ATE/ATT, TMLE/AIPW),
  `02_effect_estimators.md` (TMLE vs AIPW, result components),
  `03_graph_based_estimation.md` (`GraphID` + `CausalGraphs.jl`, uses
  `@example` blocks so output is live, not just prose).
- Live at <https://xiangao.github.io/CausalEstimate.jl/>.

## Gotchas verified while reading the code

- **`ATT` has no TMLE path.** Only `AIPW` implements `estimate(::ATT, ...)`;
  calling `estimate(ATT(...), TMLE(...), data)` falls through to
  `_backend_not_ready`.
- **Treatment column is validated strictly.** `_binary_treatment` in
  `src/utils.jl` errors if the treatment column contains any value other than
  `psi.treated`/`psi.control` — no silent coercion.
- **`crossfit` bounds are checked** in `_make_folds` (`src/utils.jl`): errors
  if `< 2` or `> n`.
- **TMLE's fluctuation differs by outcome type**: binary `Y` fits a logistic
  GLM fluctuation (`glm(... Binomial(), LogitLink(); offset=logit.(Qobs))`);
  continuous `Y` uses a closed-form OLS-style epsilon
  (`mean((Y.-Qobs).*H)/mean(H.^2)`). Don't assume one code path covers both.
- **`GraphID` rebuilds the estimand**, not just the data: it constructs a new
  `psi2 = typeof(psi)(...)` with `confounders` replaced by the graph-implied
  Markov pillow, then calls the plain `Unconfounded` estimator. If you add a
  new `Estimand` subtype, the extension's `typeof(psi)(...)` reconstruction
  will only work if that subtype's kwarg constructor accepts exactly
  `outcome, treatment, treated, control, confounders`.
