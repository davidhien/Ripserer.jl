"""
    AbstractFiltration{I, T}

A filtration is used to find the edges in filtration and to create simplices. An
`AbstractFiltration{I, T}`'s simplex type is expected to return simplices of type
`<:AbstractSimplex{_, T, I}`.

# Interface

* [`n_vertices(::AbstractFiltration)`](@ref)
* [`edges(::AbstractFiltration)`](@ref)
* [`simplex_type(::AbstractFiltration, dim)`](@ref)
* [`simplex(::AbstractFiltration, ::Val{dim}, vertices, sign)`](@ref)
* [`unsafe_simplex(::AbstractFiltration, ::Val{dim}, vertices, sign)`](@ref)
* [`unsafe_cofacet`](@ref)`(::AbstractFiltration, simplex, vertices, vertex[, sign, edges])`
* [`birth(::AbstractFiltration, v)`](@ref)
* [`threshold(::AbstractFiltration)`](@ref)
* [`postprocess_interval(::AbstractFiltration, ::Any)`](@ref)
"""
abstract type AbstractFiltration{I, T} end

function Base.show(io::IO, flt::AbstractFiltration{I, T}) where {I, T}
    print(io, nameof(typeof(flt)), "{$I, $T}(n_vertices=$(n_vertices(flt)))")
end

"""
    simplex_type(::Type{<:AbstractFiltration}, D)
    simplex_type(::AbstractFiltration, D)

Return the `D`-dimensional simplex type in the filtration. Only the method for the type
needs to be overloaded.
"""
simplex_type(flt::AbstractFiltration, dim) = simplex_type(typeof(flt), dim)

vertex_type(flt::AbstractFiltration) = simplex_type(flt, 0)
edge_type(flt::AbstractFiltration) = simplex_type(flt, 1)

"""
    n_vertices(::AbstractFiltration)

Return the number of vertices in `filtration`.
"""
n_vertices(::AbstractFiltration)

"""
    edges(::AbstractFiltration)

Get edges (1-simplices) in `filtration`. Edges should be of type
[`simplex_type`](@ref)`(filtration, 1)`.
"""
edges(::AbstractFiltration)

"""
     simplex(::AbstractFiltration, ::Val{D}, vertices, sign=1)

Return `D`-simplex constructed from `vertices` with sign equal to `sign`. Return `nothing`
if simplex is not in filtration. This function is safe to call with vertices that are out of
order. Default implementation sorts `vertices` and calls [`unsafe_simplex`](@ref).
"""
function simplex(flt::AbstractFiltration, ::Val{D}, vertices, sign=1) where D
    vs = TupleTools.sort(Tuple(vertices), rev=true)
    if allunique(vs) && all(x -> x > 0, vs) && length(vs) == length(simplex_type(flt, D))
        return unsafe_simplex(flt, Val(D), vs, sign)
    else
        throw(ArgumentError("invalid vertices $(vertices)"))
    end
end

"""
    unsafe_simplex(::AbstractFiltration, ::Val{D}, vertices, sign=1)

Return `D`-simplex constructed from `vertices` with sign equal to `sign`. Return `nothing`
if simplex is not in filtration. The unsafe in the name implies that it's up to the caller
to ensure vertices are sorted and unique.
"""
function unsafe_simplex(flt, ::Val{D}, vertices, sign=1) where D
    return unsafe_simplex(simplex_type(typeof(flt), D), flt, vertices, sign)
end

"""
    unsafe_cofacet(filtration, simplex, cofacet_vertices, v, sign[, edges])
    unsafe_cofacet(::Type{S}, filtration, simplex, cofacet_vertices, v, sign[, edges])

Return cofacet of `simplex` with vertices equal to `cofacet_vertices`. `v` is the
vertex that was added to construct the cofacet. In the case of sparse rips filtrations, an
additional argument `edges` is used. `edges` is a vector that contains the weights on edges
connecting the new vertex to old vertices. `S` is the simplex type which can be used for
dispatch.

The unsafe in the name implies that it's up to the caller to ensure vertices are sorted and
unique.

Default implementation uses [`unsafe_simplex`](@ref).
"""
@inline @propagate_inbounds function unsafe_cofacet(flt, sx, args...)
    return unsafe_cofacet(simplex_type(typeof(flt), dim(sx) + 1), flt, sx, args...)
end
function unsafe_cofacet(::Type{S}, flt, _, vertices, _, sign, args...) where S
    return unsafe_simplex(flt, Val(dim(S)), vertices, sign)::Union{S, Nothing}
end

"""
    vertices(::AbstractFiltration)

Return the vertices in filtration. Defaults to `1:n`. The `eltype` of the result can be
anything as long as `result[result[i]] == result[i]` holds.
"""
vertices(flt::AbstractFiltration) = Base.OneTo(n_vertices(flt))

"""
    birth(::AbstractFiltration, v)
    birth(::AbstractFiltration)

Get the birth time of vertex `v` in filtration. Defaults to 0. When `v` is not given, return
births in an array of same size as [`vertices(::AbstractFiltration)`](@ref).
"""
birth(::AbstractFiltration{<:Any, T}, _) where T = zero(T)
birth(flt::AbstractFiltration{<:Any, T}) where T = zeros(T, size(vertices(flt)))

"""
    threshold(::AbstractFiltration)

Get the threshold of filtration. This is the maximum diameter a simplex in the filtration
can have. Defaults to `Inf`.
"""
threshold(::AbstractFiltration) = Inf

"""
    postprocess_interval(::AbstractFiltration, interval)

This function is called on each resulting persistence interval. The default implementation
does nothing.
"""
postprocess_interval(::AbstractFiltration, interval) = interval
