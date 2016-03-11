# FastCombinations

[![Build Status](https://travis-ci.org/anthonyclays/FastCombinations.jl.svg?branch=master)](https://travis-ci.org/anthonyclays/FastCombinations.jl)

The FastCombinations package was born from frustration with the existing `Combinations` type in base Julia.
`Base.Combinations` only works with iterator types that implement both `length` and `getindex` severely limiting its genericity.
On top of that, it uses Vectors for both its state and output, requiring three allocations on every call to `next`.
However, in almost all use cases the number of elements in a combination is known at compile time, which means it is theoretically possible to eliminate all heap allocations if we can somehow make 'the number of elements in a combination' a parameter to the `Combinations` type.

FastCombinations addresses these concerns by implementing a new `Combinations`-type that attempts to solve everything.
```julia
immutable Combinations{N, T}
    itr::T
end
```
The implementation uses generated functions to produce extremely efficient code for disparate values of `N`.

### Usage
```julia
# This loop requires no heap allocation, because tup is of bits type.
for tup in Combinations{3}(1:6)
    tup::NTuple{3, eltype(1:6)}
    @show tup
end
```

### Benchmarks
```julia
const itr = 1:100

function bench_base()
    t = 0
    for _ in combinations(itr, 3)
        t += 1
    end
    t
end

  0.020909 seconds (485.10 k allocations: 34.543 MB, 9.48% gc time)


function bench_fast()
    t = 0
    for _ in Combinations{3}(itr)
        t += 1
    end
    t
end

  0.000895 seconds  # No allocations!
```

### Drawbacks
When the number of elements in a combination is computed at runtime, performance will be slightly worse than `Base.Combinations`. You should only use FastCombinations when the type parameter N is statically known.

Additionally, when `N` becomes large, so does the generated code. For large values of `N`, compilation times will become unreasonable.
```shell
$ julia -E 'using FastCombinations; @time first(Combinations{20}(1:40))'
  2.266709 seconds (8.15 M allocations: 343.999 MB, 4.76% gc time)
(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20)
```
