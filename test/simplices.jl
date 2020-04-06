using Ripserer: Simplex,index, coef, set_coef, diam, vertices, inv_mod

@testset "simplices" begin
    @testset "Simplex" begin
        for M in (2, 17, 7487)
            for i in (1, 536, typemax(Int32))
                c = rand(Int64)
                d = rand(Float64)
                @test index(Simplex{M}(d, i, c)) == i
                @test coef(Simplex{M}(d, i, c)) == mod(c, M)
                @test diam(Simplex{M}(d, i, c)) == d
            end
        end
        @test_throws DomainError Simplex{-3}(rand(), 1, 1)
        @test_throws DomainError Simplex{7497}(rand(), 1, 1)
    end

    @testset "index(::Vector), vertices" begin
        st = ReductionState{2}(rand_dist_matrix(10), 5)
        @test vertices(st, Simplex{2}(rand(), 1, 1), 2) == [3, 2, 1]
        @test vertices(st, Simplex{2}(rand(), 2, 1), 3) == [5, 3, 2, 1]
        @test vertices(st, Simplex{2}(rand(), 3, 1), 1) == [3, 2]
        @test vertices(st, Simplex{2}(rand(), 4, 1), 4) == [6, 5, 4, 2, 1]
        @test vertices(st, Simplex{2}(rand(), 5, 1), 2) == [5, 2, 1]

        for i in 1:10
            @test index(st, vertices(st, Simplex{2}(rand(), i, 1), 5)) == i
        end
    end

    @testset "set_coef" begin
        @test set_coef(Simplex{3}(1, 2, 1), 2) == Simplex{3}(1, 2, 2)
        @test set_coef(Simplex{2}(2, 2, 1), 3) == Simplex{2}(2, 2, 1)
    end

    @testset "arithmetic" begin
        @test Simplex{3}(1.0, 3, 2) * 2 == Simplex{3}(1.0, 3, 1)
        @test 2 * Simplex{3}(2.0, 3, 2) == Simplex{3}(2.0, 3, 1)
        @test -Simplex{5}(10, 1, 1) == Simplex{5}(10, 1, 4)

        @test inv_mod(Val(2), 1) == 1
        @test_throws DomainError inv_mod(Val(4), 1)
        @test_throws DivideError inv_mod(Val(3), 0)

        for i in 1:16
            @test Simplex{17}(i*10, 10, i) / i == Simplex{17}(i*10, 10, 1)
            @test -Simplex{17}(i*10, 8, i) == Simplex{17}(i*10, 8, 17 - i)
        end
    end
end
