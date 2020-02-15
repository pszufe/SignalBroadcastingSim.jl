
function create_network_from_file(path::String, mapName::String)::Network
    #map = OpenStreetMapX.parseOSM(joinpath(path,mapName))
    #crop!(map)

    mData = get_map_data(path, mapName, only_intersections = true)
    nw = Network(mData)
    return nw
end
