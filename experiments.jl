println("Using $(Threads.nthreads()) threads!")
#using Revise
using Pkg
Pkg.activate(".")
using SignalBroadcastingSim
using Random
using OpenStreetMapX
using DelimitedFiles, CSV
using LightGraphs
using DataFrames
using Statistics
using Distributions, HypothesisTests


m = OpenStreetMapX.get_map_data("maps", "torontoF.osm")
#discretize_m = 25
#p = ModelParams(discretize_m=discretize_m)
#s = Simulation(p,m)

dfstepstats = DataFrame()
dfendstats = DataFrame()
for n_agents in vcat(10:15:100, 120:20:200, 300:100:1000, 2000:1000:4000)
    for jump_infect in [false, true]
        for discretize_m in [75, 50, 25]
            p = ModelParams(n_agents=n_agents, discretize_m=discretize_m, jump_infect=jump_infect)
            s = Simulation(p,m)
            dump(p)
            simres = simulate_all!(s; reps=40, max_idle=50000)
            append!(dfstepstats, simres.stepstats)
            append!(dfendstats, simres.endstats)
        end
    end
end

CSV.write("zombiecar2_sweep_res4_step.csv", dfstepstats)
CSV.write("zombiecar2_sweep_res4_end.csv", dfendstats)

function doSim(m;jump_infect=true)
    Random.seed!(0);
    p = ModelParams(n_agents=500, discretize_m=75.0, jump_infect=jump_infect)


    s = Simulation(p,m)


    plot_sim(s, "SimStart$jump_infect.html")

    for i in 1:10
        step!(s)
    end
    plot_sim(s, "SimStep$(jump_infect)10.html")
    for i in 11:20
        step!(s)
    end
    plot_sim(s, "SimStep$(jump_infect)20.html")

    for i in 21:100
        step!(s)
    end
    plot_sim(s, "SimStep$(jump_infect)100.html")
    for i in 101:200
        step!(s)
    end
    plot_sim(s, "SimStep$(jump_infect)200.html")
    for i in 201:500
        step!(s)
    end
    plot_sim(s, "SimStep$(jump_infect)500.html")
end

#doSim(m, jump_infect=true)
#doSim(m, jump_infect=false)
