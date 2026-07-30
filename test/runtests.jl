using Test
using CausalEstimate
using DataFrames
using Random
using Statistics

@testset "CausalEstimate.jl" begin
    psi = ATE(outcome = :Y, treatment = :A, confounders = [:W1, :W2])
    @test psi.treated == 1
    @test psi.control == 0
    @test psi.confounders == [:W1, :W2]

    iv = InstrumentalVariables(instrument = :Z)
    @test iv.instrument == :Z

    eta = NuisanceSpec(outcome_model = :q_model, treatment_model = :g_model)
    method = TMLE(nuisances = eta, crossfit = 3)
    @test method.crossfit == 3
    @test method.nuisances.outcome_model == :q_model

    est = EffectEstimate(label = :ATE, value = 1.25, standard_error = 0.2)
    res = CausalEstimateResult(
        estimand = psi,
        identification = Unconfounded(),
        estimator = method,
        primary = est,
    )

    @test estimate(est) == 1.25
    @test estimate(res) == 1.25
    @test estimand(res) === psi
    @test estimator(res) === method
    @test identification(res) isa Unconfounded

    lb, ub = confint(est)
    @test lb < 1.25 < ub
    @test 0 <= pvalue(est) <= 1

    @testset "TMLE ATE" begin
        Random.seed!(42)
        n = 1500
        w1 = rand(Bool, n)
        w2 = randn(n)
        pA = 1.0 ./ (1.0 .+ exp.(-(-0.5 .+ 0.7 .* Float64.(w1) .+ 0.3 .* w2)))
        A = Int.(rand(n) .< pA)
        pY1 = 1.0 ./ (1.0 .+ exp.(-(-1.0 .+ 1.0 .- 0.2 .* Float64.(w1) .+ 0.3 .* w2)))
        pY0 = 1.0 ./ (1.0 .+ exp.(-(-1.0 .- 0.2 .* Float64.(w1) .+ 0.3 .* w2)))
        Y1 = Int.(rand(n) .< pY1)
        Y0 = Int.(rand(n) .< pY0)
        Y = Y1 .* A .+ Y0 .* (1 .- A)
        truth = mean(Y1 .- Y0)

        df = DataFrame(Y = Y, A = A, w1 = Float64.(w1), w2 = w2)
        psi_tmle = ATE(outcome = :Y, treatment = :A, confounders = [:w1, :w2])
        result = estimate(psi_tmle, TMLE(crossfit = 3), df)

        @test abs(estimate(result) - truth) < 0.12
        @test haskey(result.components, :onestep)
        @test result.components[:plugin] != estimate(result)
        @test 0 <= pvalue(result) <= 1
    end

    @testset "AIPW ATE" begin
        Random.seed!(7)
        n = 1200
        W = randn(n)
        pA = 1.0 ./ (1.0 .+ exp.(-W))
        A = Int.(rand(n) .< pA)
        Y = 2.0 .* A .+ W .+ randn(n)

        df = DataFrame(Y = Y, A = A, W = W)
        psi_aipw = ATE(outcome = :Y, treatment = :A, confounders = [:W])
        result = estimate(psi_aipw, AIPW(crossfit = 3), df)

        @test abs(estimate(result) - 2.0) < 0.6
        @test haskey(result.components, :treated)
        @test haskey(result.components, :control)
    end

    @testset "AIPW ATT" begin
        Random.seed!(11)
        n = 1500
        W = randn(n)
        pA = 1.0 ./ (1.0 .+ exp.(-(-0.2 .+ 0.8 .* W)))
        A = Int.(rand(n) .< pA)
        Y0 = W .+ randn(n)
        Y1 = 1.5 .+ W .+ randn(n)
        Y = A .* Y1 .+ (1 .- A) .* Y0

        df = DataFrame(Y = Y, A = A, W = W)
        psi_att = ATT(outcome = :Y, treatment = :A, confounders = [:W])
        result = estimate(psi_att, AIPW(crossfit = 3), df)

        @test abs(estimate(result) - 1.5) < 0.35
        @test haskey(result.components, :treated_mean)
        @test haskey(result.components, :counterfactual_control_mean)

        # The ATT standard error must match a hand-rolled efficient influence
        # curve. This guards a bug the point-estimate test above cannot see:
        # normalising the augmentation term by P(A=0) instead of P(A=1) barely
        # moves the estimate (the term has mean zero under a consistent mu0hat)
        # but scales the SE by P(A=1)/P(A=0).
        nu = result.components[:nuisance]
        p_treat = mean(nu.A)
        aug_ref = (1 .- nu.A) .* (nu.Y .- nu.mu0hat) .*
                  nu.pihat ./ (1 .- nu.pihat) ./ p_treat
        att_ref = mean((nu.A ./ p_treat) .* (nu.Y .- nu.mu0hat) .- aug_ref)
        if_ref = (nu.A ./ p_treat) .* (nu.Y .- nu.mu0hat .- att_ref) .- aug_ref
        se_ref = std(if_ref) / sqrt(length(if_ref))

        @test isapprox(estimate(result), att_ref; rtol = 1e-10)
        @test isapprox(result.primary.standard_error, se_ref; rtol = 1e-10)

        # And the interval must actually cover the truth of 1.5 here; the
        # pre-fix SE was inflated by P(A=1)/P(A=0), which hid its own errors
        # behind an over-wide interval rather than failing loudly.
        lo, hi = confint(result)
        @test lo < 1.5 < hi
        @test (hi - lo) < 1.0
    end

    msg = try
        estimate(LATE(outcome = :Y, treatment = :A, instrument = :Z), AIPW(), DataFrame())
        ""
    catch err
        sprint(showerror, err)
    end
    @test occursin("not been migrated", msg)

    graph_msg = try
        identify(GraphID(graph = :g), psi)
        ""
    catch err
        sprint(showerror, err)
    end
    @test occursin("requires CausalGraphs.jl", graph_msg)
end
