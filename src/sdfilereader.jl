#
# This file is a part of MolecularGraph.jl
# Licensed under the MIT License http://opensource.org/licenses/MIT
#

export
    SDFileReader,
    sdfilereader,
    nohaltsupplier,
    sdftomol


const SDF_CHARGE_TABLE = Dict(
    0 => 0, 1 => 3, 2 => 2, 3 => 1, 4 => 0, 5 => -1, 6 => -2, 7 => -3
)


function sdfatom(line)
    xpos = parse(Float64, line[1:10])
    ypos = parse(Float64, line[11:20])
    zpos = parse(Float64, line[21:30])
    coords = Float64[xpos, ypos, zpos]
    sym = Symbol(rstrip(line[32:34]))
    # atom.mass_diff = parse(Int, line[35:36]) use ISO property
    old_sdf_charge = parse(Int, line[37:39])
    charge = SDF_CHARGE_TABLE[old_sdf_charge]
    multi = old_sdf_charge == 4 ? 2 : 1
    # atom.stereo_flag = parse(Int, line[40:42])
    # valence = parse(Int, line[46:48])
    return (sym, charge, multi, coords)
end


function sdfbond(line)
    u = parse(Int, line[1:3])
    v = parse(Int, line[4:6])
    order = parse(Int, line[7:9])
    notation = parse(Int, line[10:12])
    return (u, v, order, notation)
end


function sdfprops(lines)
    props = Dict{Int,Dict{Symbol,Real}}() # atomindex, {type => value}
    for line in lines
        proptype = line[4:6]
        if !(proptype in ("CHG", "RAD", "ISO"))
            continue # Other properties are not supported yet
        end
        count = parse(Int, line[7:9])
        for c in 1:count
            i = c - 1
            idx = parse(Int, line[8i + 11 : 8i + 13])
            val = line[8i + 15 : 8i + 17]
            haskey(props, idx) || (props[idx] = Dict{Symbol,Real}())
            if proptype == "CHG"
                props[idx][:CHG] = parse(Int, val)
            elseif proptype == "RAD"
                props[idx][:RAD] = parse(Int, val)
            elseif proptype == "ISO"
                props[idx][:ISO] = parse(Float64, val)
            end
        end
    end
    return props
end


function sdfoptions(lines)
    data = Dict()
    for (i, line) in enumerate(lines)
        # Some inappropriate signs are accepted for practical use
        m = match(r">.*?<([\w -.%=]+)>", line)
        if m !== nothing
            data[Symbol(m[1])] = lines[i + 1]
        end
    end
    return data
end


"""
    parse(::Type{SDFile}, lines)

Parse lines of a SDFile mol block data into a molecule object.
"""
function Base.parse(::Type{SDFile}, sdflines)
    sdflines = collect(sdflines)
    molend = findnext(x -> x == "M  END", sdflines, 1)
    lines = @view sdflines[1:molend-1]
    optlines = @view sdflines[molend+1:end]

    # Get element blocks
    countline = lines[4]
    atomcount = parse(UInt16, countline[1:3])
    bondcount = parse(UInt16, countline[4:6])
    # chiralflag = countline[12:15] Not used
    # propcount = countline[30:33] No longer supported
    atomoffset = 5
    bondoffset = atomcount + atomoffset
    propoffset = bondoffset + bondcount
    atomblock = @view lines[atomoffset:bondoffset-1]
    bondblock = @view lines[bondoffset:propoffset-1]
    propblock = @view lines[propoffset:end]

    # Parse atoms
    nodeattrs = SDFileAtom[]
    props = sdfprops(propblock)
    for (i, line) in enumerate(atomblock)
        (sym, charge, multi, coords) = sdfatom(line)
        mass = nothing
        if !isempty(props)
            # If prop block exists, any annotations in atom blocks are ignored
            charge = 0
            multi = 1
            if haskey(props, i)
                prop = props[i]
                haskey(prop, :CHG) && (charge = prop[:CHG])
                haskey(prop, :RAD) && (multi = prop[:RAD])
                haskey(prop, :ISO) && (mass = prop[:ISO])
            end
        end
        push!(nodeattrs, SDFileAtom(sym, charge, multi, mass, coords))
    end

    # Parse bonds
    edges = Tuple{Int,Int}[]
    edgeattrs = SDFileBond[]
    for line in bondblock
        (u, v, order, notation) = sdfbond(line)
        push!(edges, (u, v))
        push!(edgeattrs, SDFileBond(order, notation))
    end

    molobj = graphmol(edges, nodeattrs, edgeattrs)
    merge!(molobj.attributes, sdfoptions(optlines))
    return molobj
end


function nohaltsupplier(block)
    mol = try
        return parse(SDFile, block)
    catch e
        if e isa ErrorException
            println("$(e.msg) (#$(i) in sdfilereader)")
            return graphmol(SDFileAtom, SDFileBond)
        else
            throw(e)
        end
    end
end


struct SDFileReader
    lines::Base.EachLine
    parser::Function
end

function Base.iterate(reader::SDFileReader, state=nothing)
    block = String[]
    next = iterate(reader.lines)
    while next !== nothing
        (line, state) = next
        if startswith(line, raw"$$$$")
            return (reader.parser(block), state)
        end
        push!(block, rstrip(line))
        next = iterate(reader.lines, state)
    end
    if !isempty(block)
        return (reader.parser(block), state)
    end
    return
end

Base.IteratorSize(::Type{SDFileReader}) = Base.SizeUnknown()
Base.IteratorEltype(::Type{SDFileReader}) = Base.EltypeUnknown()

"""
    sdfilereader(file::IO)
    sdfilereader(path::AbstractString)

Read SDFile data from input stream (or a file path as a string) and return a
lazy iterator that yields molecule objects.

`sdfilereader` does not stop and raise errors when an erroneous or incompatible
SDFile block is read but produces an error message and yields an empty molecule.
If this behavior is not desirable, you can use the customized supplier function
instead of default supplier `nohaltsupplier`

```
function customsupplier()
    mol = try
        parse(SDFile, block)
    catch e
        throw(ErrorException("incompatible molecule found, aborting..."))
    end
end

function sdfilereader(file::IO)
    return SDFileReader(eachline(file), customsupplier)
end
```
"""
sdfilereader(file::IO) = SDFileReader(eachline(file), nohaltsupplier)
sdfilereader(path::AbstractString) = sdfilereader(open(path))


"""
    sdftomol(lines) -> GraphMol{SDFileAtom,SDFileBond}
    sdftomol(file::IO) -> GraphMol{SDFileAtom,SDFileBond}
    sdftomol(path::AbstractString) -> GraphMol{SDFileAtom,SDFileBond}

Read a SDFile(.sdf or .mol) and parse it into a molecule object. The given
argument should be a file input stream, a file path as a string or an iterator
that yields each sdfile text lines.
"""
sdftomol(lines) = parse(SDFile, lines)
sdftomol(file::IO) = sdftomol(eachline(file))
sdftomol(path::AbstractString) = sdftomol(open(path))
