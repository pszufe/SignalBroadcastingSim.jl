
function get_median_step_infected(df_slice::DataFrame)
    cols = [:pc_infected_avg, :pc_infected_q05, :pc_infected_q95, :pc_infected_lo, :pc_infected_hi]

    res = Pair{Symbol,Int64}[]
    for col in cols
        v = minimum( i -> (abs(0.5 - df_slice[i, col]), df_slice.step[i]), 1:nrow(df_slice))[2]
        push!(res, Symbol(string("step_",col)) => v )
    end
    push!(res, :left_value => 0.0)
    push!(res, :max_step=>maximum(df_slice.step))
    DataFrame(  res...)
end


sigm(x) = exp(x)/(exp(x)+1)

vals = sigm.(-8:0.1:8) #161
med = findfirst(>=(0.5), vals) 
1:med

sum(vals[1:med])
sum(1-vals[i] for i in med:length(vals))
