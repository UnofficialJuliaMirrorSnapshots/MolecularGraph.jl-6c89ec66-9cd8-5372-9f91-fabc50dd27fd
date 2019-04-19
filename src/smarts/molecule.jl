#
# This file is a part of MolecularGraph.jl
# Licensed under the MIT License http://opensource.org/licenses/MIT
#


function componentquery!(state::SmartsParserState)
    """ Start <- Component ('.' Component)*
    """
    if read(state) == '\0'
        return # Empty query
    end
    component!(state)
    while !state.done && read(state) == '.'
        forward!(state)
        state.root = state.node + 1
        component!(state)
    end
end


function component!(state::SmartsParserState)
    """ Component <- '(' Fragment ')' / Fragment
    """
    if read(state) == '('
        # Connectivity restriction
        forward!(state)
        push!(state.connectivity, [state.root])
        fragment!(state)
        c2 = read(state)
        @assert c2 == ')' "unexpected token: $(c2) at $(state.pos)"
        forward!(state)
    else
        fragment!(state)
    end
end


function fragment!(state::SmartsParserState)
    """ Fragment <- Group
    """
    if read(state) == '\0'
        return # Empty molecule
    end
    group!(state, nothing)
    # Validity check
    if state.node + 1 == state.root
        throw(ErrorException(
            "unexpected token: $(read(state)) at $(state.pos)"))
    elseif length(state.ringlabel) > 0
        label = collect(keys(state.ringlabel))[1]
        throw(ErrorException("unclosed ring: $(label)"))
    end
end


function group!(state::SmartsParserState, bond)
    """ Group <- Atom ((Bond? Group) / Chain)* Chain
    """
    a = atom!(state)
    if a === nothing
        # ex. CC((C)C)C should be CC(CC)C
        throw(ErrorException(
            "unexpected token: branch starts with '(' at $(state.pos)"))
    end
    state.node += 1
    push!(state.nodeattrs, a)
    if bond !== nothing
        # Connect branch
        push!(state.edges, (state.branch, state.node))
        push!(state.edgeattrs, bond)
    end
    state.branch = state.node
    while true
        if read(state) == '('
            forward!(state)
            buf = state.branch
            b = something(bond!(state), defaultbond(state))
            group!(state, b)
            state.branch = buf
            c = read(state)
            @assert c == ')' "unexpected token: $(c) at $(state.pos)"
            forward!(state)
            if state.done || read(state) in ")."
                # ex. CC(C)(C) should be CC(C)C
                throw(ErrorException(
                    "unexpected token: branch ends with ')' at $(state.pos)"))
            end
        else
            chain!(state)
            state.branch = state.node
            if state.done || read(state) in ")."
                break
            end
        end
    end
end


function chain!(state::SmartsParserState)
    """ Chain <- (Bond? (Atom / RingLabel))+
    """
    u = state.branch
    while !state.done
        # Bond?
        if read(state) == '.'
            if !state.allow_disconnected
                throw(ErrorException(
                    "unexpected token: disconnected at $(state.pos)"))
            elseif lookahead(state, 1) != '('
                # Disconnected
                forward!(state)
                b = :disconn
            else
                b = bond!(state)
            end
        else
            b = bond!(state)
        end

        # RingLabel
        if isdigit(read(state))
            num = parse(Int, read(state))
            forward!(state)
            if num in keys(state.ringlabel)
                (v, rb) = state.ringlabel[num]
                b = something(b, rb, defaultbond(state))
                delete!(state.ringlabel, num) # Ring label is reusable
                push!(state.edges, (u, v))
                push!(state.edgeattrs, b)
            else
                state.ringlabel[num] = (u, b)
            end
            continue
        end

        # Atom
        a = atom!(state)
        if a === nothing
            c = read(state)
            @assert c in "().\0" "unexpected token: $(c) at $(state.pos)"
            if b == :disconn
                throw(ErrorException(
                    "unexpected token: $(read(state)) at $(state.pos)"))
            end
            break
        else
            state.node += 1
            push!(state.nodeattrs, a)
        end
        if b == :disconn
            if state isa SmartsParser
                for conn in state.connectivity
                    if conn[1] == state.root
                        push!(conn, state.node)
                    end
                end
            end
        else
            b = something(b, defaultbond(state))
            push!(state.edges, (u, state.node))
            push!(state.edgeattrs, b)
        end
        u = state.node
    end
end
