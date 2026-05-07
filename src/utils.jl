using Distributions
using EvoTrees
using Random: shuffle

function _make_folds(n::Int, k::Int)
    k < 2 && error("`crossfit` must be at least 2.")
    k > n && error("`crossfit` cannot exceed the sample size.")
    idx = shuffle(1:n)
    [idx[1 + floor(Int, (i - 1) * n / k):floor(Int, i * n / k)] for i in 1:k]
end

_is_binary(y::AbstractVector) = all(v -> v == 0.0 || v == 1.0, y)

function _require_columns(data::DataFrame, cols::AbstractVector{Symbol})
    missing = filter(col -> !hasproperty(data, col), cols)
    isempty(missing) || error("Missing required columns: $(join(string.(missing), ", ")).")
end

function _binary_treatment(raw::AbstractVector, treated, control)
    bad = unique(filter(x -> x != treated && x != control, raw))
    isempty(bad) || error("Treatment column must only contain treated=`$treated` and control=`$control` values.")
    Float64.(raw .== treated)
end

function _default_outcome_model(is_binary::Bool)
    is_binary ? EvoTreeClassifier(max_depth = 4, nrounds = 100) :
                EvoTreeRegressor(max_depth = 4, nrounds = 100)
end

_default_treatment_model() = EvoTreeClassifier(max_depth = 4, nrounds = 100)

function _z_score(level::Float64)
    level <= 0.0 && error("`level` must be in (0, 1).")
    level >= 1.0 && error("`level` must be in (0, 1).")
    quantile(Normal(), 0.5 + level / 2)
end
