

function latlon(s::Simulation,map_g_point_id::Int64)
	osm_node_ix = s.m.n[map_g_point_id]
	lla = LLA(s.m.nodes[osm_node_ix], s.m.bounds)
    return (lla.lat, lla.lon)
end

function plot_sim(s::Simulation, filename::AbstractString; agentIds=1:min(1000,length(s.agents)), tiles="Stamen Toner" )
	MAP_BOUNDS = [( s.m.bounds.min_y, s.m.bounds.min_x),( s.m.bounds.max_y, s.m.bounds.max_x)]
	map_size = (abs(MAP_BOUNDS[1][1]-MAP_BOUNDS[2][1]), abs(MAP_BOUNDS[1][2]-MAP_BOUNDS[2][2]))
	MAP_BOUNDSx9 = [ (MAP_BOUNDS[1][1]-map_size[1], MAP_BOUNDS[1][2]-map_size[1]),
					 (MAP_BOUNDS[2][1]+map_size[1], MAP_BOUNDS[2][2]+map_size[1])]



    flm = pyimport("folium")
    matplotlib_cm = pyimport("matplotlib.cm")
    matplotlib_colors = pyimport("matplotlib.colors")
    cmap = matplotlib_cm.get_cmap("prism")
    m_plot = flm.Map(tiles=tiles)

	map_g_connected_points_set = Set(s.map_g_connected_points)
    for e in edges(s.m.g)
	    (!(e.src in map_g_connected_points_set) || !(e.dst in map_g_connected_points_set)) && continue;
		flm.PolyLine( 	(latlon(s,e.src), latlon(s,e.dst)),
						color="brown", weight=4, opacity=1).add_to(m_plot)
	end

    for vm in s.vertex_meta
		lla = LLA(vm.enu,s.m.bounds)
        info = 	(vm.randomNode ? "<b>Random node</b>\n<br>(agent randomly chooses next edge here)\n<br> OSM id: $(vm.osmid)" : "<b>Deterministic node</b><br>\n(added artificially in the discretization process, agent continous in the same direction)") *
			"\n<br>Node: $(vm.ix)\n<br>Lattitude: $(lla.lat)\n<br>Longitude: $(lla.lon) "
        flm.Circle(
			(lla.lat, lla.lon),
			popup=info,
			tooltip=info,
			radius=10,
			color=(vm.randomNode ? "orange" : "yellow"),
			weight=3,
			fill=true,
			fill_color=(vm.randomNode ? "orange" : "yellow")
      	).add_to(m_plot)
    end

	jitter = 0.5e-4

    for agent in s.agents
		lla = LLA(s.vertex_meta[agent.current_node].enu,s.m.bounds)
        info = "Agent: $(agent.id)\n<br>Infected: " *
			(agent.infected ? "YES" : "NO")*
			"\n<br>Current node: $(agent.current_node)"*
			"\n<br>Previous node: $(agent.last_node)"*
			"\n<br>Total distance travelled so far $(round(Int,agent.total_route_len))m"
		loc = (lla.lat+jitter*randn(), lla.lon+jitter*randn())

        flm.Rectangle(
			[(loc[1]-0.00014, loc[2]-0.0002), (loc[1]+0.00014, loc[2]+0.0002)],
			popup=info,
			tooltip=info,
			color=(agent.infected ? "green" : "red"),
			weight=6,
			fill=true,
			fill_color=(agent.infected ? "green" : "red")
		).add_to(m_plot)
    end

    MAP_BOUNDS = [( s.m.bounds.min_y, s.m.bounds.min_x),( s.m.bounds.max_y, s.m.bounds.max_x)]
    flm.Rectangle(MAP_BOUNDS, color="black",weight=4).add_to(m_plot)
    m_plot.fit_bounds(MAP_BOUNDS)
    m_plot.save(filename)
end
