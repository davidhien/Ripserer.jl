using Ripserer

using Compat
using Ripserer:
    ReductionMatrix, insert_column!, has_column,
    Column, pop_pivot!, pivot,
    zeroth_intervals,
    ReductionMatrix

include("data.jl")

@testset "ReductionMatrix" begin
    rm = ReductionMatrix{Int}()
    @test length(rm) == 0

    insert_column!(rm, 3)
    push!(rm, 1)
    push!(rm, 2)
    push!(rm, 3)
    push!(rm, 4)

    insert_column!(rm, 10)
    push!(rm, 0)
    push!(rm, 0)
    push!(rm, 0)

    insert_column!(rm, 1)

    insert_column!(rm, 15)
    push!(rm, 1)

    @test has_column(rm, 3)
    @test collect(rm[3]) == [1, 2, 3, 4]

    @test has_column(rm, 10)
    @test length(rm[10]) == 3
    @test all(iszero, rm[10])

    @test has_column(rm, 1)
    @test length(rm[1]) == 0
    @test eltype(collect(rm[1])) === Int

    @test has_column(rm, 15)
    @test length(rm[15]) == 1
    @test first(rm[15]) == 1

    @test !has_column(rm, 2)
    @test !has_column(rm, 100)
end

@testset "Column" begin
    @testset "single element" begin
        col = Column{Simplex{1, 2, Float64}}()
        push!(col, Simplex{1, 2}(2.0, 1, 1))
        push!(col, Simplex{1, 2}(2.0, 1, 1))
        push!(col, Simplex{1, 2}(2.0, 1, 1))
        push!(col, Simplex{1, 2}(2.0, 1, 1))
        push!(col, Simplex{1, 2}(2.0, 1, 1))

        @test pop_pivot!(col) == Simplex{1, 2}(2.0, 1, 1)
        @test isempty(col)

        col = Column{Simplex{2, 3, Float64}}()
        push!(col, Simplex{2, 3}(2.0, 1, 1))
        push!(col, Simplex{2, 3}(2.0, 1, 1))
        push!(col, Simplex{2, 3}(2.0, 1, 1))

        @test isnothing(pivot(col))
        @test isnothing(pop_pivot!(col))
        @test isempty(col)
    end
    @testset "multiple" begin
        col = Column{Simplex{3, 5, Float64}}()
        push!(col, Simplex{3, 5}(1.0, 2, 3))
        push!(col, Simplex{3, 5}(2.0, 3, 4))
        push!(col, Simplex{3, 5}(1.0, 2, 2))
        push!(col, Simplex{3, 5}(3.0, 1, 2))
        push!(col, Simplex{3, 5}(2.0, 3, 1))
        push!(col, Simplex{3, 5}(4.0, 4, 4))
        push!(col, Simplex{3, 5}(4.0, 4, 4))
        push!(col, Simplex{3, 5}(4.0, 4, 4))
        push!(col, Simplex{3, 5}(5.0, 4, 4))
        push!(col, Simplex{3, 5}(5.0, 4, 1))

        @test pop_pivot!(col) == Simplex{3, 5}(3.0, 1, 2)
        @test pivot(col) == Simplex{3, 5}(4.0, 4, 2)
        @test pop_pivot!(col) == Simplex{3, 5}(4.0, 4, 2)
        @test isnothing(pop_pivot!(col))
        @test isnothing(pop_pivot!(col))
    end
end

@testset "compute_0_dim_pairs!" begin
    @testset "dense" begin
        dist = [0 1 2;
                1 0 3;
                2 3 0]
        flt = RipsFiltration(dist, threshold=3)
        res, columns, simplices = zeroth_intervals(flt, 1, Val(false))

        @test !isnothing(simplices)
        @test res == PersistenceDiagram(0, [(0, 1),
                                            (0, 2),
                                            (0, ∞)])
        @test columns == [Simplex{1, 2}(3, 3, 1)]
    end
    @testset "sparse" begin
        dist = [0 1 2;
                1 0 0;
                2 0 0]
        flt = SparseRipsFiltration(dist)
        res, columns, simplices = zeroth_intervals(flt, 1, Val(false))

        @test simplices == [Simplex{1, 2}(1, 1, 1),
                            Simplex{1, 2}(2, 2, 1)]
        @test res == PersistenceDiagram(0, [(0, 1),
                                            (0, 2),
                                            (0, ∞)])
        @test isempty(columns)
    end
    @testset "birth" begin
        dist = Float64[ 1 10 20 40;
                        10  2 30 50;
                        20 30  3 60;
                        40 50 60  4]
        flt = RipsFiltration(dist)
        res, columns, simplices = zeroth_intervals(flt, 1, Val(false))
        @test res == PersistenceDiagram(0, [(1.0, ∞),
                                            (2.0, 10.0),
                                            (3.0, 20.0),
                                            (4.0, 40.0)])
    end
end

@testset "ripserer" begin
    @testset "full matrix, no threshold" begin
        @testset "icosahedron" begin
            res = ripserer(icosahedron, dim_max=2)
            @test res[1] == [fill(PersistenceInterval(0.0, 1.0), 11);
                             PersistenceInterval(0.0, ∞)]
            @test isempty(res[2])
            @test res[3] == [PersistenceInterval(1.0, 2.0)]
        end
        @testset "torus 16" begin
            d0, d1, d2 = ripserer(torus(16), dim_max=2)

            @test length(d0) == 16

            @test all(x -> birth(x) ≈ 0.5, d1)
            @test count(x -> death(x) ≈ 1, d1) == 2
            @test count(x -> isapprox(death(x), 0.71, atol=0.1), d1) == 15

            @test death(only(d2)) == 1
        end
        @testset "torus 100" begin
            d0, d1 = ripserer(torus(100), dim_max=1)

            @test length(d0) == 100

            deaths = sort(death.(d1))
            @test deaths[end] ≈ 0.8
            @test deaths[end-1] ≈ 0.8
            @test deaths[end-2] < 0.5
        end
        @testset "cycle" begin
            d0, d1, d2, d3, d4 = ripserer(cycle, dim_max=4)
            @test d0 == [fill(PersistenceInterval(0, 1), size(cycle, 1) - 1);
                         PersistenceInterval(0, ∞)]
            @test d1 == [PersistenceInterval(1, 6)]
            @test d2 == fill(PersistenceInterval(6, 7), 5)
            @test d3 == [PersistenceInterval(7, 8)]
            @test d4 == []

            d0_7, d1_7, d2_7, d3_7, d4_7 = ripserer(cycle, dim_max=4, modulus=7)
            @test all(d0 .== d0_7)
            @test all(d1 .== d1_7)
            @test all(d2 .== d2_7)
            @test all(d3 .== d3_7)
            @test all(d4 .== d4_7)
        end
        @testset "projective plane (modulus)" begin
            _, d1_2, d2_2 = ripserer(projective_plane, dim_max=2)
            _, d1_3, d2_3 = ripserer(projective_plane, dim_max=2, modulus=3)
            @test d1_2 == [PersistenceInterval(1, 2)]
            @test d2_2 == [PersistenceInterval(1, 2)]
            @test isempty(d1_3)
            @test isempty(d2_3)
        end
    end

    @testset "full matrix, with threshold" begin
        @testset "icosahedron, high threshold" begin
            res = ripserer(icosahedron, threshold=2, dim_max=2)
            @test res[1] == [fill(PersistenceInterval(0.0, 1.0), 11);
                             PersistenceInterval(0.0, ∞)]
            @test isempty(res[2])
            @test res[3] == [PersistenceInterval(1.0, 2.0)]
        end
        @testset "icosahedron, med threshold" begin
            res = ripserer(icosahedron, dim_max=2, threshold=1)
            @test res[1] == [fill(PersistenceInterval(0.0, 1.0), 11);
                             PersistenceInterval(0.0, ∞)]
            @test isempty(res[2])
            @test res[3] == [PersistenceInterval(1.0, ∞)]
        end
        @testset "icosahedron, low threshold" begin
            res = ripserer(icosahedron, dim_max=2, threshold=0.5)
            @test res[1] == fill(PersistenceInterval(0.0, ∞), 12)
            @test isempty(res[2])
            @test isempty(res[3])
        end
        @testset "torus 16, high threshold" begin
            d0, d1, d2 = ripserer(torus(16), dim_max=2, threshold=2)

            @test length(d0) == 16

            @test all(x -> birth(x) ≈ 0.5, d1)
            @test count(x -> death(x) ≈ 1, d1) == 2
            @test count(x -> isapprox(death(x), 0.71, atol=0.1), d1) == 15

            @test death(only(d2)) == 1
        end
        @testset "torus 16, med threshold" begin
            d0, d1, d2 = ripserer(torus(16), dim_max=2, threshold=0.9)

            @test length(d0) == 16

            @test all(x -> birth(x) ≈ 0.5, d1)
            @test count(x -> death(x) == ∞, d1) == 2
            @test count(x -> isapprox(death(x), 0.71, atol=0.1), d1) == 15

            @test last(only(d2)) == ∞
        end
        @testset "torus 16, low threshold" begin
            d0, d1, d2 = ripserer(torus(16), dim_max=2, threshold=0.5)

            @test length(d0) == 16

            @test all(x -> birth(x) ≈ 0.5, d1)
            @test all(x -> death(x) == ∞, d1)

            @test isempty(d2)
        end
        @testset "projective plane (modulus), med threshold" begin
            _, d1_2, d2_2 = ripserer(projective_plane,
                                     dim_max=2, threshold=1)
            _, d1_3, d2_3 = ripserer(projective_plane,
                                     dim_max=2, modulus=3, threshold=1)
            @test d1_2 == [PersistenceInterval(1, ∞)]
            @test d2_2 == [PersistenceInterval(1, ∞)]
            @test isempty(d1_3)
            @test isempty(d2_3)
        end
    end

    @testset "sparse matrix" begin
        @testset "icosahedron" begin
            flt = SparseRipsFiltration(icosahedron, threshold=2)
            res = ripserer(flt, dim_max=2)
            @test res[1] == [fill(PersistenceInterval(0.0, 1.0), 11);
                             PersistenceInterval(0.0, ∞)]
            @test isempty(res[2])
            @test res[3] == [PersistenceInterval(1.0, 2.0)]
        end
        @testset "torus 16" begin
            dists = sparse(torus(16))
            SparseArrays.fkeep!(dists, (_, _, v) -> v ≤ 1)

            d0, d1, d2 = ripserer(dists, dim_max=2)

            @test length(d0) == 16

            @test all(x -> birth(x) ≈ 0.5, d1)
            @test count(x -> death(x) ≈ 1, d1) == 2
            @test count(x -> isapprox(death(x), 0.71, atol=0.1), d1) == 15

            @test last(only(d2)) == 1
        end
        @testset "projective plane (modulus), med threshold" begin
            dists = sparse(projective_plane)
            SparseArrays.fkeep!(dists, (_, _, v) -> v ≤ 2)

            _, d1_2, d2_2 = ripserer(dists, dim_max=2, threshold=1)
            _, d1_3, d2_3 = ripserer(dists, dim_max=2, modulus=3, threshold=1)
            @test d1_2 == [PersistenceInterval(1, ∞)]
            @test d2_2 == [PersistenceInterval(1, ∞)]
            @test isempty(d1_3)
            @test isempty(d2_3)
        end
    end

    @testset "representatives" begin
        _, d1, d2 = ripserer(projective_plane, dim_max=2, representatives=true)

        @test representative(only(d1)) == [
            Simplex{1, 2}(1, (11, 10), 1),
            Simplex{1, 2}(1, (10, 7), 1),
            Simplex{1, 2}(1, (10, 6), 1),
            Simplex{1, 2}(1, (8, 1), 1),
            Simplex{1, 2}(1, (7, 3), 1),
            Simplex{1, 2}(1, (7, 1), 1),
            Simplex{1, 2}(1, (6, 2), 1),
            Simplex{1, 2}(1, (5, 1), 1),
            Simplex{1, 2}(1, (2, 1), 1),
        ]
        @test representative(only(d2)) == [Simplex{2, 2}(1, (6, 2, 1), 1)]
    end

    @testset "lower star" begin
        data = [range(0, 1, length=5);
                range(1, 0.5, length=5)[2:end];
                range(0.5, 2, length=4)[2:end];
                range(2, -1, length=4)[2:end]]

        # Create distance matrix from data, where neighboring points are connected by edges
        # and the edge weights are equal to the max of both vertex births.
        n = length(data)
        dists = spzeros(n, n)
        for i in 1:n
            dists[i, i] = data[i]
        end
        for i in 1:n-1
            j = i + 1
            dists[i, j] = dists[j, i] = max(dists[i, i], dists[j, j])
        end
        # 0-dimensional persistence should find values of minima and maxima of our data.
        res = first(ripserer(dists, dim_max=0))
        mins = birth.(res)
        maxs = death.(filter(isfinite, res))
        @test sort(mins) == [-1.0, 0.0, 0.0, 0.5]
        @test sort(maxs) == [1.0, 2.0]
    end
end
