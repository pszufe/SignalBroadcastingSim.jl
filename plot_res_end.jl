using DataFrames
using CSV
using Plots
using Statistics
using GLM

df_e = CSV.read("zombiecar2_sweep_res5_endfalse.csv");
df_e.pc_median_step = df_e.median_step./df_e.steps
df = aggregate(df_e, [:n_agents, :discretize_m, :jump, :g_nodes, :g_edges], mean)
df.assymetry = df.left_tail_sum_mean./df.right_tail_sum_mean
df.pc_steps_mean = df.median_step_mean ./ df.steps_mean

df.e_sim_time = 2df.g_nodes.*log.(df.n_agents)./df.n_agents
df.log_n_x_n = log.(df.n_agents)./df.n_agents

df.log_agents = log.(df.n_agents)

for d in [50.]
    dfj0 = df[(df.jump.==0) .& (df.discretize_m.==d),:]
    dfj1 = df[(df.jump.==1) .& (df.discretize_m.==d),:]
    for dat in [dfj0]
        println("COR log_n_x_n $(cor(dat.log_n_x_n, dat.steps_mean))")
        println("COR n_agents $(cor(dat.n_agents, dat.steps_mean))")
        println("COR e_sim_time $(cor(dat.e_sim_time, dat.steps_mean))")
        ols = lm(@formula(steps_mean~e_sim_time), dat)
        #display(ols) #coef(ols)
        println("R2=$(r2(ols))")
    end
end

function scatterplot(df, jumps)
    p = Plots.scatter(xlabel = "Simulation steps", ylabel="Theoretical time: 2n log(k)/k", lab="")
    for discretize_m in [50,0]
        for jump in jumps
            dd = df[ (df.discretize_m .== discretize_m) .& (df.jump .== jump), :]
            p = Plots.scatter!(p,dd.steps_mean,dd.e_sim_time,lab="d=$discretize_m j=$jump")
        end
    end
    p
end



function scatterplot2(df, jumps)
    p = Plots.scatter(xlabel = "Simulation steps", ylabel="log(n_agents)", lab="")
    for discretize_m in [50.0]
        for jump in jumps
            dd = df[ (df.discretize_m .== discretize_m) .& (df.jump .== jump), :]
            p = Plots.scatter!(p,dd.steps_mean,log.(dd.n_agents)./dd.n_agents,lab="d=$discretize_m j=$jump")
        end
    end
    p
end


function scatterplot3(df, jumps)
    p = Plots.scatter(xlabel = "n_agents", ylabel="% of simulation steps where half agents are infeteted", lab="", legend=:bottomright)
    for discretize_m in [50]
        for jump in jumps
            dd = df[ (df.discretize_m .== discretize_m) .& (df.jump .== jump), :]
            p = Plots.scatter!(p,dd.n_agents,dd.pc_steps_mean,lab="d=$discretize_m j=$jump")
        end
    end
    p
end


function scatterplot4(df, jumps)
    p = Plots.scatter(xlabel = "n_agents", ylabel="Assymetry - (left tail)/(1 - right tail)", lab="", legend=:bottomright)
    for discretize_m in [50]
        for jump in jumps
            dd = df[ (df.discretize_m .== discretize_m) .& (df.jump .== jump), :]
            p = Plots.scatter!(p,dd.n_agents,dd.assymetry,lab="d=$discretize_m j=$jump")
        end
    end
    p
end





p=scatterplot3(df[df.n_agents .< 100_000, :], 0)


savefig(p, "Steps_to_get_halfagents_infected.png")
p=scatterplot3(df[df.n_agents .<= 1000, :], 0)

savefig(p, "Steps_to_get_halfagents_infected_up_t0_1000_agents.png")


p=scatterplot4(df[df.n_agents .< 100_000, :], 0)
savefig(p, "Assymetry.png")
p=scatterplot4(df[df.n_agents .<= 1000, :], 0)
savefig(p, "Assymetry_up_t0_1000_agents.png")



p=scatterplot(df, 0)

p=scatterplot2(df, 0)


p=scatterplot(df, 1)
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

p = scatter(df.n_agents, df.steps_mean; xlab="n_agents", ylab="expected number of steps for all infeceted", lab="")
savefig(p, "Agents_vs_all_infected_time.png")

p = scatter(log.(df.n_agents), log.(df.steps_mean); xlab="log(n_agents)", ylab="log(expected number of steps for all infeceted)", lab="")
savefig(p, "Log_Agents_vs_all_Log_infected_time.png")
