
@testset "smarts.smiles" begin

@testset "chain" begin
    nullmol = parse(SMILES, "")
    @test nodecount(nullmol) == 0
    @test edgecount(nullmol) == 0

    methane = parse(SMILES, "C")
    @test nodeattr(methane, 1).symbol == :C
    @test edgecount(methane) == 0

    EtOH = parse(SMILES, "CCO")
    @test nodeattr(EtOH, 3).symbol == :O

    EtOH2 = parse(SMILES, "[CH3][CH2][OH]")
    @test edgeattr(EtOH2, 2, 3).order == 1

    nitro = parse(SMILES, "N#N")
    @test edgeattr(nitro, 1, 2).order == 3

    vinylcl = parse(SMILES, "C=CCl")
    @test edgeattr(vinylcl, 1, 2).order == 2
    @test nodeattr(vinylcl, 3).symbol == :Cl
end

@testset "branch" begin
    tBuOH = parse(SMILES, "CC(C)(C)O")
    @test nodeattr(tBuOH, 5).symbol == :O
    @test degree(tBuOH, 2) == 4

    TFA = parse(SMILES, "FC(F)(F)C(=O)O")
    @test edgeattr(TFA, 5, 6).order == 2
    @test degree(TFA, 2) == 4

    EDTA = parse(SMILES, "C(CN(CC(=O)O)CC(=O)O)N(CC(=O)O)CC(=O)O")
    @test degree(EDTA, 5) == 3
    @test degree(EDTA, 12) == 3
    @test degree(EDTA, 14) == 3
end

@testset "ring" begin
    cychexe = parse(SMILES, "C1C=CCCC1")
    @test degree(cychexe, 1) == 2

    cychexe2 = parse(SMILES, "C=1CCCCC1")
    @test edgeattr(cychexe2, 1, 6).order == 2

    cychexe3 = parse(SMILES, "C1CCCCC=1")
    @test edgeattr(cychexe3, 1, 6).order == 2

    cychexe4 = parse(SMILES, "C=1CCCCC=1")
    @test edgeattr(cychexe4, 1, 6).order == 2

    bicyclohexyl = parse(SMILES, "C1CCCCC1C1CCCCC1")
    @test edgeattr(bicyclohexyl, 1, 6).order == 1
    @test edgeattr(bicyclohexyl, 7, 12).order == 1

    bicyclohexyl2 = parse(SMILES, "C1CCCCC1C2CCCCC2")
    @test edgeattr(bicyclohexyl2, 1, 6).order == 1
    @test edgeattr(bicyclohexyl2, 7, 12).order == 1

    naphthalene = parse(SMILES, "C=1C=CC=C2C1C=CC=C2")
    @test edgeattr(naphthalene, 1, 6).order == 2
    @test edgeattr(naphthalene, 5, 10).order == 1

    naphthalene2 = parse(SMILES, "C1=CC=C2C(=C1)C=CC=C2")
    @test edgeattr(naphthalene2, 1, 6).order == 1
    @test edgeattr(naphthalene2, 4, 10).order == 1

    tetrahedrane = parse(SMILES, "C12C3C1C23")
    @test edgecount(tetrahedrane) == 6

    thiamin = parse(SMILES, "OCCc1c(C)[n+](=cs1)Cc2cnc(C)nc(N)2")
    @test edgecount(thiamin) == 19
end

@testset "component" begin
    NaCl = parse(SMILES, "[Na+].[Cl-]")
    @test nodeattr(NaCl, 1).symbol == :Na
    @test nodeattr(NaCl, 1).charge == 1
    @test nodeattr(NaCl, 2).symbol == :Cl
    @test nodeattr(NaCl, 2).charge == -1

    ferrous = parse(SMILES, "[Fe++]")
    @test nodeattr(ferrous, 1).symbol == :Fe
    @test nodeattr(ferrous, 1).charge == 2

    ferrous2 = parse(SMILES, "[Fe+2]")
    @test nodeattr(ferrous2, 1).symbol == :Fe
    @test nodeattr(ferrous2, 1).charge == 2

    CuSO4 = parse(SMILES, "[Cu+2].[O-]S(=O)(=O)[O-]")
    @test nodeattr(CuSO4, 1).charge == 2
    @test nodeattr(CuSO4, 6).charge == -1
    @test degree(CuSO4, 3) == 4

    PhONa = parse(SMILES, "c1cc([O-].[Na+])ccc1")
    @test degree(PhONa, 3) == 3
    @test degree(PhONa, 5) == 0
end

@testset "stereo" begin
    # TODO: optical isomers
    LAla = parse(SMILES, "N[C@H](C)C(=O)O")
    @test degree(LAla, 2) == 3
    @test nodeattr(LAla, 2).stereo == 1
    DAla = parse(SMILES, "N[C@@H](C)C(=O)O")
    @test degree(DAla, 2) == 3
    @test nodeattr(DAla, 2).stereo == 2
end

@testset "aromatic" begin
    # TODO: aromatic
    benzene = parse(SMILES, "c1ccccc1")
    @test nodeattr(benzene, 1).isaromatic
    @test edgeattr(benzene, 1, 6).order == 1
    pyridone = parse(SMILES, "O=c1[nH]cccc1")
    @test nodeattr(pyridone, 3).isaromatic
    @test degree(pyridone, 3) == 2 # Implicit H is ignored

    # println(Int64[a.index for a in atomvector(ethanol2)])
    # println(Tuple{Int64, Int64}[(b.u, b.v) for b in bondvector(ethanol2)])
end

end # smarts.smiles
