module CausalEstimate

using DataFrames
using Statistics

include("types.jl")
include("utils.jl")
include("nuisance.jl")
include("aipw.jl")
include("targeting.jl")
include("tmle_backend.jl")
include("inference.jl")
include("estimate.jl")

export Estimand, ATE, ATT, LATE, EffectCurve, IncrementalPS
export Identification, Unconfounded, InstrumentalVariables, Frontdoor, GeneralID, GraphID
export Estimator, AIPW, TMLE, Plugin, ANIPW
export NuisanceSpec, EffectEstimate, CausalEstimateResult
export estimate, confint, pvalue, estimand, identification, estimator, identify

end # module CausalEstimate
