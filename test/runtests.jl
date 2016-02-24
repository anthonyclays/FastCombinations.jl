using FastCombinations
import FastCombinations: next_states

using Base.Test

@test next_states(1:6, 1, Val{0}) == ()
@test next_states(1:6, 1, Val{1}) == (1,)
@test next_states(1:6, 1, Val{6}) == (1, 2, 3, 4, 5, 6)

@test_throws ErrorException Combinations{0}(1:1)

@test first(Combinations{1}(1:6)) == (1,)
@test first(Combinations{2}(1:6)) == (1,2)
@test first(Combinations{3}(1:6)) == (1,2,3)
@test first(Combinations{4}(1:6)) == (1,2,3,4)
@test first(Combinations{5}(1:6)) == (1,2,3,4,5)
@test first(Combinations{6}(1:6)) == (1,2,3,4,5,6)
@test collect(Combinations{7}(1:6)) == NTuple{7, Int}[]

@test first(MultiCombinations{1}(1:6)) == (1,)
@test first(MultiCombinations{2}(1:6)) == (1,1)
@test first(MultiCombinations{3}(1:6)) == (1,1,1)
@test first(MultiCombinations{4}(1:6)) == (1,1,1,1)
@test first(MultiCombinations{5}(1:6)) == (1,1,1,1,1)
@test first(MultiCombinations{6}(1:6)) == (1,1,1,1,1,1)

# TODO test more complex iterators

@test length(Combinations{1}(1:1)) == 1 == length(collect(Combinations{1}(1:1)))
@test length(Combinations{1}(1:2)) == 2 == length(collect(Combinations{1}(1:2)))
@test length(Combinations{1}(1:3)) == 3 == length(collect(Combinations{1}(1:3)))

@test length(Combinations{2}(1:2)) == 1 == length(collect(Combinations{2}(1:2)))
@test length(Combinations{2}(1:3)) == 3 == length(collect(Combinations{2}(1:3)))
@test length(Combinations{2}(1:4)) == 6 == length(collect(Combinations{2}(1:4)))

@test length(Combinations{3}(1:3)) == 1 == length(collect(Combinations{3}(1:3)))
@test length(Combinations{3}(1:4)) == 4 == length(collect(Combinations{3}(1:4)))
@test length(Combinations{3}(1:5)) == 10 == length(collect(Combinations{3}(1:5)))


@test length(MultiCombinations{1}(1:1)) == 1  == length(collect(MultiCombinations{1}(1:1)))
@test length(MultiCombinations{1}(1:2)) == 2  == length(collect(MultiCombinations{1}(1:2)))
@test length(MultiCombinations{1}(1:3)) == 3  == length(collect(MultiCombinations{1}(1:3)))

@test length(MultiCombinations{2}(1:1)) == 1  == length(collect(MultiCombinations{2}(1:1)))
@test length(MultiCombinations{2}(1:2)) == 3  == length(collect(MultiCombinations{2}(1:2)))
@test length(MultiCombinations{2}(1:3)) == 6  == length(collect(MultiCombinations{2}(1:3)))

@test length(MultiCombinations{3}(1:1)) == 1  == length(collect(MultiCombinations{3}(1:1)))
@test length(MultiCombinations{3}(1:2)) == 4  == length(collect(MultiCombinations{3}(1:2)))
@test length(MultiCombinations{3}(1:3)) == 10 == length(collect(MultiCombinations{3}(1:3)))
