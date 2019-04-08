#
# This file is a part of MolecularGraph.jl
# Licensed under the MIT License http://opensource.org/licenses/MIT
#

@testset "graph.clique" begin

@testset "maxclique" begin
    nullg = vectorgraph(Node, Edge)
    @test issetequal(maxclique(nullg), [])

    noedges = vectorgraph(5, Tuple{Int,Int}[])
    @test length(maxclique(noedges)) == 1

    g1 = cyclegraph(5)
    @test length(maxclique(g1)) == 2

    g2 = vectorgraph(5, [(1, 2), (2, 3), (3, 1), (3, 4), (4, 5)])
    @test issetequal(maxclique(g2), [1, 2, 3])

    g3 = vectorgraph(
        5, [(1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4), (4, 5)])
    @test issetequal(maxclique(g3), [1, 2, 3, 4])
end

end # graph.clique
