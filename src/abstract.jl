# simplex arithmetic ===================================================================== #
Base.isless(sx1, sx2) =
    diam(sx1) < diam(sx2) || diam(sx1) == diam(sx2) && index(sx1) > index(sx2)

Base.:+(sx1::A, sx2::A) where A<:AbstractSimplex =
    set_coef(sx1, coef(sx1) + coef(sx2))
Base.:-(sx1::A, sx2::A) where A<:AbstractSimplex =
    set_coef(sx1, coef(sx1) - coef(sx2))
Base.:*(sx::AbstractSimplex, λ::Number) =
    set_coef(sx, coef(sx) * λ)
Base.:*(λ::Number, sx::AbstractSimplex) =
    set_coef(sx, λ::Number * coef(sx))
Base.:-(sx::AbstractSimplex) =
    set_coef(sx, -coef(sx))
Base.:/(sx::AbstractSimplex{C}, λ::Number) where C =
    set_coef(sx, coef(sx) * inv(C(λ)))

# filtration stuff ======================================================================= #
function index(flt::AbstractFiltration, vertices)
    res = 0
    for l in eachindex(vertices)
        res += binomial(flt, vertices[end - l + 1] - 1, l)
    end
    res + 1
end

@propagate_inbounds function diam(flt::AbstractFiltration, vertices)
    n = length(vertices)
    res = typemin(disttype(flt))
    for i in 1:n, j in i+1:n
        d = dist(flt, vertices[j], vertices[i])
        res = ifelse(res > d, res, d)
        res > threshold(flt) && return infinity(flt)
    end
    res
end

"""
    max_dist(filtration, vertices, vertex)

Get the maximum distance from `vertices` to `vertex`.
"""
@propagate_inbounds function max_dist(flt::AbstractFiltration, us, v::Integer)
    res = typemin(disttype(flt))
    for u in us
        d = dist(flt, u, v)
        res = ifelse(res > d, res, d)
        res > threshold(flt) && return infinity(flt)
    end
    res
end

"""
    find_max_vertex(filtration, idx, k)

Find largest vertex index of vertex for which `binomial(i, k) ≤ idx` holds.
"""
@propagate_inbounds function find_max_vertex(flt::AbstractFiltration, idx, k, n_max)
    hi = n_max + 1
    lo = k - 1
    while lo < hi - 1
        m = lo + ((hi - lo) >>> 0x01)
        if binomial(flt, m, k) ≤ idx
            lo = m
        else
            hi = m
        end
    end
    lo
end

"""
    get_vertices!(filtration, index)

Copy vertices of simplex with `index` to `filtration`'s vertex cache.
"""
function get_vertices!(flt::AbstractFiltration, index, dim)
    resize!(flt.vertex_cache, dim + 1)
    index = index - 1
    v = length(flt)
    @inbounds for (i, k) in enumerate(dim+1:-1:1)
        v = find_max_vertex(flt, index, k, v-1)

        flt.vertex_cache[i] = v + 1
        index -= binomial(flt, v, k)
        n_max = v - 1
    end
    flt.vertex_cache
end

"""
    vertices(filtration, simplex, dim)

    vertices(filtration, index, dim)

Get vertices of `simplex`. Vertices are only recomputed when the vertex cache in
`filtration` is invalid.
"""
vertices(flt::AbstractFiltration{<:Any, S}, sx::S, dim) where S =
    vertices(flt, index(sx), dim)
function vertices(flt::AbstractFiltration, idx::Integer, dim)
    # Calculating index from vertices is so much faster that this is worth doing.
    if length(flt.vertex_cache) != dim+1 || index(flt, flt.vertex_cache) != idx
        get_vertices!(flt, idx, dim)
    end
    flt.vertex_cache
end

# coboundary ============================================================================= #
struct CoboundaryIterator{A, S<:AbstractSimplex, F<:AbstractFiltration{<:Any, S}}
    filtration ::F
    simplex    ::S
    dim        ::Int

    function CoboundaryIterator{A}(flt, sx, dim) where A
        dim ≤ flt.dim_max + 1 || throw(ArgumentError("`dim` is larger than `dim_max + 1`"))
        new{A, typeof(sx), typeof(flt)}(flt, sx, dim)
    end
end

Base.IteratorSize(::Type{CoboundaryIterator}) =
    Base.SizeUnknown()
Base.IteratorEltype(::Type{CoboundaryIterator}) =
    Base.HasEltype()
Base.eltype(::Type{CoboundaryIterator{<:Any, S}}) where S =
    S

"""
    coboundary(filtration, simplex, dim, [all_cofaces])

Return an iterator that iterates over all cofaces of `simplex` of dimension `dim + 1` in
decreasing order by index.

If `all_cofaces` is `::Val{false}`, only return cofaces where the added vertex has an index
higher than all other vertices. This is used in sparse `assemble_columns!` to find all
simplices.
"""
coboundary(flt::AbstractFiltration, simplex::AbstractSimplex, dim, ::Val{false}) =
    CoboundaryIterator{false}(flt, simplex, dim)
coboundary(flt::AbstractFiltration, simplex::AbstractSimplex, dim) =
    CoboundaryIterator{true}(flt, simplex, dim)

function Base.iterate(ci::CoboundaryIterator{all_cofaces},
                      st = (length(ci.filtration), ci.dim + 1,
                            index(ci.simplex) - 1, 0)) where all_cofaces
    # bounds are checked in constructor
    @inbounds begin
        v, k, idx_below, idx_above = st
        v -= 1
        if !all_cofaces && binomial(ci.filtration, v, k) ≤ idx_below
            return nothing
        end
        while v > 0 && v ≥ k && binomial(ci.filtration, v, k) ≤ idx_below
            idx_below -= binomial(ci.filtration, v, k)
            idx_above += binomial(ci.filtration, v, k + 1)
            v -= 1; k -= 1
        end
        if v < k
            nothing
        else
            vxs = vertices(ci.filtration, ci.simplex, ci.dim)
            diameter = max(diam(ci.simplex), max_dist(ci.filtration, vxs, v+1))

            coefficient = ifelse(k % 2 == 1, -coef(ci.simplex), coef(ci.simplex))
            new_index = idx_above + binomial(ci.filtration, v, k + 1) + idx_below + 1
            S = eltype(ci.filtration)

            S(diameter, new_index, coefficient), (v, k, idx_below, idx_above)
        end
    end
end
