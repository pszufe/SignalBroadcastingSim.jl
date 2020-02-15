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
using StructArrays
using CSV
m = OpenStreetMapX.get_map_data("maps", "torontoF.osm")
for discretize_m in [25., 50., 75.]
    p = ModelParams(discretize_m=discretize_m)
    s = Simulation(p,m)

    df = DataFrame(ix=Int[], latitude=Float64[],longitude=Float64[], OSM_nodeid=Union{Int,Nothing}[],random_node=Bool[],neighbors=String[])

    for v in s.vertex_meta
        lla = LLA(v.enu, s.m.bounds)
        push!(df, Dict( :ix => v.ix,:latitude=>lla.lat, :longitude => lla.lon, :OSM_nodeid => v.osmid, :random_node => v.randomNode, :neighbors => string(neighbors(s.g, v.ix))  ))
    end

    CSV.write("export_toronto_graph_d$(discretize_m)m.csv", df)

    dfe = DataFrame(vertex1=Int[], vertex2=Int[], distance_in_meters=Float64[])
    for e in edges(s.g)
        push!(dfe, (e.src, e.dst, s.w[e.src, e.dst]))
    end
    CSV.write("export_toronto_distances_d$(discretize_m)m.csv", dfe)
end

Random.seed!(20)
p = ModelParams(n_agents=200, discretize_m=50)
s = Simulation(p,m)
init!(s)
for i in 1:100
    SignalBroadcastingSim.step!(s)
end
SignalBroadcastingSim.plot_sim(s, "sample_200agents_discretize50m_after100steps.html")
