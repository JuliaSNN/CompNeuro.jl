function nulleclines(func, p, u_range)
    null_w = (x,y,n)-> begin
                z = zeros(2)
                u0 = [x, y]
                func(z, u0, p, 0.0)
                z[n]
    end

    us = u_range
    ws = zeros(length(us), 2)
    for n in eachindex(us)
        x0 = us[n]
        _null_w = y-> null_w(x0,y, 2)
        zero_w = find_zero(_null_w, 0.f0, Order2())

        _null_u = y-> null_w(x0,y, 1)
        zero_u = find_zero(_null_u, 0.f0, Order2())
        ws[n, 1] = zero_u
        ws[n, 2] = zero_w
    end
    return (u=[us,us], w=[ws[:,2], ws[:,1]])
end


function run_model(p, u0, func, tspan=(0.0, 100.); V_th=Inf, u_range, w_range, do_quiver=true, reset_cb=nothing)
    # Time span
    @unpack t_impulse, ϵ, A, b = p

    # Define the ODE problem
    prob = ODEProblem(func, u0, tspan, p)

    input_times = [t_impulse]
    affect!(integrator) = integrator.u[1] += A
    delta_cb = PresetTimeCallback(input_times, affect!)

    # Reset condition: when V crosses V_th, reset to V_reset
    reset_condition(u, t, integrator) = u[1] - V_th

    # Reset action: set V to V_reset
    reset_affect! = (integrator) -> begin
        integrator.u[1] = V_reset
        integrator.u[2] += b
        @error "Spike at time $(integrator.t), resetting V to $V_reset and w to $(integrator.u[2])"
    end

    reset_cb = isnothing(reset_cb) ? ContinuousCallback(reset_condition, reset_affect!) : reset_cb

    cb = CallbackSet(reset_cb, delta_cb)
    sol = solve(prob, Tsit5(), abstol=1e-8, callback=cb, reltol=1e-6)

    # Nullclines
    u_range = range(u_range[1], u_range[end], length=40)
    nc = nulleclines(func, p, u_range)

    uu_range = range(u_range[1], u_range[end], length=25) 
    ww_range = range(w_range[1], w_range[end], length=25)
    
    # Compute vector field
    _du = [let 
            du = zeros(2)
            func(du, [u, w], p, 0.0)[1]
            du = normalize(du)[1] .* diff(u_range)[1]
            end
            for u in uu_range for w in ww_range]
    
    _dw = [let 
            du = zeros(2)
            func(du, [u, w], p, 0.0)[1]
            du = normalize(du)[2] .* diff(w_range)[1]
            end
            for u in uu_range for w in ww_range]
    
        
    _uu = [u for u in uu_range for w in ww_range]
    _ww = [w for u in uu_range for w in ww_range]


    colors = cos.(atan.(_dw/ϵ, _du ))
    quiver_colors = colors
    _clims = minimum([abs(minimum(colors)), abs(maximum(colors))])
    clims = (-_clims, _clims)

    return (; _uu, _ww, _du, _dw, quiver_colors, clims, sol, nc, p, u_range, w_range)
end

export run_model, plot_solution