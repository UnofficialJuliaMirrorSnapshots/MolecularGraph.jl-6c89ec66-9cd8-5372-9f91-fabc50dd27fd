
using MolecularGraph: sdfatom, sdfbond

@testset "sdfilereader" begin

@testset "sdfatom" begin
    full = sdfatom(
        "    1.1763    0.6815    0.0000 C   0  0  0  0  0  0  0  0  0  0  0  0"
    )
    @test full[1] == :C
    @test full[2] == 0
    @test full[3] == 1
    @test full[4] == [1.1763, 0.6815, 0.0]
    atomBr = sdfatom("   -0.1041    2.3896    0.0000 Br  0  0")
    @test atomBr[1] == :Br
    @test atomBr[4] == [-0.1041, 2.3896, 0.0]
    charged = sdfatom("    2.5488    1.2083    0.0000 O   0  3")
    @test charged[2] == 1
    radical = sdfatom("    1.6514    2.7627    0.0000 C   0  4")
    @test radical[2] == 0
    @test radical[3] == 2
end

@testset "sdfbond" begin
    @test sdfbond("  1  2  2  0  0  0  0") == (1, 2, 2, 0)
    @test sdfbond("  5  4  1  6  0  0  0") == (5, 4, 1, 6)
end

@testset "sdfmol" begin
    demomol = joinpath(dirname(@__FILE__), "..", "assets", "test", "demo.mol")
    mol = sdftomol(demomol)
    @test edgecount(mol) == 37
    @test nodecount(mol) == 37
    @test mol isa SDFile
end

end # sdfilereader
