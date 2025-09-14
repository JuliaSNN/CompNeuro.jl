using Plots
using Mux
using WebIO
using Interact
using Blink

function plot_solution(solution; do_quiver=false)
    @unpack _uu, _ww, _du, _dw, quiver_colors, clims, sol, nc, p, u_range, w_range = solution 
    colors = vcat(quiver_colors, quiver_colors)
    quiver_colors = repeat(colors, inner=4)
    p1 =plot()
    if do_quiver
        quiver!(_uu, _ww, quiver=(_du, _dw), lw=2, line_z=quiver_colors, 
                alpha=0.4, arrow=:closed, cmap=:bluesreds, label="Vector field", cbar=false, clims=clims)
    end
    # Plot
    plot!(xlabel="u", ylabel="w", legend=:topright, title="Phase Plane")
    plot!(nc.u[1], nc.w[1], color=:purple, ls=:solid, lw=4, label="u-nullcline")
    plot!(nc.u[2], nc.w[2], color=:purple, ls=:dash, lw=4, label="w-nullcline")


    params = named_tuple_to_string(p) 
    p0 = plot(sol, labels=["Membrane potential (u)" "Recovery variable (w)"], 
    xlabel="Time (ms)", ylabel="Value", title="", lw=5)
    plot!(p0, legend=:topright, fg_color=:black, legendfontsize=15, rightmargin=25Plots.mm)
    p0_label = plot(frame=:none)
    annotate!(p0_label, (-0.3, 1), Plots.text(params, :left, :top, 15),)
    layout = @layout [a{0.7w} b{0.3w}]
    p0 = plot(p0, p0_label, layout=layout)
    scatter!(p1, sol, idxs = [(1, 2)], lw=8, xlabel="u", ylabel="w", title="Phase Plane", legend=false, c=:black, m=4)
    if haskey(p, :spike_times)    
        for st in p.spike_times
            tt = argmin(abs.(sol.t .- st)) +1
            scatter!(p1, [sol.u[tt][1]], [sol.u[tt][2]], m=:star5, ms=20, label="Spike at t=$(round(st, digits=2))", c=:black)
            vline!(p0, [st], lw=2, c=:black, label="")
        end
    end


    plot!(p1, xlims=extrema(u_range), ylims=extrema(w_range))
    plot(p0, p1, layout=(2,1), size=(1800,1200),  margin=10mm, guidefontsize=22, legendfontsize=14, titlefontsize=20)
end
