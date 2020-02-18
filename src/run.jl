function resize_filllast!(v::Vector, n::Integer)
    vlen = length(v)
    (n <= vlen) && return resize!(v, n)
    resize!(v, n)
    (@view v[(vlen+1):end]) .= Ref(v[vlen])
    v
end

function simulate_all!(s0::Simulation; reps=30, max_idle=500)::NamedTuple{(:stepstats, :endstats),Tuple{DataFrame,DataFrame}}
    statefile = tempname()
    println(statefile)
    serialize(statefile, s0)
    res_infected_count = Vector{Vector{Int}}(undef, reps)
    res_m = Vector{Vector{Float64}}(undef, reps)
    worker_ids = Vector{Int}(undef, reps)
    #ss = [deepcopy(s0) for i in 1:Threads.nthreads()]
    #Threads.@threads for rep in 1:reps
    rrs = @distributed (append!) for rep in 1:reps
        local s = deserialize(statefile)
        Random.seed!(rep);
        init!(s)
        simulate_steps!(s; max_idle = max_idle)
        r_inf_count = copy(s.step_infected_agents_count)
        r_m = copy(s.step_total_avg_m_driven)
        [(rep=rep, r_inf_count=r_inf_count, r_m=r_m, worker_id=myid())]
    end
    for rr in rrs
        res_infected_count[rr.rep] = rr.r_inf_count
        res_m[rr.rep] = rr.r_m
        worker_ids[rr.rep] = rr.worker_id
    end
    dfend = DataFrame(rep_no=Int[],steps=Int[],total_m_driven=Float64[],
        median_step=Int[],
        left_tail_sum=Float64[],
        right_tail_sum=Float64[],
        n_agents=Int[], discretize_m=Float64[] ,jump=Bool[],
        g_nodes=Int[], g_edges=Int[],worker_id=Int[])
    half_agents = ceil(Int, s0.p.n_agents/2)
    for rep in 1:reps
        med = findfirst(>=(half_agents), res_infected_count[rep])
        steps_no = length(res_infected_count[rep])
        push!(dfend,(rep, steps_no, res_m[rep][end],
            med,
            sum(res_infected_count[rep][1:med])/s0.p.n_agents,
            steps_no-med+1-sum(res_infected_count[rep][med:steps_no])/s0.p.n_agents,
            s0.p.n_agents, s0.p.discretize_m, s0.p.jump_infect,
            nv(s0.g), ne(s0.g), worker_ids[rep] ))
    end

    maxlen = maximum(length.(res_infected_count))
    resize_filllast!.(res_infected_count,maxlen)
    resize_filllast!.(res_m,maxlen)
    df = DataFrame(step=Int[],total_avg_m_driven=Float64[],
        reps=Int[],infected_avg=Float64[],
        infected_std=Float64[],infected_lo=Float64[],infected_hi=Float64[],
        infected_q05=Float64[],infected_q95=Float64[],
        infected_median=Float64[],
        n_agents=Int[], discretize_m=Float64[] ,jump=Bool[],
        g_nodes=Int[], g_edges=Int[])


    for step in 1:maxlen
        data_for_step = getindex.(res_infected_count,step)
        data_for_meters = getindex.(res_m,step)
        stats = OneSampleTTest(data_for_step)
        conf_interv = confint(stats)
        meanv = mean(data_for_step)
        push!(df,(step,mean(data_for_meters),reps,meanv,std(data_for_step; mean=meanv),
            max(0,conf_interv[1]), min(conf_interv[2],s0.p.n_agents),
            quantile(data_for_step,0.05), quantile(data_for_step,0.95),
            median(data_for_step),
            s0.p.n_agents, s0.p.discretize_m, s0.p.jump_infect,
            nv(s0.g), ne(s0.g)))
    end
    (stepstats=df, endstats=dfend)
end
