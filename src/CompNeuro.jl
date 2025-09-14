module CompNeuro
    using Revise
    using DrWatson
    findproject(@__DIR__) |> quickactivate
    using DifferentialEquations
    using LaTeXStrings
    using Roots
    using Requires
    using ColorSchemes

    include("update.jl")
    include("integrate.jl")

    _backend = nothing
    # @require Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80" begin
    #     default(grid=false, framestyle=:box, label="", fontfamily="Computer Modern")
    #     _backend = "Plots"
    #     include("plots.jl")
    # end

    function __init__() 
        @require Makie = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a" include("makie.jl")
    end

    export plot_solution
    export @unpack , _backend
    export DiscreteCallback, ContinuousCallback, CallbackSet, ODEProblem, Tsit5, solve
end 

# module CompNeuroJulia
