using Makie
using GLMakie

_backend = "GLMakie"
@info "Using Makie backend for plotting"
        
function plot_solution(solution, ax1, ax2)
    empty!(ax1)
    empty!(ax2)
    @unpack _uu, _ww, _du, _dw, quiver_colors, clims, sol, nc, p, u_range, w_range = solution 
    set_theme!(
        # theme_dark(),
        fontsize = 20,
        palette = (color = 
        get(ColorSchemes.viridis, range(0.5, 1.0, length=2)) |> ColorScheme
        , linestyle = [:dash, :dot])
    )

    # ax1 = Axis(fig1, xlabel="Time", ylabel="Population", title="AdEx Neuron Model")
    lines!(ax1, sol.t, sol[1, :], label="Membrane Potential (mV)", linewidth=4, color=:black)
    lines!(ax1, sol.t, sol[2, :], label="Adaptive current (w)", linewidth=4, color=:red)
    haskey(p, :θ) || hlines!(ax1, [p.θ], label="Threshold", linestyle=:dash, color=:red)
    isempty(p.spike_times) || vlines!(ax1, p.spike_times, label="Spike times", linestyle=:dash, color=:black)

    # ax2 = Axis(fig2, xlabel="u", ylabel="w", title="Phase plane",)
    arrows2d!(ax2, _uu, _ww, _du, _dw, color=quiver_colors,lengthscale = 0.91, colormap=:bluesreds, strokemask=0, tipwidth=10)
    lines!(ax2, nc.u[2], nc.w[2], label="w-nullcline", linewidth=4)
    lines!(ax2, nc.u[1], nc.w[1], label="u-nullcline", linewidth=4)
    scatter!(ax2, sol[1,:], sol[2,:], color=:black)
    xlims!(ax2, extrema(u_range))
    ylims!(ax2, extrema(w_range))
    if haskey(p, :spike_times)    
        for st in p.spike_times
            tt = argmin(abs.(sol.t .- st)) +1
            scatter!(ax2, [sol.u[tt][1]], [sol.u[tt][2]], markersize=22, color=:red, marker=:star5)
            # vline!(p0, [st], lw=2, c=:black, label="")
        end
    end
end
