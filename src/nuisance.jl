using DataFrames
using Distributions
using MLJ

function _binary_nuisances(psi::Union{ATE, ATT}, spec::NuisanceSpec, data::DataFrame;
                           crossfit::Int, verbosity::Int)
    cols = [psi.outcome, psi.treatment, psi.confounders...]
    _require_columns(data, cols)

    Y = Float64.(data[!, psi.outcome])
    A = _binary_treatment(data[!, psi.treatment], psi.treated, psi.control)
    X = isempty(psi.confounders) ? DataFrame(_intercept = ones(nrow(data))) : select(data, psi.confounders)
    n = nrow(data)

    is_binary_Y = _is_binary(Y)
    q_model = isnothing(spec.outcome_model) ? _default_outcome_model(is_binary_Y) : spec.outcome_model
    g_model = isnothing(spec.treatment_model) ? _default_treatment_model() : spec.treatment_model

    Q1 = zeros(n)
    Q0 = zeros(n)
    Qobs = zeros(n)
    ghat = zeros(n)

    folds = _make_folds(n, crossfit)

    for fold_idx in eachindex(folds)
        test = folds[fold_idx]
        train = setdiff(1:n, test)

        X_tr = X[train, :]
        X_te = X[test, :]
        A_tr = A[train]
        A_te = A[test]
        Y_tr = Y[train]

        XA_tr = hcat(X_tr, DataFrame(A_feat = A_tr))
        XA_te1 = hcat(X_te, DataFrame(A_feat = ones(length(test))))
        XA_te0 = hcat(X_te, DataFrame(A_feat = zeros(length(test))))
        XA_te_obs = hcat(X_te, DataFrame(A_feat = A_te))

        if is_binary_Y
            mach_Q = machine(q_model, XA_tr, MLJ.categorical(Int.(Y_tr)))
            MLJ.fit!(mach_Q, verbosity = verbosity)
            Q1[test] = clamp.(pdf.(MLJ.predict(mach_Q, XA_te1), 1), 1e-6, 1 - 1e-6)
            Q0[test] = clamp.(pdf.(MLJ.predict(mach_Q, XA_te0), 1), 1e-6, 1 - 1e-6)
            Qobs[test] = clamp.(pdf.(MLJ.predict(mach_Q, XA_te_obs), 1), 1e-6, 1 - 1e-6)
        else
            mach_Q = machine(q_model, XA_tr, Y_tr)
            MLJ.fit!(mach_Q, verbosity = verbosity)
            Q1[test] = MLJ.predict(mach_Q, XA_te1)
            Q0[test] = MLJ.predict(mach_Q, XA_te0)
            Qobs[test] = MLJ.predict(mach_Q, XA_te_obs)
        end

        mach_g = machine(g_model, X_tr, MLJ.categorical(Int.(A_tr)))
        MLJ.fit!(mach_g, verbosity = verbosity)
        ghat[test] = clamp.(pdf.(MLJ.predict(mach_g, X_te), 1), 0.001, 0.999)
    end

    return (Y = Y, A = A, X = X, Q1 = Q1, Q0 = Q0, Qobs = Qobs, ghat = ghat,
            is_binary_Y = is_binary_Y)
end

function _att_nuisances(psi::ATT, spec::NuisanceSpec, data::DataFrame;
                        crossfit::Int, verbosity::Int)
    cols = [psi.outcome, psi.treatment, psi.confounders...]
    _require_columns(data, cols)

    Y = Float64.(data[!, psi.outcome])
    A = _binary_treatment(data[!, psi.treatment], psi.treated, psi.control)
    X = isempty(psi.confounders) ? DataFrame(_intercept = ones(nrow(data))) : select(data, psi.confounders)
    n = nrow(data)

    is_binary_Y = _is_binary(Y)
    outcome_model = isnothing(spec.outcome_model) ? _default_outcome_model(is_binary_Y) : spec.outcome_model
    treatment_model = isnothing(spec.treatment_model) ? _default_treatment_model() : spec.treatment_model

    pihat = zeros(n)
    mu0hat = zeros(n)
    folds = _make_folds(n, crossfit)

    for fold_idx in eachindex(folds)
        test = folds[fold_idx]
        train = setdiff(1:n, test)

        X_tr = X[train, :]
        X_te = X[test, :]
        A_tr = A[train]
        Y_tr = Y[train]

        mach_g = machine(treatment_model, X_tr, MLJ.categorical(Int.(A_tr)))
        MLJ.fit!(mach_g, verbosity = verbosity)
        pihat[test] = clamp.(pdf.(MLJ.predict(mach_g, X_te), 1), 1e-4, 1 - 1e-4)

        mask0 = A_tr .== 0.0
        X_tr0 = X_tr[mask0, :]
        Y_tr0 = Y_tr[mask0]

        if is_binary_Y
            mach_mu0 = machine(outcome_model, X_tr0, MLJ.categorical(Int.(Y_tr0)))
            MLJ.fit!(mach_mu0, verbosity = verbosity)
            mu0hat[test] = clamp.(pdf.(MLJ.predict(mach_mu0, X_te), 1), 1e-6, 1 - 1e-6)
        else
            mach_mu0 = machine(outcome_model, X_tr0, Y_tr0)
            MLJ.fit!(mach_mu0, verbosity = verbosity)
            mu0hat[test] = MLJ.predict(mach_mu0, X_te)
        end
    end

    return (Y = Y, A = A, X = X, pihat = pihat, mu0hat = mu0hat, is_binary_Y = is_binary_Y)
end
