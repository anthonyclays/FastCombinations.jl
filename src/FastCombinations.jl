module FastCombinations

export Combinations, MultiCombinations

import Base: start, next, done, length, eltype, collect

# Computes the next $K states of the iterator `itr`, starting from a given state.
# This function can handle cases where K is larger than the length of the given iterator.
@generated function initial_states{K}(itr, ::Type{Val{K}})
    K == 0 && return ()
    syms = [gensym(:state) for _ in 1:K]
    expr = Expr(:block, :($(syms[1]) = start(itr)))
    for i in 2:K
        sym = syms[i]
        push!(expr.args, quote
            (_, $sym) = next(itr, $(syms[i - 1]))
            done(itr, $sym) && return $(Expr(:tuple, repeated(sym, K)...))
        end)
    end
    push!(expr.args, Expr(:tuple, syms...))
    expr
end
# Computes the next $K states of the iterator `itr`, starting from a given state.
# This function assumes that the iterator has at least K elements left
# after the given state.
@generated function next_states{S, K}(itr, state::S, ::Type{Val{K}})
    K == 0 && return ()
    syms = [gensym(:state) for _ in 1:K]
    expr = Expr(:block, :($(syms[1]) = state))
    for i in 2:K
        push!(expr.args, quote
            (_, $(syms[i])) = next(itr, $(syms[i - 1]))
        end)
    end
    push!(expr.args, Expr(:tuple, syms...))
    expr
end

# A k-combination of a set is a way to select exactly k distinct elements from the set.
immutable Combinations{K, T}
    itr::T
    function Combinations(itr::T)
        0 < K || error("Received K <= 0")  # TODO error message
        new{K, T}(itr)
    end
end

Base.convert{K, T}(::Type{Combinations{K}}, itr::T) = Combinations{K, T}(itr)

eltype{K, T}(combs::Combinations{K, T}) = NTuple{K, eltype(combs.itr)}
collect(combs::Combinations) = collect(eltype(combs), combs)
@generated length{K, T}(combs::Combinations{K, T}) = :(binomial(length(combs.itr), $K))

start{K, T}(combs::Combinations{K, T}) = initial_states(combs.itr, Val{K})
done{K, T, State}(combs::Combinations{K, T}, state::NTuple{K, State}) = done(combs.itr, state[end])

@generated function next{K, T, State}(combs::Combinations{K, T}, state::NTuple{K, State})
    comb_elements = [gensym(:comb) for _ in 1:K]
    new_states = [gensym(:state) for _ in 1:K]
    labels = [gensym(Symbol(:label, l)) for l in 1:K]

    next_expr = Expr(:block)
    for i in 1:K
        push!(next_expr.args, :(($(comb_elements[i]), $(new_states[i])) = next(combs.itr, state[$i])))
    end

    goto_block = quote
        current_state = $(new_states[end])
        done(combs.itr, current_state) || @goto $(labels[1])
    end
    for i in 2:K
        push!(goto_block.args, quote
            next_state = $(new_states[end+1-i])
            next(combs.itr, next_state)[2] == current_state || @goto $(labels[i])
            current_state = next_state
        end)
    end
    push!(goto_block.args, :(@goto result))  # Final yield, no additional computation

    label_defs = Expr(:block)
    for i in 1:K
        lhs1 = Expr(:tuple, new_states[1:end-i]...)
        rhs1 = Expr(:tuple, [:(state[$i]) for i in 1:K-i]...)
        lhs2 = Expr(:tuple, new_states[end+2-i:end]...)
        rhs2 = :(next_states(combs.itr, next(combs.itr, $(new_states[end+1-i]))[2], Val{$(i-1)}))

        push!(label_defs.args, quote
            @label $(labels[i])
            $lhs1 = $rhs1
            $lhs2 = $rhs2
            @goto result
        end)
    end

    result_comb = Expr(:tuple, comb_elements...)
    result_state = Expr(:tuple, new_states...)
    result_expr = quote
        @label result
        $result_comb, $result_state
    end
    Expr(:block, next_expr, goto_block, label_defs, result_expr)
end

# a k-multicombination is a combination in which repetition of elements is allowed
# (though the elements must still be in sorted order)
immutable MultiCombinations{K, T}
    itr::T
    function MultiCombinations(itr::T)
        0 < K || error("Received K <= 0")  # TODO error message
        new{K, T}(itr)
    end
end

Base.convert{K, T}(::Type{MultiCombinations{K}}, itr::T) = MultiCombinations{K, T}(itr)

eltype{K, T}(combs::MultiCombinations{K, T}) = NTuple{K, eltype(combs.itr)}
collect(combs::MultiCombinations) = collect(eltype(combs), combs)
@generated length{K, T}(combs::MultiCombinations{K, T}) = :(binomial(length(combs.itr) + $(K - 1), $K))

@generated start{K, T}(combs::MultiCombinations{K, T}) = quote
    state = start(combs.itr)
    $(Expr(:tuple, repeated(:state, K)...))
end
done{K, T, State}(combs::MultiCombinations{K, T}, state::NTuple{K, State}) = done(combs.itr, state[1])

@generated function next{K, T, State}(combs::MultiCombinations{K, T}, state::NTuple{K, State})
    comb_elements = [gensym(:comb) for _ in 1:K]
    new_states = [gensym(:state) for _ in 1:K]
    labels = [gensym(Symbol(:label, l)) for l in 1:K]

    next_expr = Expr(:block)
    for i in 1:K
        push!(next_expr.args, :(($(comb_elements[i]), $(new_states[i])) = next(combs.itr, state[$i])))
    end

    goto_block = Expr(:block)
    for i in 1:K
        push!(goto_block.args, quote
            done(combs.itr, $(new_states[end+1-i])) || @goto $(labels[i])
        end)
    end
    push!(goto_block.args, :(@goto result))

    label_defs = Expr(:block)
    for i in 1:K
        lhs1 = Expr(:tuple, new_states[1:end-i]...)
        rhs1 = Expr(:tuple, [:(state[$i]) for i in 1:K-i]...)
        lhs2 = Expr(:tuple, new_states[end+2-i:end]...)
        rhs2 = Expr(:tuple, repeated(new_states[end+1-i], i-1)...)

        push!(label_defs.args, quote
            @label $(labels[i])
            $lhs1 = $rhs1
            $lhs2 = $rhs2
            @goto result
        end)
    end

    result_comb = Expr(:tuple, comb_elements...)
    result_state = Expr(:tuple, new_states...)
    result_expr = quote
        @label result
        $result_comb, $result_state
    end
    Expr(:block, next_expr, goto_block, label_defs, result_expr)
end

end # module
