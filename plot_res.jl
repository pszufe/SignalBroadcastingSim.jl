using DataFrames
using CSV
using Plots
using Statistics
using GLM

dfs = CSV.read("zombiecar2_sweep_res5_steptrue.csv");


for c in [:infected_avg, :infected_std, :infected_lo, :infected_hi,
            :infected_median, :infected_q05, :infected_q95 ]
    dfs[!, Symbol(string("pc_",c))] = dfs[!, c] ./ dfs.n_agents
end

# log(steps) = 2g_nodes*log(n_agents)/n_agents

dfs.e_sim_time = 2dfs.g_nodes.*log.(dfs.n_agents)./dfs.n_agents
dfs.log_n_x_n = log.(dfs.n_agents)./dfs.n_agents


function get_slice(dfs::DataFrame; n_agents=500, discretize_m=50.0, jump=0)
    dfs[ (dfs.n_agents.==n_agents) .& (dfs.discretize_m .== discretize_m) .& (dfs.jump .== jump), :]
end

function plot_res!(p, d, color, lab)
    Plots.plot!(p, d.step, d.pc_infected_avg; linestyle=:solid, lab=lab, color=color)
    Plots.plot!(p, d.step, d.pc_infected_q05; linestyle=:dash, lab="", color=color)
    Plots.plot!(p, d.step, d.pc_infected_q95; linestyle=:dash, lab="", color=color)
end


function plot_sim_res(dfs::DataFrame,
        kw_list::Vector{NamedTuple{(:n_agents, :discretize_m, :jump),Tuple{Int64,Float64,Int64}}})

    ds = [get_slice(dfs; kw...) for kw in kw_list]
    for i in 1:length(kw_list)
        @assert nrow(ds[i]) > 0 "ERRROR no rows found for $(string(kw_list[i]))"
    end
    labs = ["k=$(kw.n_agents), Jump-over=$(kw.jump==1 ? "Yes" : "No"), discretization=$(round(Int, kw.discretize_m))m" for kw in kw_list]
    ordering = sortperm(ds; lt = (x,y) -> x.step[end] < y.step[end] )
    ds = ds[ordering]
    labs = labs[ordering]

    ncolor = max(length(kw_list),2)
    cols = reshape( range(colorant"blue", stop=colorant"red",length=ncolor), 1, ncolor );
    p = Plots.plot(;xlabel = "Simulation steps", ylabel="Share of agents who received the message", ylim=(0.0,1.1),
        legend=:bottomright, size=(500,300))

    for i in 1:length(labs)
        plot!(p,[0],[0],color=cols[i], lab=labs[i])
    end
    for i in 1:length(kw_list)
        plot_res!(p, ds[i], cols[i], "")
    end
    p
end

Plots.pgfplotsx()

plt = plot_sim_res(dfs, [
    (n_agents=100, discretize_m=50.0, jump=1 ),
    (n_agents=250, discretize_m=50.0, jump=1 ),
    (n_agents=400, discretize_m=50.0, jump=1 ),
    (n_agents=700, discretize_m=50.0, jump=1 ),
    (n_agents=1000, discretize_m=50.0, jump=1 ),
])
savefig(plt, "../5d63f3b5c3791641ba87e19f/message_prop_med.pdf")


plt = plot_sim_res(dfs, [
    (n_agents=1000, discretize_m=50.0, jump=1 ),
    (n_agents=2000, discretize_m=50.0, jump=1 ),
    (n_agents=5000, discretize_m=50.0, jump=1 ),
    (n_agents=10000, discretize_m=50.0, jump=1 ),
    (n_agents=20000, discretize_m=50.0, jump=1 ),
])
savefig(plt, "../5d63f3b5c3791641ba87e19f/message_prop_high.pdf")
