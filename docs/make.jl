using Documenter
using CausalEstimate

makedocs(
    sitename = "CausalEstimate.jl",
    modules = [CausalEstimate],
    format = Documenter.HTML(),
    pages = [
        "Home" => "index.md",
        "API" => "api.md",
        "Vignettes" => [
            "Getting Started" => "vignettes/01_getting_started.md",
            "Effect Estimators" => "vignettes/02_effect_estimators.md",
            "Graph-Based Estimation" => "vignettes/03_graph_based_estimation.md",
        ],
    ],
    warnonly = true,
)

deploydocs(
    repo = "github.com/xiangao/CausalEstimate.jl.git",
    devbranch = "main",
    push_preview = false,
)
