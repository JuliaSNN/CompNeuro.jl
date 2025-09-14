using DrWatson
findproject(@__DIR__) |> quickactivate
using GLMakie
using CompNeuro

function morris_lecar!(du, u, p, t)
    V, w = u
    @unpack I, g_Ca, g_K, g_L, V_Ca, V_K, V_L, V1, V2, V3, V4, ϕ  = p

    # Steady-state activation functions
    m_inf(V) = 0.5 * (1 + tanh((V - V1) / V2))
    w_inf(V) = 0.5 * (1 + tanh((V - V3) / V4))
    τ_w(V) = 1 / cosh((V - V3) / (2 * V4))

    # Current balance equation
    I_Ca = g_Ca * m_inf(V) * (V - V_Ca)
    I_K = g_K * w * (V - V_K)
    I_L = g_L * (V - V_L)

    du[1] = (I - I_Ca - I_K - I_L) / C  # dV/dt
    du[2] = ϕ * (w_inf(V) - w) / τ_w(V)     # dw/dt
end

# Parameters for three fixed points
C = 20.0
I = 0.0
g_Ca, g_K, g_L = 4.0, 8.0, 2.0
V_Ca, V_K, V_L = 120.0, -84.0, -60.0
V1, V2, V3, V4 = -1.2, 18.0, 10.0, 14.5
p = (; I, g_Ca, g_K, g_L, V_Ca, V_K, V_L, V1, V2, V3, V4, ϕ= 0.04,
     t_impulse=20.0, ϵ=0, A=0.0, b=0)

##
@info "Rendering figure... "
u_range=-80.0:5.0:50.0
w_range=-0.5:0.1:1.5

fig = Figure(size=(1200, 900))
sl_x = Slider(fig[2,1][2, 1], range = u_range, startvalue = -60)
sl_y = Slider(fig[2,1][1, 2], range = w_range, horizontal = false, startvalue = 0)

ax1 = Axis(fig[1, 1], xlabel="Time", ylabel="Value", title="Morris Lecar Model")
ax2 = Axis(fig[2, 1][1,1], xlabel="u", ylabel="w", title="Phase plane",)
panel = fig[2,1][1, 3]

sg = SliderGrid(
    panel[1,1],
    (label = "I_ext", range = 0:0.5:100, format = "{:.1f}", startvalue = 0),
    (label = "V1", range = -10:0.05:20, format = "{:.1f} nA", startvalue = -1.2),
    (label = "V3", range = -10:0.05:20, format = "{:.1f} nS", startvalue = 10),
    (label = "A", range = 0:0.05:200, format = "{:.1f} nS", startvalue = 0),
    width = 350,
    tellheight = false)
    # I = 0.0:0.1:1.2, u0 = -2.5:0.1:1.5, w0 = -2.5:0.1:1.5,
    # b0=0.1:0.1:2, b1=0.1:0.1:2, A= 0:0.05:2.0


button_state = Observable(false)
button_color = :lightblue
button = panel[2, 1] = Button(fig, label = "Current Impulse", buttoncolor = lift(x->x ? :red : :lightblue, button_state))
on(button.clicks) do n
    global button_state[] = !(button_state[])
    @show "Button state is:" button_state
end

sl_ext, sl_b0, sl_b1, sl_A = sg.sliders
@lift begin 
    p0 = @update p begin
        I = $(sl_ext.value)
        V1 = $(sl_b0.value)
        V3 = $(sl_b1.value)
        A = $(sl_A.value)
        θ = -1
        I_ext = $(sl_ext.value)
        spike_times = Float64[]
        t_impulse = $(button_state) ? 20.0 : -1.0
    end
    u0  = [$(sl_x.value), $(sl_y.value)]
    solution = run_model(p0, u0, morris_lecar!, (0, 300.0), u_range=u_range, w_range=w_range)
    fig = CompNeuro.plot_solution(solution, ax1, ax2)
end
display(fig)

@info "Done rendering figure. Interact with sliders and button to change parameters. Use Ctrl+C to stop."
while true
    sleep(10)
    fig
end
##