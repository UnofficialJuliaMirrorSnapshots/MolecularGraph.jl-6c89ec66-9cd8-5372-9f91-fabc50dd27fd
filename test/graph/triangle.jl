#
# This file is a part of MolecularGraph.jl
# Licensed under the MIT License http://opensource.org/licenses/MIT
#

@testset "graph.triangle" begin

@testset "triangles" begin
    graph1 = pathgraph(5)
    @test isempty(triangles(graph1))
    graph2 = mapgraph(1:5, [(1, 2), (2, 3), (3, 1)])
    @test issetequal(collect(triangles(graph2))[1], 1:3)
    graph3 = mapgraph(1:8, [
        (1, 2), (2, 3), (1, 3), (3, 4), (4, 5),
        (5, 6), (4, 6), (5, 7), (7, 8), (8, 6)
    ])
    @test length(triangles(graph3)) == 2
    graph4 = mapgraph(1:10, [
        (1, 2), (2, 3), (3, 4), (3, 5), (5, 6),
        (6, 7), (7, 5), (5, 8), (8, 9), (9, 5), (5, 10)
    ])
    @test length(triangles(graph4)) == 2
end

end # graph.triangle
