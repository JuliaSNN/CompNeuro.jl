using DrWatson
findproject(@__DIR__) |> quickactivate
using CompNeuro
using GLMakie

function fitzhugh_nagumo!(du, u, p, t)
    u_val, w_val = u
    @unpack I, b0, b1, t_impulse, ϵ, A = p

    du[1] = u_val - (1/3) * u_val^3 - w_val + I  # du/dt
    du[2] = ϵ * (b0 + b1 * u_val - w_val)             # dw/dt

end

p = @update NamedTuple() begin
    I = 0.0  # External current
    b0 = 0.9 # Parameter b
    b1 = 1
    b = 0.0 # Parameter b
    t_impulse = 20.0  # Time of impulse
    ϵ = 0.1  # Width of impulse
    A = .7  # Amplitude of impulse
    θ = 1.0
end

# Initial conditions: [u0, w0]
u0 = [-2.0, -0.5]


##
@info "Rendering figure... "
u_range=-4:4
w_range=-4:4

fig = Figure(size=(1200, 900))
sl_x = Slider(fig[2,1][2, 1], range = u_range, startvalue = -2)
sl_y = Slider(fig[2,1][1, 2], range = w_range, horizontal = false, startvalue = 0)

ax1 = Axis(fig[1, 1], xlabel="Time", ylabel="Value", title="FitzHugh Nagumo Model")
ax2 = Axis(fig[2, 1][1,1], xlabel="u", ylabel="w", title="Phase plane",)
panel = fig[2,1][1, 3]

sg = SliderGrid(
    panel[1,1],
    (label = "I_ext", range = 0:0.1:1.2, format = "{:.1f}", startvalue = 0),
    (label = "b0", range = 0:0.05:2, format = "{:.1f} nA", startvalue = 0.9),
    (label = "b1", range = 0:0.05:2, format = "{:.1f} nS", startvalue = 1),
    (label = "A", range = 0:0.05:2, format = "{:.1f} nS", startvalue = 0),
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
        b0 = $(sl_b0.value)
        b1 = $(sl_b1.value)
        A = $(sl_A.value)
        I_ext = $(sl_ext.value)
        spike_times = Float64[]
        t_impulse = $(button_state) ? 20.0 : -1.0
    end
    u0  = [$(sl_x.value), $(sl_y.value)]
    solution = run_model(p0, u0, fitzhugh_nagumo!, (0, 300.0), u_range=u_range, w_range=w_range)
    fig = CompNeuro.plot_solution(solution, ax1, ax2)
end
display(fig)

@info "Done rendering figure. Interact with sliders and button to change parameters. Use Ctrl+C to stop."

while true
    sleep(10)
    fig
end
##