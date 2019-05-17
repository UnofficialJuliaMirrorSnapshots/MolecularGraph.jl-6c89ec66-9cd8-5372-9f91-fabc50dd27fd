#
# This file is a part of MolecularGraph.jl
# Licensed under the MIT License http://opensource.org/licenses/MIT
#

export
    trivialhydrogens,
    allhydrogens,
    makehydrogensimplicit,
    makehydrogensexplicit,
    largestcomponentnodes,
    largestcomponentgraph,
    neutralizeacids!,
    neutralizeoniums!,
    depolarize!,
    triplebondanion!,
    canonicalize!,
    canonicalize

# TODO: large conjugated system
# TODO: salts and waters should detected by functional group analysis
# TODO: Phosphate, diphosphate, sulfate, nitrate, acetate,
# maleate, fumarate, succinate, citrate, tartrate, oxalate,
# mesylate, tosylate, besylate,
# benzoate, gluconate


"""
    trivialhydrogens(mol::GraphMol) -> Set{Int}

Return a set of trivial hydrogen nodes (light hydrogens which are uncharged,
non-radical, non-stereospecific and attached to organic heavy atoms)
"""
function trivialhydrogens(mol::GraphMol)
    hs = Set{Int}()
    organic_heavy = (
        :B, :C, :N, :O, :F, :Si, :P, :S, :Cl, :As, :Se, :Br, :I)
    for (i, atom) in enumerate(nodeattrs(mol))
        if (atom.symbol != :H || atom.charge != 0 || atom.multiplicity != 1
                || atom.mass !== nothing)
            continue
        elseif atom isa SmilesAtom && atom.stereo !== nothing
            continue
        end
        degree(mol, i) == 1 || continue
        (inc, adj) = iterate(neighbors(mol, i))[1]
        bond = edgeattr(mol, inc)
        nbratom = nodeattr(mol, adj)
        if bond isa SDFileBond && (bond.order != 1 || bond.notation != 0)
            continue
        elseif !(nbratom.symbol in organic_heavy)
            continue
        end
        push!(hs, i)
    end
    return hs
end


"""
    allhydrogens(mol::GraphMol) -> Set{Int}

Return a set of hydrogen nodes.
"""
function allhydrogens(mol::GraphMol)
    hs = Set{Int}()
    for (i, atom) in enumerate(nodeattrs(mol))
        if atom.symbol == :H
            push!(hs, i)
        end
    end
    return hs
end


"""
    makehydrogensimplicit(mol::GraphMol) -> GraphMol

Return molecule whose hydrogen nodes are removed. If option `all` is set to
false, only trivial hydrogens are removed (see [`trivialhydrogens`](@ref)).
"""
function makehydrogensimplicit(mol::GraphMol; all=true)
    hydrogens = all ? allhydrogens : trivialhydrogens
    ns = setdiff(nodeset(mol), hydrogens(mol))
    return graphmol(nodesubgraph(mol, ns))
end


"""
    makehydrogensexplicit(mol::GraphMol) -> GraphMol

Return molecule whose hydrogens are fully attached. If option `all` is set to
false, only trivial hydrogens are removed (see [`trivialhydrogens`](@ref)).
"""
function makehydrogensexplicit(mol::GraphMol)
    newmol = graphmol(mol)
    implicithcount_ = implicithcount(mol)
    for (i, atom) in enumerate(nodeattrs(mol))
        for j in 1:implicithcount_[i]
            n = addnode!(newmol, nodeattrtype(mol)(:H))
            addedge!(newmol, i, n, edgeattrtype(mol)())
        end
    end
    return newmol
end


"""
    largestcomponentnodes(mol::GraphMol) -> Set{Int}

Return a set of nodes in the largest connected component.
"""
largestcomponentnodes(mol::GraphMol
    ) = sortstablemax(connected_components(mol), by=length, init=Set{Int}())


"""
    largestcomponentgraph(mol::GraphMol) -> GraphMol

Return largest connected component of the molecular graph.
"""
largestcomponentgraph(mol::GraphMol
    ) = nodesubgraph(mol, largestcomponentnodes(mol))


"""
    neutralizeacids!(mol::GraphMol)

Neutralize oxo(thio) acids.

Note that this function edits `Atom` object fields directly. The molecular
property vector needs recalculation to apply the changes.
see [`canonicalize!`](@ref).
"""
function neutralizeacids!(mol::GraphMol)
    atomsymbol_ = atomsymbol(mol)
    charge_ = charge(mol)
    connectivity_ = connectivity(mol)
    pielectron_ = pielectron(mol)
    for o in findall(
            (atomsymbol_ .== :O) .* (charge_ .== -1) .* (connectivity_ .== 1))
        nbr = iterate(adjacencies(mol, o))[1]
        if pielectron_[nbr] == 1
            cnbrs = adjacencies(mol, nbr)
            pop!(cnbrs, o)
            for cn in cnbrs
                if (atomsymbol_[cn] in (:O, :S) && pielectron_[cn] == 1
                        && connectivity_[cn] == 1)
                    setnodeattr!(mol, o, setcharge(nodeattr(mol, o), 0))
                    break
                end
            end
        end
    end
end


"""
    neutralizeoniums!(mol::GraphMol)

Neutralize 1-3° oniums. Permanently charged quart-oniums are not neutralized.

Note that this function edits `Atom` object fields directly. The molecular
property vector needs recalculation to apply the changes.
see [`canonicalize!`](@ref).
"""
function neutralizeoniums!(mol::GraphMol)
    for o in findall((charge(mol) .== 1) .* (hcount(mol) .> 0))
        setnodeattr!(mol, o, setcharge(nodeattr(mol, o), 0))
    end
end


"""
    depolarize!(mol::GraphMol)

Depolarize oxo groups except in the case that polarization is required for
aromaticity.

Note that this function edits `Atom` object fields directly. The molecular
property vector needs recalculation to apply the changes.
see [`canonicalize!`](@ref).
"""
function depolarize!(mol::GraphMol)
    charge_ = charge(mol)
    isaromatic_ = isaromatic(mol)
    for o in findall((atomsymbol(mol) .== :O) .* (charge_ .== -1))
        @assert degree(mol, o) == 1 "unexpected oxygen degree $(length(nbrs))"
        (inc, adj) = iterate(neighbors(mol, o))[1]
        if charge_[adj] == 1 && !isaromatic_[adj]
            setnodeattr!(mol, o, setcharge(nodeattr(mol, o), 0))
            setnodeattr!(mol, adj, setcharge(nodeattr(mol, adj), 0))
            setedgeattr!(mol, inc, setorder(edgeattr(mol, inc), 2))
        end
    end
end


"""
    triplebondanion!(mol::GraphMol)

Canonicalize anions next to triple bonds (ex. [C-][N+]#N -> C=[N+]=[N-]).

Note that this function edits `Atom` object fields directly. The molecular
property vector needs recalculation to apply the changes.
see [`canonicalize!`](@ref).
"""
function triplebondanion!(mol::GraphMol)
    # TODO: better function name
    charge_ = charge(mol)
    for tb in findall(bondorder(mol) .== 3)
        tbond = edgeattr(mol, tb)
        (u, v) = getedge(mol, tb)
        for (f, s) in ((u, v), (v, u))
            nbrs = copy(neighbors(mol, f))
            pop!(nbrs, findedgekey(mol, f, s))
            length(nbrs) == 1 || continue
            (inc, adj) = iterate(nbrs)[1]
            if charge_[adj] == -1
                setnodeattr!(mol, adj, setcharge(nodeattr(mol, adj), 0))
                setnodeattr!(mol, s, setcharge(nodeattr(mol, s), -1))
                setedgeattr!(mol, inc, setorder(edgeattr(mol, inc), 2))
                setedgeattr!(mol, tb, setorder(edgeattr(mol, tb), 2))
            end
        end
    end
end


"""
    canonicalize!(mol::GraphMol)

Canonicalize molecule notation and apply the changes to the molecular property
vector.

- Neutralize oxo acid, 1-3° ammonium and polarized carbonyls except in the
  case that polarization is required for aromaticity.
- Canonicalize anions next to triple bonds (ex. [C-][N+]#N -> C=[N+]=[N-])
"""
function canonicalize!(mol::GraphMol)
    neutralizeacids!(mol)
    neutralizeoniums!(mol)
    depolarize!(mol)
    triplebondanion!(mol)
    return
end

function canonicalize(mol::GraphMol)
    newmol = graphmol(mol)
    canonicalize!(newmol)
    return newmol
end
