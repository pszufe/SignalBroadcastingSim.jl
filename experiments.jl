#] add OpenStreetMapX DelimitedFiles CSV LightGraphs DataFrames Statistics Distributions HypothesisTests SparseArrays Serialization Parameters LinearAlgebra StatsBase PyCall Conda
#] precompile

#println("Using $(Threads.nthreads()) threads!")
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

using Distributed
addprocs(Sys.CPU_THREADS)
println("Number of workers $(nworkers())")

@everywhere using Pkg
@everywhere Pkg.activate(".")
@everywhere using SignalBroadcastingSim
@everywhere using Random
@everywhere using OpenStreetMapX
@everywhere using DelimitedFiles, CSV
@everywhere using LightGraphs
@everywhere using DataFrames
@everywhere using Statistics
@everywhere using Distributions, HypothesisTests




m = OpenStreetMapX.get_map_data("maps", "torontoF.osm")
#discretize_m = 25
#p = ModelParams(discretize_m=discretize_m)
#s = Simulation(p,m)

dfstepstats = DataFrame()
dfendstats = DataFrame()
for jump_infect in [false, true]
    for n_agents in vcat(10:30:100, 150:50:200, 250:150:1000, 2000:1000:10000, 12000:2000:20000)
        for discretize_m in [50]
            p = ModelParams(n_agents=n_agents, discretize_m=discretize_m, jump_infect=jump_infect)
            s = Simulation(p,m; store_map = false)
            dump(p)
            simres = simulate_all!(s; reps=40*96, max_idle=50000)
            
			CSV.write("zombiecar2_sweep_res5_step_$(n_agents)_$(jump_infect)_$(discretize_m).csv", simres.stepstats)
			CSV.write("zombiecar2_sweep_res5_end_$(n_agents)_$(jump_infect)_$(discretize_m).csv", simres.endstats)
			append!(dfstepstats, simres.stepstats)
            append!(dfendstats, simres.endstats)
        end
    end
    CSV.write("zombiecar2_sweep_res5_step$(jump_infect).csv", dfstepstats)
    CSV.write("zombiecar2_sweep_res5_end$(jump_infect).csv", dfendstats)
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
