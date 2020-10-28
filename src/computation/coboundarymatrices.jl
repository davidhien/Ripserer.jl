"""
    CoboundaryMatrix{I}

This `struct` is used to compute cohomology. The `I` parameter sets whether the implicit
algoritm is used or not.
"""
struct CoboundaryMatrix{I,T,F,S,R,C}
    filtration::F
    reduced::R
    chain::C
    columns_to_reduce::Vector{S}
    columns_to_skip::Vector{S}
end

function CoboundaryMatrix{I}(
    ::Type{T}, filtration, columns_to_reduce, columns_to_skip
) where {I,T}
    Simplex = eltype(columns_to_reduce)
    Cofacet = simplex_type(filtration, dim(Simplex) + 1)
    ordering = Base.Order.Forward
    SimplexElem = chain_element_type(Simplex, T)
    CofacetElem = chain_element_type(Cofacet, T)

    if I
        reduced = ReducedMatrix{Cofacet,SimplexElem}(ordering)
    else
        reduced = ReducedMatrix{Cofacet,CofacetElem}(ordering)
    end
    sizehint!(reduced, length(columns_to_reduce))
    chain = WorkingChain{CofacetElem}(ordering)

    return CoboundaryMatrix{I,T,typeof(filtration),Simplex,typeof(reduced),typeof(chain)}(
        filtration, reduced, chain, columns_to_reduce, columns_to_skip
    )
end

field_type(::CoboundaryMatrix{<:Any,T}) where {T} = T
dim(cm::CoboundaryMatrix{<:Any,<:Any,<:Any,S}) where {S} = dim(S)
function chain_element_type(bm::CoboundaryMatrix{<:Any,T,F}) where {T,F}
    return chain_element_type(simplex_type(F, dim(bm) + 1), T)
end

is_implicit(::CoboundaryMatrix{I}) where {I} = I
is_cohomology(::CoboundaryMatrix) = true

function coboundary(matrix::CoboundaryMatrix, simplex::AbstractSimplex)
    return coboundary(matrix.filtration, simplex)
end

function next_matrix(matrix::CoboundaryMatrix{I}, progress) where {I}
    C = simplex_type(matrix.filtration, dim(matrix) + 1)
    new_to_reduce = C[]
    new_to_skip = C[]
    sizehint!(new_to_skip, length(matrix.reduced))

    if progress
        progbar = ProgressUnknown("Assembling columns:")
    end
    for simplex in columns_to_reduce(
        matrix.filtration,
        Iterators.flatten((matrix.columns_to_reduce, matrix.columns_to_skip)),
    )
        if haskey(matrix.reduced, simplex)
            push!(new_to_skip, abs(simplex))
        else
            push!(new_to_reduce, abs(simplex))
        end
        progress && next!(
            progbar;
            showvalues=(
                ("cleared", length(new_to_skip)), ("to reduce", length(new_to_reduce))
            ),
        )
    end
    prog_print(progress, '\r')

    return CoboundaryMatrix{I}(
        field_type(matrix), matrix.filtration, new_to_reduce, new_to_skip
    )
end

"""
    BoundaryMatrix{I}

This `struct` is used to compute homology. The `I` parameter sets whether the implicit
algoritm is used or not.
"""
struct BoundaryMatrix{I,T,F,S,R,C}
    filtration::F
    reduced::R
    chain::C
    columns_to_reduce::Vector{S}
end

function BoundaryMatrix{I}(::Type{T}, filtration, columns_to_reduce) where {I,T}
    if eltype(columns_to_reduce) === Any
        Simplex = typeof(first(columns_to_reduce))
    else
        Simplex = eltype(columns_to_reduce)
    end
    Facet = simplex_type(filtration, dim(Simplex) - 1)
    ordering = Base.Order.Reverse
    SimplexElem = chain_element_type(Simplex, T)
    FacetElem = chain_element_type(Facet, T)

    columns = Simplex[]
    foreach(columns_to_reduce) do c
        push!(columns, abs(c))
    end

    if !I
        reduced = ReducedMatrix{Facet,FacetElem}(ordering)
    else
        reduced = ReducedMatrix{Facet,SimplexElem}(ordering)
    end
    sizehint!(reduced, length(columns))
    chain = WorkingChain{FacetElem}(ordering)

    return BoundaryMatrix{I,T,typeof(filtration),Simplex,typeof(reduced),typeof(chain)}(
        filtration, reduced, chain, columns
    )
end

field_type(::BoundaryMatrix{<:Any,T}) where {T} = T
dim(bm::BoundaryMatrix{<:Any,<:Any,<:Any,S}) where {S} = dim(S) - 1
function chain_element_type(bm::BoundaryMatrix{<:Any,T,F}) where {T,F}
    return chain_element_type(simplex_type(F, dim(bm)), T)
end

is_implicit(::BoundaryMatrix{I}) where {I} = I
is_cohomology(::BoundaryMatrix) = false

# The naming here is not ideal...
function coboundary(matrix::BoundaryMatrix, simplex::AbstractSimplex)
    return boundary(matrix.filtration, simplex)
end

"""
    initialize_coboundary!(matrix, column)

Initialize the column indexed by `column` by adding its (co)boundary to `matrix.chain`. This
is where the emergent pairs optimization gets triggered for implicit versions of the
algorithm.

"""
function initialize_coboundary!(matrix, column)#=::Val{true},=#
    empty!(matrix.chain)
    # Emergent pairs: we are looking for pairs of simplices (σ, τ) where σ is the youngest
    # facet of τ and τ is the oldest cofacet of σ. These pairs give birth to persistence
    # intervals with zero length and can be skipped.

    # This implementation of this optimization only works if (co)boundary simplices are
    # returned in the correct order and if the birth times of σ and τ are the same.
    emergent_check = emergent_pairs(matrix.filtration) && is_implicit(matrix)
    for cofacet in coboundary(matrix, column)
        if emergent_check && birth(cofacet) == birth(column)
            emergent_check = false
            if !haskey(matrix.reduced, cofacet)
                return chain_element_type(matrix)(cofacet)
            end
        end
        nonheap_push!(matrix.chain, cofacet)
    end
    if isempty(matrix.chain)
        return nothing
    else
        repair!(matrix.chain)
        return pop!(matrix.chain)
    end
end

"""
    add!(matrix, column, pivot)

Add already reduced column indexed by `column` multiplied by `-coefficient(pivot)` to
`matrix.chain`.

"""
function add!(matrix, column, pivot)
    return add!(Val(is_implicit(matrix)), matrix, column, pivot)
end
# Implicit version
function add!(::Val{true}, matrix, column, pivot)
    factor = -coefficient(pivot)
    for element in column
        for cofacet in coboundary(matrix, simplex(element))
            simplex(pivot) == cofacet && continue
            push!(
                matrix.chain,
                chain_element_type(matrix)(cofacet, coefficient(element) * factor),
            )
        end
    end
    return record!(matrix.reduced, column, factor)
end
# Explicit version
function add!(::Val{false}, matrix, column, pivot)
    factor = -coefficient(pivot)
    for element in column
        # The pivot is not stored in the column, so there is no need to check for it.
        push!(matrix.chain, element * factor)
    end
end

"""
    finalize!(matrix, column, pivot)

After reduction is done, finalize the column by adding it to the reduced matrix.
"""
function finalize!(matrix, column, pivot)
    return finalize!(Val(is_implicit(matrix)), matrix, column, pivot)
end
# Implicit version
function finalize!(::Val{true}, matrix, column, pivot)
    record!(matrix.reduced, column)
    return commit!(matrix.reduced, simplex(pivot), inv(coefficient(pivot)))
end
# Explicit version
function finalize!(::Val{false}, matrix, column, pivot)
    record!(matrix.reduced, matrix.chain)
    return commit!(matrix.reduced, simplex(pivot), inv(coefficient(pivot)))
end

"""
    reduce_column!(matrix, column_to_reduce)

Reduce `column_to_reduce` by repeatedly adding other columns to it. Once nothing more can be
added, `finalize!` the column.

"""
function reduce_column!(matrix, column_to_reduce)
    clear_buffer!(matrix.reduced)
    pivot = initialize_coboundary!(matrix, column_to_reduce)

    while !isnothing(pivot)
        column = matrix.reduced[pivot]
        isempty(column) && break

        add!(matrix, column, pivot)
        pivot = pop!(matrix.chain)
    end
    if !isnothing(pivot)
        finalize!(matrix, column_to_reduce, pivot)
    end

    return pivot
end

"""
    collect_cocycle!(matrix, pivot, reps)

Collect the representative (co)cycle.

TODO: clean this up.
"""
function collect_cocycle!(matrix, pivot)
    if is_cohomology(matrix)
        if isnothing(pivot)
            return copy(collect_buffer!(matrix.reduced))
        elseif is_implicit(matrix)
            return collect(matrix.reduced[pivot])
        else
            elem_t = chain_element_type(
                simplex_type(matrix.filtration, dim(matrix)), field_type(matrix)
            )
            tmp_chain = WorkingChain{elem_t}(Base.Order.Forward)
            for elem in matrix.reduced[pivot]
                for facet in boundary(matrix.filtration, simplex(elem))
                    push!(tmp_chain, elem_t(facet, coefficient(elem)))
                end
            end
            return move!(tmp_chain)
        end
    else
        if is_implicit(matrix)
            return pushfirst!(move!(matrix.chain), pivot)
        else
            return pushfirst!(collect(matrix.reduced[pivot]), pivot)
        end
    end
end

"""
    interval(matrix, column, pivot, cutoff, reps)

Construct a persistence interval.
"""
function interval(matrix, column, pivot, cutoff, reps)
    if is_cohomology(matrix)
        birth_simplex = column
        death_simplex = isnothing(pivot) ? nothing : simplex(pivot)
    elseif isnothing(pivot)
        # In homology, birth simplex is nothing when column is fully reduced.
        return nothing
    else
        birth_simplex, death_simplex = simplex(pivot), column
    end
    birth_time = Float64(birth(birth_simplex))
    death_time = isnothing(death_simplex) ? Inf : Float64(birth(death_simplex))
    if death_time - birth_time > cutoff
        if reps
            rep = (; representative=collect_cocycle!(matrix, pivot))
        else
            rep = NamedTuple()
        end
        meta = (; birth_simplex=birth_simplex, death_simplex=death_simplex, rep...)
        return PersistenceInterval(birth_time, death_time, meta)
    else
        return nothing
    end
end

"""
    handle_apparent_pairs!(matrix, intervals, cutoff, progress, reps)

Handle apparent pair precomputation, if defined for `matrix.filtration`. Only does anything
for implicit cohomology. Resulting intervals (if any) are `push!`ed to `intervals`.
"""
function handle_apparent_pairs!(matrix, intervals, cutoff, progress, reps)
    coho = Val(is_cohomology(matrix))
    impl = Val(is_implicit(matrix))
    return handle_apparent_pairs!(coho, impl, matrix, intervals, cutoff, progress, reps)
end
# Implicit cohomology version
function handle_apparent_pairs!(
    ::Val{true}, ::Val{true}, matrix, intervals, cutoff, progress, reps
)
    columns, apparent = find_apparent_pairs(
        matrix.filtration, matrix.columns_to_reduce, progress
    )
    bulk_add!(matrix.reduced, apparent)
    for (σ, τ) in apparent
        int = interval(matrix, σ, chain_element_type(matrix)(τ), cutoff, reps)
        !isnothing(int) && push!(intervals, int)
    end
    return columns
end
# Other versions
function handle_apparent_pairs!(::Val, ::Val, matrix, _, _, _, _)
    return matrix.columns_to_reduce
end

"""
    compute_intervals!(matrix, cutoff, progress, reps, sortres=true)

Compute all intervals by fully reducing `matrix`.
"""
function compute_intervals!(matrix, cutoff, progress, reps, sortres=true)
    ###
    ### Set up output.
    ###
    intervals = PersistenceInterval[]

    ###
    ### Apparent pair stuff.
    ###
    columns = handle_apparent_pairs!(matrix, intervals, cutoff, progress, reps)

    ###
    ### Interval computation.
    ###
    prog_print(
        progress,
        fmt_number(length(columns)),
        " ",
        (simplex_name(eltype(columns))),
        " to reduce.",
    )
    # One-dimensional columns in cohomology are already sorted.
    if !is_cohomology(matrix) || dim(matrix) > 1
        sort_t = time_ns()
        sort!(columns; rev=is_cohomology(matrix))
        elapsed = round((time_ns() - sort_t) / 1e9; digits=3)
        prog_println(progress, " Sorted in ", elapsed, "s)")
    else
        prog_println(progress)
    end

    if progress
        progbar = Progress(length(columns); desc="Computing $(dim(matrix))d intervals... ")
    end
    for column in columns
        pivot = reduce_column!(matrix, column)
        int = interval(matrix, column, pivot, cutoff, reps)
        !isnothing(int) && push!(intervals, int)

        progress && next!(progbar; showvalues=((:intervals, length(intervals)),))
    end

    return postprocess_diagram(
        matrix.filtration,
        PersistenceDiagram(
            sortres ? sort!(intervals; by=persistence) : intervals;
            threshold=Float64(threshold(matrix.filtration)),
            dim=dim(matrix),
            field_type=field_type(matrix),
            filtration=matrix.filtration,
        ),
    )
end

"""
    compute_death_simplices!(matrix::CoboundaryMatrix{true}, progress, cutoff)

Fully reduce `matrix`, but only compute (homological) death simplices. Return all death
simplices up to the last that produces an interval with persistence greater than `cutoff`.

Used for assisted homology.
"""
function compute_death_simplices!(matrix::CoboundaryMatrix{true}, progress, cutoff)
    columns, apparent = find_apparent_pairs(
        matrix.filtration, matrix.columns_to_reduce, progress
    )
    bulk_add!(matrix.reduced, apparent)
    deaths = simplex_type(matrix.filtration, dim(matrix) + 1)[]
    inf_births = simplex_type(matrix.filtration, dim(matrix))[]
    if isempty(columns)
        return deaths, inf_births
    else
        dim(matrix) > 1 && sort!(columns; rev=true)
        thresh = typemin(birth(first(columns)))
        for pair in apparent
            if birth(pair[2]) - birth(pair[1]) > cutoff
                thresh = max(thresh, birth(pair[2]))
            end
            push!(deaths, pair[2])
        end
        if progress
            progbar = Progress(length(columns); desc="Precomputing columns...   ")
        end
        for column in columns
            pivot = reduce_column!(matrix, column)
            if !isnothing(pivot)
                if birth(pivot) - birth(column) > cutoff
                    thresh = max(thresh, birth(pivot))
                end
                push!(deaths, simplex(pivot))
            else
                push!(inf_births, column)
            end
            progress && next!(progbar; showvalues=((:simplices, length(deaths)),))
        end
        return filter!(x -> birth(x) ≤ thresh, deaths), inf_births
    end
end
