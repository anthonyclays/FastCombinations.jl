module FastCombinations

export Combinations

import Base: start, next, done, length, eltype, collect

immutable Combinations{N, T}
    itr::T
    function Combinations(itr::T)
        0 < N || error("Received N <= 0")  # TODO error message
        new{N, T}(itr)
    end
end
Base.convert{N, T}(::Type{Combinations{N}}, itr::T) = Combinations{N, T}(itr)

eltype{N, T}(::Combinations{N, T}) = NTuple{N, eltype(T)}
collect(combs::Combinations) = collect(eltype(combs), combs)

@generated length{N, T}(combs::Combinations{N, T}) = :(binomial(length(combs.itr), $N))

@generated function next_states{S, N}(itr, state::S, ::Type{Val{N}})
    N == 0 && return ()
    syms = [gensym(:state) for _ in 1:N]
    expr = Expr(:block, :($(syms[1]) = state))
    for i in 2:N
        push!(expr.args, quote
            (_, $(syms[i])) = next(itr, $(syms[i - 1]))
        end)
    end
    push!(expr.args, Expr(:tuple, syms...))
    expr
end

start{N, T}(combs::Combinations{N, T}) = next_states(combs.itr, start(combs.itr), Val{N})
done{N, T}(combs::Combinations{N, T}, state) = done(combs.itr, state[end])

@generated function next{N, T}(combs::Combinations{N, T}, state)
    comb_elements = [gensym(:comb) for _ in 1:N]
    new_states = [gensym(:state) for _ in 1:N]
    labels = [gensym(symbol(:label, l)) for l in 1:N]

    next_expr = Expr(:block)
    for i in 1:N
        push!(next_expr.args, :(($(comb_elements[i]), $(new_states[i])) = next(combs.itr, state[$i])))
    end

    goto_block = quote
        current_state = $(new_states[end])
        done(combs.itr, current_state) || @goto $(labels[1])
    end
    for i in 2:N
        push!(goto_block.args, quote
            next_state = $(new_states[end+1-i])
            next(combs.itr, next_state)[2] == current_state || @goto $(labels[i])
            current_state = next_state
        end)
    end
    push!(goto_block.args, :(@goto result))  # Final yield, no additional computation

    label_defs = Expr(:block)
    for i in 1:N
        lhs1 = Expr(:tuple, new_states[1:end-i]...)
        rhs1 = Expr(:tuple, [:(state[$i]) for i in 1:N-i]...)
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

end # module
