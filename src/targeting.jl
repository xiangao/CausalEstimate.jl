using DataFrames
using GLM
using StatsModels

_logit(p) = log(p / (1.0 - p))
_logistic(x) = 1.0 / (1.0 + exp(-x))

function _targeting_step(Y::Vector{Float64}, A::Vector{Float64},
                         Q1::Vector{Float64}, Q0::Vector{Float64},
                         Qobs::Vector{Float64}, ghat::Vector{Float64},
                         is_binary_Y::Bool)
    H = A ./ ghat .- (1.0 .- A) ./ (1.0 .- ghat)
    H1 = 1.0 ./ ghat
    H0 = -1.0 ./ (1.0 .- ghat)

    if is_binary_Y
        df = DataFrame(Y = Y, H = H)
        fit = glm(@formula(Y ~ H + 0), df, Binomial(), LogitLink(); offset = _logit.(Qobs))
        epsilon = coef(fit)[1]
        Q1_star = _logistic.(_logit.(Q1) .+ epsilon .* H1)
        Q0_star = _logistic.(_logit.(Q0) .+ epsilon .* H0)
    else
        epsilon = mean((Y .- Qobs) .* H) / mean(H .^ 2)
        Q1_star = Q1 .+ epsilon .* H1
        Q0_star = Q0 .+ epsilon .* H0
    end

    return (Q1_star = Q1_star, Q0_star = Q0_star, H = H, epsilon = epsilon)
end
