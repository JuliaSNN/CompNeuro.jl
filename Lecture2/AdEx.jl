using DrWatson
findproject(@__DIR__) |> quickactivate
using Revise
using Makie, GLMakie
using CompNeuro

## AdEx model
function adex!(du, u, p, t)
    @unpack C, V_L, I_ext, ΔT, θ, a, b,  R, τm, τw = p
    du[1] = 1/τm * (- (u[1] - V_L) + ΔT *exp((u[1] - θ)/ΔT)) + (-u[2] + I_ext)/C
    du[2] = 1/τw *(a*( u[1]- V_L) - u[2])
end

# Reset condition: when V crosses V_th, reset to V_reset
function reset_condition(u, t, integrator) 
    integrator.u[1] > 0
end
function reset_affect!(integrator)
    integrator.u[1] = integrator.p.V_reset
    integrator.u[2] += integrator.p.b
    push!(integrator.p.spike_times, integrator.t)
end
cb = DiscreteCallback(reset_condition, reset_affect!)

# Initial condition
u0 = [-60.0, 10.]  # Initial membrane potential
tspan = (0.0, 400.0)

# Parameters
p = (C=50, 
    V_L=-60.0, 
    V_reset=-60.0, 
    θ=-50.0, 
    ΔT=2.0, 
    a=-4.0, 
    b=7.0, 
    R=0.5, 
    τm=7, 
    τw=150
)

@update! p begin
    I_ext=95.0
    spike_times = Float64[]
    t_impulse=20.0
    ϵ = 20/140
    A=0.0
end

# u0 = [-60f0, 0f0]
# solution = run_model(p, u0, adex!, (0, 300.0), u_range=-80:-40, w_range=-40:100, reset_cb=cb)

##

@info "Rendering figure... "
fig = Figure(size=(1200, 900))
sl_x = Slider(fig[2,1][2, 1], range = -80:0.01:-40, startvalue = -60)
sl_y = Slider(fig[2,1][1, 2], range = -40:0.01:100, horizontal = false, startvalue = 6)
ax1 = Axis(fig[1, 1], xlabel="Time", ylabel="Value", title="AdEx Neuron Model")
ax2 = Axis(fig[2, 1][1,1], xlabel="u", ylabel="w", title="Phase plane",)
panel = fig[2,1][1, 3]

sg = SliderGrid(
    panel[1,1],
    (label = "V reset", range = -70:1:-40, format = "{:.1f}mV", startvalue = -55),
    (label = "b", range = 0:1:100, format = "{:.1f} nA", startvalue = 20),
    (label = "a", range = 0:0.1:20, format = "{:.1f} nS", startvalue = 0),
    (label = "I_ext", range = 0:1:100, format = "{:.1f} nA", startvalue = 0),
    (label = "Impulse", range = 0:1:50, format = "{:.1f} nA", startvalue = 0),
    width = 350,
    tellheight = false)

button_state = Observable(false)
button_color = :lightblue
button = panel[2, 1] = Button(fig, label = "Current Impulse", buttoncolor = lift(x->x ? :red : :lightblue, button_state))

on(button.clicks) do n
    global button_state[] = !(button_state[])
end

sl_vr, sl_b, sl_a, sl_ext, sl_A = sg.sliders
@lift begin 
    p0 = @update p begin
        V_reset = $(sl_vr.value)
        b = $(sl_b.value)
        a = $(sl_a.value)
        A = $(sl_A.value)
        I_ext = $(sl_ext.value)
        spike_times = Float64[]
        t_impulse = $(button_state) ? 20.0 : -1.0
    end
    u0  = [$(sl_x.value), $(sl_y.value)]
    solution = run_model(p0, u0, adex!, (0, 300.0), u_range=-80:-40, w_range=-40:100, reset_cb=cb)
    fig = CompNeuro.plot_solution(solution, ax1, ax2)
end
display(fig)

@info "Done rendering figure. Interact with sliders and button to change parameters. Use Ctrl+C to stop."

# while true
#     sleep(10)
#     fig
# end
##