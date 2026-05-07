using Documenter
using CausalEstimate

makedocs(
    sitename = "CausalEstimate.jl",
    modules = [CausalEstimate],
    format = Documenter.HTML(),
    remotes = nothing,
    pages = [
        "Home" => "index.md",
        "API" => "api.md",
        "Vignettes" => [
            "Getting Started" => "vignettes/01_getting_started.md",
            "Effect Estimators" => "vignettes/02_effect_estimators.md",
            "Graph-Based Estimation" => "vignettes/03_graph_based_estimation.md",
        ],
    ],
)
