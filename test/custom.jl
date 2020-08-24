using Ripserer
using SparseArrays
using Test
using TupleTools

using Ripserer: dist

@testset "Custom filtration 1" begin
    flt = Custom([
        (1,) => 0,
        (4,) => 0,
        (1, 3) => 2,
        (1, 4) => 3,
        (3, 4) => 6.0,
        (1, 2, 3) => 7,
        (1, 2, 4) => 8,
        (1, 3, 4) => 9,
        (1, 2, 3, 4) => 9,
        (3,) => 10_000,
    ]; threshold=8)

    @test flt isa Custom{Int, Float64}
    @test dim(flt) == 3
    @test sort(flt[0], by=index) == [
        Simplex{0}(1, 0.0),
        Simplex{0}(2, 7.0),
        Simplex{0}(3, 2.0),
        Simplex{0}(4, 0.0),
    ]
    @test isempty(flt[10])
    @test simplex(flt, Val(2), (1, 2, 4)) === Simplex{2}((4, 2, 1), 8.0)
    @test simplex(flt, Val(2), (4, 3, 1)) === nothing

    @test all(eachindex(dist(flt))) do cart_ind
        i, j = TupleTools.sort(Tuple(cart_ind), rev=true)
        if i ≠ j
            idx = index((i, j))
            return dist(flt)[i, j] == haskey(flt.dicts[2], idx)
        else
            return !dist(flt)[i, j]
        end
    end

    d0, d1, d2 = ripserer(flt, dim_max=2)
    @test d0 == [(0, 3), (0, Inf)]
    @test d1 == [(6, Inf)]
    @test d2 == []
end

@testset "Custom filtration vs Rips" begin
    dist = [
        0 1 2 1
        1 0 1 2
        2 1 0 1
        1 2 1 0
    ]

    cf = Custom([
        [(i,) => 0 for i in 1:4];
        [(i, j) => dist[i, j] for i in 1:4 for j in i+1:4];
        [(i, j, k) => max(dist[i, j], dist[i, k], dist[j, k])
         for i in 1:4 for j in i+1:4 for k in j+1:4];
    ])
    @test simplex(cf, Val(3), (4, 3, 2, 1)) == nothing
    @test all(birth(cf, i) == 0 for i in 1:4)

    @test ripserer(dist) == ripserer(cf)
end

@testset "Custom filtration vs SparseRips" begin
    spdist = sparse([
        0 1 0 0 0 1
        1 0 1 0 0 0
        0 1 0 1 0 0
        0 0 1 0 1 0
        0 0 0 1 0 1
        1 0 0 0 1 0
    ])
    cf = Custom([
        (1,) => 0,
        (2,) => 0,
        (3,) => 0,
        (4,) => 0,
        (5,) => 0,
        (6,) => 0,
        (1, 2) => 1,
        (2, 3) => 1,
        (3, 4) => 1,
        (4, 5) => 1,
        (5, 6) => 1,
        (6, 1) => 1,
    ])
    sprips = SparseRips(spdist)

    @test dist(cf) == Bool.(spdist)
    @test threshold(cf) == 1
    @test ripserer(cf) == ripserer(sprips)
end

@testset "Overflow" begin
    big_simplex = Tuple(Ripserer._vertices(Int128(typemax(Int64) ÷ 2), Val(6)))
    @test_throws OverflowError Custom{Int}([big_simplex => 1])
    @test begin Custom{Int128}([big_simplex => 1]); true end
end
