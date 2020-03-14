using DataFrames
using CSV
using Plots
using Statistics
using GLM

using Latexify






df_e = CSV.read("zombiecar2_sweep_res5_endtrue.csv");
df_e.pc_median_step = df_e.median_step./df_e.steps
df = aggregate(df_e, [:n_agents, :discretize_m, :jump, :g_nodes, :g_edges], mean)
df.assymetry = df.left_tail_sum_mean./df.right_tail_sum_mean
df.pc_steps_mean = df.median_step_mean ./ df.steps_mean

df.e_sim_time = 2df.g_nodes.*log.(df.n_agents)./df.n_agents
df.log_n_x_n = log.(df.n_agents)./df.n_agents

df.log_agents = log.(df.n_agents)


r = DataFrame(discretization=Int[],jump=String[], R2=Float64[])
for d in [25., 50., 75.]
    for jj in [false, true]
        dat = df[(df.jump.==jj) .& (df.discretize_m.==d),:]
        println("COR log_n_x_n $(cor(dat.log_n_x_n, dat.steps_mean))")
        println("COR n_agents $(cor(dat.n_agents, dat.steps_mean))")
        println("COR e_sim_time $(cor(dat.e_sim_time, dat.steps_mean))")
        ols = lm(@formula(steps_mean~e_sim_time), dat)
        #display(ols) #coef(ols)
        println("R2=$(r2(ols))")
        push!(r,(d,(jj ? "Y" : "N"),round(cor(dat.log_n_x_n, dat.steps_mean),digits=6) ))
    end
end
println(latexify(r, env=:table))


r = DataFrame(jump=String[], R2=Float64[])
jj = false
for jj in [false, true]
    dat = df[(df.jump.==1) ,:]
    println("COR log_n_x_n $(cor(dat.log_n_x_n, dat.steps_mean))")
    println("COR n_agents $(cor(dat.n_agents, dat.steps_mean))")
    println("COR e_sim_time $(cor(dat.e_sim_time, dat.steps_mean))")
    ols = lm(@formula(steps_mean~e_sim_time), dat)
    #display(ols) #coef(ols)
    println("R2=$(r2(ols))")
    push!(r,((jj ? "Y" : "N"),round(cor(dat.e_sim_time, dat.steps_mean),digits=6) ))
end
println(latexify(r, env=:table))


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

function scatterplot(df, jumps=[true,false])
    p = Plots.scatter(xlabel = "Steps requred to deliver message to all participants",
        lab="", legend=:bottomright, size=(320,310))
    ylabel!(p, "Theoretical time: \$n \\ln k/k\$")
    shps=Dict(true=>:cross, false=>:star5)
    colrs=Dict(true=>:blue, false=>:red)
    for jj in jumps
        dd = df[(df.jump .== jj), :]
        p = Plots.scatter!(p,dd.steps_mean,dd.e_sim_time,
            markershape=shps[jj],
            markerstrokecolor=colrs[jj],
            lab="Jump-over = $(jj ? "Yes" : "No" )")
    end
    p
end

Plots.pgfplotsx()

fig = scatterplot(df[ df.n_agents .> 1, :])
savefig(fig, "../5d63f3b5c3791641ba87e19f/jump_yes_vs_no.pdf")

function scatterplot2(df)
    p = Plots.scatter(
        xlabel="Number of agents --- \$k\$", lab="", legend=:topright,
        size=(500,400))
    ylabel!(p, "Steps requred to deliver message to all participants")
    lcls=Dict(25=>:green, 50=>:blue, 75=>:red)
    shps=Dict(true=>:cross, false=>:star5)
    for discretize_m in [25, 50, 75]
        for jj in [true,false]
            dd = df[ (df.discretize_m .== discretize_m) .& (df.jump .== jj), :]
            p = Plots.scatter!(p,dd.n_agents, dd.steps_mean,
                markershape=shps[jj],
                markerstrokecolor=lcls[discretize_m],
                lab="Distance=$(discretize_m)m \\ \\ \\ \\ \\ Jump-over=$(jj ? "Yes" : "No" )")
        end
    end
    p
end

Plots.pgfplotsx()

fig = scatterplot2(df[ df.n_agents .> 40 , :])
savefig(fig, "../5d63f3b5c3791641ba87e19f/number_of_agents_vs_steps_min_agent70.pdf")



function scatterplot2logk(df)
    p = Plots.scatter(xlabel = "Steps requred to deliver message to all participants",
        ylabel=raw"$\ln k/k$", lab="", legend=:bottomright, size=(400,300))
    lcls=Dict(25=>:green, 50=>:blue, 75=>:red)
    shps=Dict(true=>:cross, false=>:star5)
    for discretize_m in [25, 50, 75]
        for jj in [true,false]
            dd = df[ (df.discretize_m .== discretize_m) .& (df.jump .== jj), :]
            p = Plots.scatter!(p,dd.steps_mean,log.(dd.n_agents)./dd.n_agents,
                markershape=shps[jj],
                markerstrokecolor=lcls[discretize_m],
                lab="Discr.=$(discretize_m), \\textit{Jump-over=$(jj ? "Yes" : "No" )}")
        end
    end
    p
end

Plots.pgfplotsx();
fig = scatterplot2logk(df[ df.n_agents .> 1, :]);
savefig(fig, "../5d63f3b5c3791641ba87e19f/scatterplotlogk_over_k.pdf")

function scatterplot_assy_median(df, jumps=[true,false])
    p = Plots.scatter(
        xlabel=raw"Number of agents --- $k$", lab="", legend=:bottomright,
        size=(400,400))
    ylabel!(p, "Percentage of simulation steps where half agents have received the message")
    lcls=Dict(25=>:green, 50=>:blue, 75=>:red)
    shps=Dict(true=>:cross, false=>:star5)
    for discretize_m in [25,50,75]
        for jj in jumps
            dd = df[ (df.discretize_m .== discretize_m) .& (df.jump .== jj), :]
            Plots.scatter!(p,dd.n_agents,dd.pc_steps_mean,
                markershape=shps[jj],
                markerstrokecolor=lcls[discretize_m],
                lab="Distance=$(discretize_m)m, Jump-over: $(jj ? "Yes" : "No" )")
        end
    end
    p
end

Plots.pgfplotsx()
fig = scatterplot_assy_median(df[ df.n_agents .> 1, :])
savefig(fig, "../5d63f3b5c3791641ba87e19f/scatterplot_assy_median.pdf")


function scatter_assymetry_left_right(df, jumps=[true, false])
    p = Plots.scatter(
        xlabel="Number of agents --- \$k\$", lab="", legend=:bottomright,
        size=(400,300))
    ylabel!(p, raw"Assymetry = $ left\_tail / upper\_right\_tail $")
    lcls=Dict(25=>:green, 50=>:blue, 75=>:red)
    shps=Dict(true=>:cross, false=>:star5)
    for discretize_m in [25,50,75]
        for jj in jumps
            dd = df[ (df.discretize_m .== discretize_m) .& (df.jump .== jj), :]
            Plots.scatter!(p,dd.n_agents,dd.assymetry,
                markershape=shps[jj],
                markerstrokecolor=lcls[discretize_m],
                lab="Distance=$(discretize_m)m, Jump-over: $(jj ? "Yes" : "No" )")
        end
    end
    p
end


fig = scatter_assymetry_left_right(df[ df.n_agents .> 1, :])
savefig(fig, "../5d63f3b5c3791641ba87e19f/scatter_assymetry_left_right.pdf")



function scatter_assymetry_both_median_left_right(df)
    p = Plots.scatter(
        xlabel="Percentage of simulation steps where half agents have received the message", lab="", legend=:bottomright)
    ylabel!(p, raw"Assymetry = $ left\_tail / upper\_right\_tail $")
    shps=Dict(25=>:circle, 50=>:rect, 75=>:diamond)

    for discretize_m in [25,50,75]
        jj = true
        dd = df[ (df.discretize_m .== discretize_m) .& (df.jump .== jj), :]
        Plots.scatter!(p, dd.pc_steps_mean[1:1],dd.assymetry[1:1],
            lab="Distance=$(discretize_m)m, Jump-over: $(jj ? "Yes" : "No" )",
            markershape=shps[discretize_m], color=:black )
    end

    for discretize_m in [25,50,75]
        for jj in [true]
            dd = df[ (df.discretize_m .== discretize_m) .& (df.jump .== jj), :]

            Plots.scatter!(p,dd.pc_steps_mean,dd.assymetry,
                markershape=shps[discretize_m],
                zcolor=log.(dd.n_agents), palette=:balance,
                markerstrokecolor=nothing,
                lab="")

        end
    end
    p
end

fig = scatter_assymetry_both_median_left_right(df[ df.n_agents .> 1, :])
savefig2(fig, "../5d63f3b5c3791641ba87e19f/scatter_assymetry_both_median_left_right_pdf.pdf", replace_y_lab_pos="-0.028,0.5")



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
    p = Plots.plot(;xlabel = "Simulation steps", ylabel="Share of agent who received the message", ylim=(0.0,1.1), legend=:bottomright)
    for i in 1:length(kw_list)
        plot_res!(p, ds[i], cols[i], labs[i])
    end
    filename!=nothing && savefig(p, filename)
    p
end
