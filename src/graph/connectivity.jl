#
# This file is a part of MolecularGraph.jl
# Licensed under the MIT License http://opensource.org/licenses/MIT
#

export
    connected_components, connected_membership,
    cutvertices, bridges, biconnected_components, biconnected_membership,
    two_edge_connected, two_edge_membership


struct ConnectedComponentState{G<:UndirectedGraph}
    graph::G

    visited::Set{Int}
    remaining::Set{Int}

    components::Vector{Vector{Int}}

    function ConnectedComponentState{G}(graph) where {G<:UndirectedGraph}
        new(graph, Set(), nodeset(graph), [])
    end
end


function dfs!(state::ConnectedComponentState, n)
    push!(state.visited, n)
    for nbr in adjacencies(state.graph, n)
        if !(nbr in state.visited)
            dfs!(state, nbr)
        end
    end
end


function run!(state::ConnectedComponentState)
    while !isempty(state.remaining)
        dfs!(state, pop!(state.remaining))
        push!(state.components, collect(state.visited))
        setdiff!(state.remaining, state.visited)
        empty!(state.visited)
    end
end


"""
    connected_components(graph::UndirectedGraph) -> Vector{Vector{Int}}

Compute connectivity and return sets of the connected components.
"""
@cache function connected_components(graph::UndirectedGraph)
    G = typeof(graph)
    state = ConnectedComponentState{G}(graph)
    run!(state)
    return state.components
end

@cache function connected_membership(graph::UndirectedGraph)
    mem = zeros(Int, nodecount(graph))
    for (i, conn) in enumerate(connected_components(graph))
        for c in conn
            mem[c] = i
        end
    end
    return mem
end


struct BiconnectedState{G<:UndirectedGraph}
    graph::G

    pred::Dict{Int,Int}
    level::Dict{Int,Int}
    low::Dict{Int,Int}
    compbuf::Vector{Int}

    cutvertices::Vector{Int}
    bridges::Vector{Int}
    biconnected::Vector{Vector{Int}}

    function BiconnectedState{G}(graph) where {G<:UndirectedGraph}
        new(graph, Dict(), Dict(), Dict(), [], [], [], [])
    end
end


function dfs!(state::BiconnectedState, depth::Int, n::Int)
    state.level[n] = depth
    state.low[n] = depth
    for (nbr, bond) in neighbors(state.graph, n)
        if n in keys(state.pred) && nbr == state.pred[n]
            continue # predecessor
        elseif !(nbr in keys(state.pred))
            # New node
            state.pred[nbr] = n
            push!(state.compbuf, n)
            dfs!(state, depth + 1, nbr)
            if state.low[nbr] >= state.level[n]
                # Articulation point
                if state.low[nbr] > state.level[n]
                    push!(state.bridges, bond) # except for bridgehead
                end
                push!(state.cutvertices, n)
                push!(state.biconnected, copy(state.compbuf))
                empty!(state.compbuf)
            end
            state.low[n] = min(state.low[n], state.low[nbr])
        else
            # Cycle found
            state.low[n] = min(state.low[n], state.level[nbr])
        end
    end
end


function findbiconnected(
        graph::G, sym::Symbol) where {G<:UndirectedGraph}
    state = BiconnectedState{G}(graph)
    nodes = nodeset(graph)
    while !isempty(nodes)
        dfs!(state, 1, pop!(nodes))
        setdiff!(nodes, keys(state.level))
    end
    if isdefined(graph, :cache)
        graph.cache[:biconnected_components] = state.biconnected
        graph.cache[:cutvertices] = state.cutvertices
        graph.cache[:bridges] = state.bridges
        return graph.cache[sym]
    else
        return getproperty(state, sym)
    end
end


"""
    cutvertices(graph::UndirectedGraph) -> Set{Int}

Compute biconnectivity and return cut vertices (articulation points).
"""
@cache function cutvertices(graph::UndirectedGraph)
    return findbiconnected(graph, :cutvertices)
end


"""
    bridges(graph::UndirectedGraph) -> Set{Int}

Compute biconnectivity and return bridges.
"""
@cache function bridges(graph::UndirectedGraph)
    return findbiconnected(graph, :bridges)
end


"""
    biconnected(graph::UndirectedGraph) -> Vector{Set{Int}}

Compute biconnectivity and return sets of biconnected components.
"""
@cache function biconnected_components(graph::UndirectedGraph)
    return findbiconnected(graph, :biconnected_components)
end


@cache function biconnected_membership(graph::UndirectedGraph)
    mem = zeros(Int, nodecount(graph))
    for (i, conn) in enumerate(biconnected_components(graph))
        for c in conn
            mem[c] = i
        end
    end
    return mem
end


"""
    two_edge_connected(graph::UndirectedGraph) -> Set{Int}

Compute biconnectivity and return sets of the 2-edge connected components.
Isolated nodes will be filtered out.
"""
@cache function two_edge_connected(graph::UndirectedGraph)
    cobr = setdiff(edgeset(graph), bridges(graph))
    comp = connected_components(edgesubgraph(graph, cobr))
    return comp
end


@cache function two_edge_membership(graph::UndirectedGraph)
    mem = zeros(Int, nodecount(graph))
    for (i, conn) in enumerate(two_edge_connected(graph))
        for c in conn
            mem[c] = i
        end
    end
    return mem
end
