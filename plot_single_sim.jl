using Pkg
Pkg.activate(".")
using SignalBroadcastingSim
using Random
using OpenStreetMapX
using DelimitedFiles, CSV
using LightGraphs
using DataFrames
using Statistics
using CSV
using Plots

m = OpenStreetMapX.get_map_data("maps", "torontoF.osm")

p = ModelParams(n_agents=0, discretize_m=50)
s = Simulation(p,m)
SignalBroadcastingSim.plot_sim(s, "road_network.html")

Random.seed!(20)
p = ModelParams(n_agents=500, discretize_m=50)
s = Simulation(p,m)
init!(s)
for i in 1:100
    SignalBroadcastingSim.step!(s)
end
#SignalBroadcastingSim.
plot_sim(s, "sample_200agents_discretize50m_after100steps.html")

Random.seed!(20)
p = ModelParams(n_agents=10000, discretize_m=50)
s = Simulation(p,m)
init!(s)
SignalBroadcastingSim.simulate_steps!(s;max_idle=50000)

steps = length(s.step_infected_agents_count)

pgfplotsx()

plt = plot(lab="", xlim=[0,100],
    legend=:bottomright,
    xlabel = "Simulation step number",
    ylabel="Percentage of agents that received the message" )

median_x = findfirst(>=(0.5), s.step_infected_agents_count./p.n_agents)
plot!(plt, 1:steps,s.step_infected_agents_count./p.n_agents,
    lab="Agents that received the message", color=:blue)

bar!(1:(median_x-1),(s.step_infected_agents_count./p.n_agents)[1:median_x-1],color=:blue,linecolor=nothing, lab="", fillalpha=0.1)
bar!(median_x:steps,ones(steps-median_x+1),color=:red,linecolor=nothing, lab="",fillalpha=0.1)
bar!(median_x:steps,(s.step_infected_agents_count./p.n_agents)[median_x:steps],color=:white,linecolor=:white, lab="")

plot!(plt, 1:steps,s.step_infected_agents_count./p.n_agents,lab="", color=:blue)


annotate!(plt, median_x+24, 0.5, text("Median value (here it is at the step $median_x)", 10, :black))

annotate!(plt, median_x*0.6, 0.1, text("Left tail", 8, :blue))

annotate!(plt, median_x*1.1, .9, text("Upper part of the right tail", 8, :red))

scatter!(plt, [median_x-0.75], [0.5],
    markershape=:star5,
    markerstrokecolor=:black,
lab="")

function savefig2(plot,filename; twidth=raw"\columnwidth", replace_y_lab_pos=nothing)
    savefig(plot,filename)
    dat = read(filename, String)
    open(filename, "w") do f
        println(f,raw"\resizebox{"*twidth*"}{!}{%")
        if replace_y_lab_pos != nothing
            dat = replace(dat, "ylabel style={"=>"ylabel style={at={(axis description cs:$(replace_y_lab_pos))}")
        end

        println(f, dat)
        println(f,raw"}")
    end
end

savefig2(plt,"../5d63f3b5c3791641ba87e19f/sample_simulation_run.tex";twidth=raw"0.9\columnwidth")



plt = plot(lab="", xlim=[0,100],
    legend=:bottomright,
    xlabel = "Simulation step number",
    ylabel="Number of agents that received the message",
    size=(400,300) );

plot!(plt, 1:steps,s.step_infected_agents_count,
    lab="Agents that received the message", color=:blue);


savefig(plt,"../5d63f3b5c3791641ba87e19f/sample_simulation_run_simple.pdf")
