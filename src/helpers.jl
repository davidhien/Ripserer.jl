# compressed sparse matrix =============================================================== #
"""
    CompressedSparseMatrix{T}

Compressed immutable sparse matrix data structure that supports efficient column insertion,
pushing to the last column via [`push!`](@ref) and iterating over columns.

It's up to the value type `T` to know about its row position.
"""
struct CompressedSparseMatrix{T}
    colptr::Vector{Int}
    nzval::Vector{T}
end

CompressedSparseMatrix{T}() where T =
    CompressedSparseMatrix(Int[1], T[])

function Base.show(io::IO, csm::CompressedSparseMatrix{T}) where T
    println(io, "CompressedSparseMatrix{$T}[")
    for i in 1:length(csm)
        println(io, "  $i: ", collect(csm[i]))
    end
    print(io, "]")
end

function Base.push!(csm::CompressedSparseMatrix, value)
    push!(csm.nzval, value)
    csm.colptr[end] += 1
    value
end

add_column!(csm::CompressedSparseMatrix) =
    push!(csm.colptr, csm.colptr[end])
Base.eltype(csm::CompressedSparseMatrix{T}) where T =
    T
Base.length(csm::CompressedSparseMatrix) =
    length(csm.colptr) - 1
Base.getindex(csm::CompressedSparseMatrix, i) =
    CSMColumnIterator(csm, i)

struct CSMColumnIterator{T}
    csm ::CompressedSparseMatrix{T}
    idx ::Int
end

Base.IteratorSize(::Type{CSMColumnIterator}) =
    Base.HasLength()
Base.IteratorEltype(::Type{CSMColumnIterator{T}}) where T =
    Base.HasEltype()
Base.eltype(::Type{CSMColumnIterator{T}}) where T =
    T
Base.length(ci::CSMColumnIterator) =
    ci.csm.colptr[ci.idx + 1] - ci.csm.colptr[ci.idx]

function Base.iterate(ci::CSMColumnIterator, i=1)
    colptr = ci.csm.colptr
    index = i + colptr[ci.idx] - 1
    if index ≥ colptr[ci.idx + 1]
        nothing
    else
        (ci.csm.nzval[index], i + 1)
    end
end
# state ================================================================================== #
"""
    isprime(n)

Return `true` if `n` is a prime number.
"""
function isprime(n)
    if iseven(n) || n < 2
        n == 2
    else
        p = 3
        q = n / p
        while p ≤ q
            iszero(n % p) && return false
            p += 2
            q = n / p
        end
        true
    end
end

"""
    Binomial(n_max, k_max)

Table of precomputed binomial coefficients up to `n_max` and `k_max`. Can be called like a
function and should be identical to [`binomial`](@ref) for values of `0 ≤ n ≤ n_max` and
`0 ≤ k ≤ k_max`
"""
struct Binomial
    table::Matrix{Int64}
end

function Binomial(n, k)
    table = zeros(Int, n+1, k+1)
    for i in 1:n+1
	table[i, 1] = 1;
	for j in 2:min(i, k+1)
	    table[i, j] = table[i-1, j-1] + table[i-1, j];
	    if (i <= k)
                table[i, i] = 1
            end
        end
    end
    Binomial(table)
end

Base.show(io::IO, bin::Binomial) =
    print(io, "Binomial$(size(bin.table) .- 1)")
(bin::Binomial)(n, k) =
    bin.table[n+1, k+1]

"""
    ReductionState{M, T, A<:AbstractArray{T}}

This type holds the information about the current state in reduction algorithm.

# Constructor

    ReductionState(distance_matrix, dim, modulus)

"""
struct ReductionState{M, T, A<:AbstractArray{T}}
    dist         ::A
    binomial     ::Binomial
    dim          ::Ref{Int}
    vertex_cache ::Vector{Int}
end

function ReductionState(dist::A, dim::Int, modulus::Int) where {T, A<:AbstractArray{T}}
    is_distance_matrix(dist) ||
        throw(ArgumentError("`dist` must be a distance matrix"))
    isprime(modulus) ||
        throw(ArgumentError("`modulus` must be prime"))
    dim ≥ 0 ||
        throw(ArgumentError("`dim` must be positive"))
    ReductionState{modulus, T, A}(dist, Binomial(size(dist, 1), dim+2),
                                  Ref(dim), Int[])
end

"""
    n_vertices(reduction_state)

Get number of vertices in `reduction_state`.
"""
n_vertices(st::ReductionState) =
    size(st.dist, 1)

dim(st::ReductionState) =
    st.dim[]

function set_dim!(st::ReductionState, dim)
    @warn "TODO: Binomial not updated!"
    st.dim[] = dim
end

"""
    dist(reduction_state, i, j)

Get the distance between vertex `i` and vertex `j`.
"""
dist(st::ReductionState, i, j) =
    st.dist[i, j] # should return Inf?

"""
    diam(reduction_state, vertices)

Get diameter of vertex set `vertices`.
"""
function diam(st::ReductionState, vertices)
    @warn "test me if you use me"
    n = n_vertices(st)
    maximum(dist(st, i, j) for i in 1:n-1 for j in i+1:n)
end

"""
    is_connected(reduction_state, vertex, vertices)

Check if `vertex` is connected to `vertices` i.e. if the distance to all other vertices
is ≥ 0. If `vertex in vertices`, this function returns `false`.
"""
is_connected(st::ReductionState, vertex, vertices) =
    !any(iszero, dist(st, v, vertex) for v in vertices)

Base.binomial(st::ReductionState, n, k) =
    st.binomial(n, k)

# distance matrix stuff ================================================================== #
"""
    edge_lt(e1, e2) =

Compare edges like DiameterSimplexComparer.

* by increasing diameter,
* by decreasing combinatorial index.
"""
edge_lt((e1, i1), (e2, i2)) =
    e1 < e2 || e1 == e2 && i1 > i2

"""
    edges(reduction_state)

Get edges in distance matrix in `reduction_state`,
sorted by decresing length and increasing index.
"""
edges(rs::ReductionState) =
    edges(rs.dist)

function edges(dist::AbstractMatrix{T}) where T
    n = size(dist, 1)
    res = Tuple{T, Tuple{Int, Int}}[]
    for j in 1:n, i in j+1:n
        push!(res, (dist[i, j], (i, j)))
    end
    sort!(res, lt=edge_lt)
end

function edges(dist::AbstractSparseMatrix{T}) where T
    res = Tuple{T, Tuple{Int, Int}}[]
    I, J, V = findnz(dist)
    for (i, j) in zip(I, J)
        i > j || continue
        push!(res, (dist[i, j], (i, j)))
    end
    sort!(res, lt=edge_lt)
end

"""
    is_distance_matrix(dist)

Return true if dist is a valid distance matrix.
"""
is_distance_matrix(dist) =
    issymmetric(dist) && all(iszero(dist[i, i]) for i in 1:size(dist, 1))

"""
    apply_threshold(dist, thresh)

Convert matrix `dist` to sparse matrix with no entries larger than `thresh`.
"""
function apply_threshold(dist, thresh)
    n = size(dist, 1)
    for i in 1:n, j in i+1:n
        if dist[i, j] > thresh
            dist[i, j] = dist[j, i] = 0
        end
    end
    if dist isa SparseMatrixCSC
        dropzeros!(dist)
    else
        sparse(dist)
    end
end
