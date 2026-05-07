abstract type Estimand end
abstract type Identification end
abstract type Estimator end

Base.@kwdef struct ATE <: Estimand
    outcome::Symbol
    treatment::Symbol
    treated::Any = 1
    control::Any = 0
    confounders::Vector{Symbol} = Symbol[]
end

Base.@kwdef struct ATT <: Estimand
    outcome::Symbol
    treatment::Symbol
    treated::Any = 1
    control::Any = 0
    confounders::Vector{Symbol} = Symbol[]
end

Base.@kwdef struct LATE <: Estimand
    outcome::Symbol
    treatment::Symbol
    instrument::Symbol
    treated::Any = 1
    control::Any = 0
    encouraged::Any = 1
    discouraged::Any = 0
    confounders::Vector{Symbol} = Symbol[]
end

Base.@kwdef struct EffectCurve <: Estimand
    outcome::Symbol
    treatment::Symbol
    confounders::Vector{Symbol} = Symbol[]
    grid::Any = nothing
end

Base.@kwdef struct IncrementalPS <: Estimand
    outcome::Symbol
    treatment::Symbol
    time::Symbol
    unit::Symbol
    treatment_confounders::Vector{Symbol} = Symbol[]
    outcome_confounders::Vector{Symbol} = Symbol[]
    delta::Any = nothing
end

struct Unconfounded <: Identification end
struct Frontdoor <: Identification end
struct GeneralID <: Identification end

Base.@kwdef struct InstrumentalVariables <: Identification
    instrument::Symbol
end

Base.@kwdef struct GraphID <: Identification
    graph::Any
end

Base.@kwdef struct NuisanceSpec
    outcome_model::Any = nothing
    treatment_model::Any = nothing
    instrument_model::Any = nothing
    auxiliary::NamedTuple = NamedTuple()
end

Base.@kwdef struct AIPW <: Estimator
    nuisances::NuisanceSpec = NuisanceSpec()
    crossfit::Int = 5
    verbosity::Int = 0
end

Base.@kwdef struct TMLE <: Estimator
    nuisances::NuisanceSpec = NuisanceSpec()
    crossfit::Int = 5
    verbosity::Int = 0
end

Base.@kwdef struct Plugin <: Estimator
    nuisances::NuisanceSpec = NuisanceSpec()
end

Base.@kwdef struct ANIPW <: Estimator
    nuisances::NuisanceSpec = NuisanceSpec()
    crossfit::Int = 5
    verbosity::Int = 0
end

Base.@kwdef struct EffectEstimate
    label::Symbol
    value::Float64
    standard_error::Union{Nothing, Float64} = nothing
    lower_ci::Union{Nothing, Float64} = nothing
    upper_ci::Union{Nothing, Float64} = nothing
    influence_curve::Union{Nothing, Vector{Float64}} = nothing
end

Base.@kwdef struct CausalEstimateResult
    estimand::Estimand
    identification::Identification
    estimator::Estimator
    primary::EffectEstimate
    components::Dict{Symbol, Any} = Dict{Symbol, Any}()
end
