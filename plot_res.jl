using DataFrames
using CSV
using Plots
using Statistics
using GLM

df = CSV.read("zombiecar2_sweep_res3.csv");


for c in [:infected_avg, :infected_std, :infected_lo, :infected_hi,
            :infected_median, :infected_q05, :infected_q95 ]
    df[!, Symbol(string("pc_",c))] = df[!, c] ./ df.n_agents
end


# log(steps) = 2g_nodes*log(n_agents)/n_agents

df.e_sim_time = 2df.g_nodes.*log.(df.n_agents)./df.n_agents
df.log_n_x_n = log.(df.n_agents)./df.n_agents

resg = DataFrame()
for g in groupby(df,[:discretize_m, :n_agents, :jump])
    push!(resg, g[end, :])
end

for d in [25.,50.,75.]
    resgj0 = resg[(resg.jump.==0) .& (resg.discretize_m.==d),:]
    resgj1 = resg[(resg.jump.==1) .& (resg.discretize_m.==d),:]
    for dat in [resgj0, resgj1]
        ols = lm(@formula(log_n_x_n~step), dat)
        #display(ols) #coef(ols)
        println("R2=$(r2(ols))")
    end
end

function scatterplot(resg, jump)
    p = Plots.scatter(xlabel = "Simulation steps", ylabel="Theoretical time: 2n log(k)/k", lab="")
    for discretize_m in [25.0, 50,0, 75.0]
        for jump in [jump]
            dd = resg[ (resg.discretize_m .== discretize_m) .& (resg.jump .== jump), :]
            p = Plots.scatter!(p,dd.step,dd.e_sim_time,lab="d=$discretize_m j=$jump")
        end
    end
    p
end


CSV.write( "Theoretical_vs_practical_end.csv", resg)

p=scatterplot(resg, 0)
savefig(p, "Theoretical_vs_practical_end_jumpN.png")


p=scatterplot(resg, 1)
savefig(p, "Theoretical_vs_practical_end_jumpY.png")



using Plots
pyplot()
p = Plots.scatter(; lab="")
Plots.scatter!(p, [1], [2]; lab="point 1")
Plots.scatter!(p, [3], [4]; lab="point 2")
Plots.scatter!(p, [5], [6]; lab="point 3")



function get_slice(df::DataFrame; n_agents=500, discretize_m=50.0, jump=0)
    df[ (df.n_agents.==n_agents) .& (df.discretize_m .== discretize_m) .& (df.jump .== jump), :]
end

function plot_res!(p, d, color, lab)
    Plots.plot!(p, d.step, d.pc_infected_avg; linestyle=:solid, lab=lab, color=color)
    Plots.plot!(p, d.step, d.pc_infected_q05; linestyle=:dash, lab="", color=color)
    Plots.plot!(p, d.step, d.pc_infected_q95; linestyle=:dash, lab="", color=color)
end


function plot_sim_res(df::DataFrame,
        kw_list::Vector{NamedTuple{(:n_agents, :discretize_m, :jump),Tuple{Int64,Float64,Int64}}};
        filename::Union{AbstractString,Nothing}=nothing)

    ds = [get_slice(df; kw...) for kw in kw_list]
    for i in 1:length(kw_list)
        @assert nrow(ds[i]) > 0 "ERRROR no rows found for $(string(kw_list[i]))"
    end

    labs = ["n=$(kw.n_agents), j=$(kw.jump==1 ? "Y" : "N"), d=$(round(Int, kw.discretize_m))m" for kw in kw_list]
    ordering = sortperm(ds; lt = (x,y) -> x.step[end] < y.step[end] )
    ds = ds[ordering]
    labs = labs[ordering]

    ncolor = max(length(kw_list),2)
    cols = reshape( range(colorant"blue", stop=colorant"red",length=ncolor), 1, ncolor );
    p = Plots.plot(;xlabel = "Simulation steps", ylabel="Share of infected", ylim=(0.0,1.1), legend=:bottomright)
    for i in 1:length(kw_list)
        plot_res!(p, ds[i], cols[i], labs[i])
    end
    filename!=nothing && savefig(p, filename)
    p
end

plot_sim_res(df, [
    (n_agents=100, discretize_m=50.0, jump=0 ),
    (n_agents=200, discretize_m=50.0, jump=0 ),
    (n_agents=500, discretize_m=50.0, jump=0 ),
    (n_agents=1000, discretize_m=50.0, jump=0 ),
    (n_agents=2000, discretize_m=50.0, jump=0 ),
    (n_agents=3000, discretize_m=50.0, jump=0 ),
    (n_agents=4000, discretize_m=50.0, jump=0 ),
]; filename="change_of_agent_count_no_jumping_infection.png")


plot_sim_res(df, [
    (n_agents=10, discretize_m=50.0, jump=0 ),
    (n_agents=25, discretize_m=50.0, jump=0 ),
    (n_agents=40, discretize_m=50.0, jump=0 ),
    (n_agents=55, discretize_m=50.0, jump=0 ),
]; filename="change_of_agent_count_no_jumping_infection.png")


plot_sim_res(df, [
    (n_agents=4000, discretize_m=50.0, jump=0 ),
]; filename="change_of_agent_count_no_jumping_infection.png")


s = get_slice(df;n_agents=4000, discretize_m=50.0, jump=0 )

get_median_step_infected(s)

plot_sim_res(df, [
    (n_agents=50, discretize_m=50.0, jump=1 ),
    (n_agents=100, discretize_m=50.0, jump=1 ),
    (n_agents=200, discretize_m=50.0, jump=1 ),
    (n_agents=500, discretize_m=50.0, jump=1 ),
    (n_agents=1000, discretize_m=50.0, jump=1 ),
    (n_agents=2000, discretize_m=50.0, jump=1 ),
    (n_agents=3000, discretize_m=50.0, jump=1 ),
]; filename="change_of_agent_count_with_jumping_infection.png")



plot_sim_res(df, [
    (n_agents=500, discretize_m=25.0, jump=0 ),
    (n_agents=500, discretize_m=50.0, jump=0 ),
    (n_agents=500, discretize_m=75.0, jump=0 ),
]; filename="discretization_levels_no_jumping_infection.png")


plot_sim_res(df, [
    (n_agents=500, discretize_m=25.0, jump=1 ),
    (n_agents=500, discretize_m=50.0, jump=1 ),
    (n_agents=500, discretize_m=75.0, jump=1 ),

]; filename="discretization_levels_with_jumping_infection.png")


plot_sim_res(df, [
    (n_agents=1000, discretize_m=50.0, jump=1 ),
    (n_agents=500, discretize_m=50.0, jump=1 ),
    (n_agents=200, discretize_m=50.0, jump=1 ),
    (n_agents=100, discretize_m=50.0, jump=1 ),

    (n_agents=1000, discretize_m=50.0, jump=0 ),
    (n_agents=500, discretize_m=50.0, jump=0 ),
    (n_agents=200, discretize_m=50.0, jump=0 ),

    (n_agents=100, discretize_m=50.0, jump=0 ),

]; filename="jumping_vs_no_jumping.png")


plot_sim_res(df, [
    (n_agents=2000, discretize_m=50.0, jump=1 ),
    (n_agents=2500, discretize_m=50.0, jump=1 ),
    (n_agents=3000, discretize_m=50.0, jump=1 ),
    (n_agents=2000, discretize_m=50.0, jump=0 ),
    (n_agents=2500, discretize_m=50.0, jump=0 ),
    (n_agents=3000, discretize_m=50.0, jump=0 ),
]; filename="high_agent_counts.png")


df = CSV.read("zombiecar2_sweep_small.csv")
for c in [:infected, :infected_std, :infected_lo, :infected_hi, ]
    df[!, Symbol(string("pc_",c))] = df[!, c] ./ df.n_agents
end


for n_agents in 10:10:90
    plot_sim_res(df, [
        (n_agents=n_agents, discretize_m=25.0, jump=1 ),
        (n_agents=n_agents, discretize_m=50.0, jump=1 ),
        (n_agents=n_agents, discretize_m=75.0, jump=1 ),
        (n_agents=n_agents, discretize_m=25.0, jump=0 ),
        (n_agents=n_agents, discretize_m=50.0, jump=0 ),
        (n_agents=n_agents, discretize_m=75.0, jump=0 ),
    ]; filename="small_agent_counts$n_agents.png")
end
