
@with_kw struct ModelParams
	n_agents = 10
	discretize_m = 100.
	jump_infect=true
end


@with_kw mutable struct Agent
    id::Int
	last_node::Int
	current_node::Int
	infected = false
	infection_time = -1
	total_route_len = 0.0
end


@with_kw struct VertexMeta
	ix::Int
	enu::ENU
	mapix::Union{Nothing,Int} = nothing
	osmid::Union{Nothing,Int} = nothing
	randomNode= (osmid != nothing)
	agents = Set{Int}()
end

@with_kw struct Simulation
    p::ModelParams
	g::SimpleGraph
	w::SparseMatrixCSC{Float64,Int64}  #edge weights
	vertex_meta::Vector{VertexMeta}
	agents::Vector{Agent}
	m::Union{OpenStreetMapX.MapData, Nothing}
	map_g_connected_points::Vector{Int}
	occupied_vertices::Set{Int}
	infected_agents::Set{Int}
	step_infected_agents_count::Vector{Int}
	step_total_avg_m_driven::Vector{Float64}
		#total number of meters driven by an average car
end

function Simulation(p::ModelParams, m::MapData; store_map::Bool=true)
	map_g_connected_points = sort(LightGraphs.strongly_connected_components(m.g),
	                    lt=(x,y)->length(x)<length(y), rev=true)[1]
	sort!(map_g_connected_points)
	map_g_connected_points_set = Set(map_g_connected_points)
	g = SimpleGraph()
	LightGraphs.add_vertices!(g,length(map_g_connected_points))
	vertex_meta = Vector{VertexMeta}(undef,length(map_g_connected_points))
	for i in 1:length(vertex_meta)
	    vertex_meta[i] = VertexMeta(;ix=i,
	        enu=m.nodes[m.n[map_g_connected_points[i]]],
	        mapix=map_g_connected_points[i],
	        osmid=m.n[map_g_connected_points[i]])
	end
	visited = Set{Pair{Int,Int}}() #used to not inlude bidirect edges

	wd = Dict{Tuple{Int,Int},Float64}() #edge weights as dict

	for e in edges(m.g)
	    (!(e.src in map_g_connected_points_set) || !(e.dst in map_g_connected_points_set)) && continue;
	    edgepair = Pair{Int,Int}(sort!([e.src, e.dst])...)
	    edgepair in visited && continue;
	    push!(visited, edgepair)
	    srcix = searchsortedfirst(map_g_connected_points,e.src)
	    dstix = searchsortedfirst(map_g_connected_points,e.dst)
	    d = distance(vertex_meta[srcix].enu,vertex_meta[dstix].enu)
	    add_vxs = max(0 , Int(ceil(d/p.discretize_m)-1) )
		piece_d = d/(add_vxs+1)
	    local lastix = srcix
	    for piece in 1:add_vxs
	        LightGraphs.add_vertex!(g)
	        local ix = nv(g)
	        LightGraphs.add_edge!(g, lastix, ix)
			wd[(lastix, ix)] = piece_d
	        lastix = ix
	        push!(vertex_meta,
	            VertexMeta(;ix=ix,
	                enu=enu_weighted(vertex_meta[srcix].enu,
	                               vertex_meta[dstix].enu,
	                               piece/(add_vxs+1) ))
	            )
	    end
	    LightGraphs.add_edge!(g, lastix, dstix)
		wd[(lastix, dstix)] = piece_d
	end
	w = SparseArrays.spzeros(length(vertex_meta),length(vertex_meta))

	for k in keys(wd)
		w[k[1], k[2]] = w[k[2], k[1]] = wd[k]
	end

	Simulation(	p=p, g=g, w=w, vertex_meta=vertex_meta,
	 			agents=Vector{Agent}(undef, p.n_agents),
				m=( store_map ? m : nothing ),
				map_g_connected_points=map_g_connected_points,
				occupied_vertices = Set{Int}(),
				infected_agents = Set{Int}(),
				step_infected_agents_count = Vector{Int}(),
				step_total_avg_m_driven = Vector{Float64}() )
end

function init!(s::Simulation; spawn_point::AbstractVector{Int} = 1:nv(s.g))
	empty!(s.occupied_vertices)
	empty!(s.infected_agents)
	empty!(s.step_infected_agents_count)
	empty!(s.step_total_avg_m_driven)
	for vm in s.vertex_meta
		empty!(vm.agents)
	end
	for i in 1:s.p.n_agents
		a = Agent(id=i,current_node=rand(spawn_point),last_node=-1)
		s.agents[i] = a
		push!(s.vertex_meta[a.current_node].agents, a.id)
		push!(s.occupied_vertices,a.current_node)
	end
	for aid in s.vertex_meta[s.agents[end].current_node].agents
		s.agents[aid].infected = true
		s.agents[aid].infection_time = 1
		push!(s.infected_agents, aid)
	end
	push!(s.step_infected_agents_count, length(s.infected_agents))
	push!(s.step_total_avg_m_driven, 0)
end



function enu_weighted(enu1::ENU, enu2::ENU, weight_perc::Float64)::ENU
	return ENU(enu1.east*(1-weight_perc) 	+ enu2.east*weight_perc,
		enu1.north*(1-weight_perc) 	+ enu2.north*weight_perc,
		enu1.up*(1-weight_perc) 	+ enu2.up*weight_perc)
end


function step!(s::Simulation)
	infected_nodes =  Set{Int}()
	from_infected_node_targets = Dict{Int, Set{Int}}()

	for node in s.occupied_vertices
		empty!(s.vertex_meta[node].agents)
	end
	empty!(s.occupied_vertices)
	for agent in s.agents
		vm = s.vertex_meta[agent.current_node]
		local nextnode::Int
		ns = LightGraphs.neighbors(s.g,agent.current_node)
		if vm.randomNode
			nextnode = rand(ns)
		else
			if agent.last_node!=ns[1]
				nextnode = ns[1]
			else
				nextnode = ns[2]
			end
		end

		agent.last_node = agent.current_node
		agent.current_node = nextnode
		agent.total_route_len += s.w[agent.last_node, agent.current_node]
		if agent.infected
			push!(infected_nodes, agent.current_node)
			if (s.p.jump_infect)
				push!(get!(from_infected_node_targets, agent.last_node, Set{Int}()), agent.current_node)
			end
		end
		push!(s.occupied_vertices, agent.current_node)
		push!(s.vertex_meta[agent.current_node].agents, agent.id)
	end
	if (s.p.jump_infect)
		for agent in s.agents
			if (!agent.infected) &&
					haskey(from_infected_node_targets, agent.current_node)
				# check if the agent just jumped over another infected agents
				if agent.last_node in from_infected_node_targets[agent.current_node]
					# the agent and all oter at the new node will get infected
					push!(infected_nodes, agent.current_node)
				end
			end
		end
	end

	step_no = length(s.step_infected_agents_count)+1
	for node in infected_nodes
		for aid in s.vertex_meta[node].agents
			if !s.agents[aid].infected
				s.agents[aid].infected = true
				s.agents[aid].infection_time = step_no
				push!(s.infected_agents, aid)
			end
		end
	end
	push!(s.step_infected_agents_count, length(s.infected_agents))
	push!(s.step_total_avg_m_driven,
		sum(a.total_route_len for a in s.agents)/length(s.agents))
end

function simulate_steps!(s::Simulation; max_idle=500)
	steps_without_change = 0
	last_infected_count = 0
	while (infected_count = length(s.infected_agents)) < length(s.agents)
		step!(s)
		if last_infected_count == infected_count
			steps_without_change += 1
			steps_without_change >= max_idle && break;
		else
			steps_without_change = 0
			last_infected_count = infected_count
		end
	end
end
