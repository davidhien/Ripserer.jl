var documenterSearchIndex = {"docs":
[{"location":"api/#API-1","page":"API","title":"API","text":"","category":"section"},{"location":"api/#","page":"API","title":"API","text":"ripserer","category":"page"},{"location":"api/#Ripserer.ripserer","page":"API","title":"Ripserer.ripserer","text":"ripserer(dists::AbstractMatrix{T}; dim_max=1, modulus=2, threshold=typemax(T))\nripserer(points, metric; dim_max=1, modulus=2, threshold=typemax(T))\n\nCompute the persistent homology of metric space represented by dists or points and metric.\n\nKeyoword Arguments\n\ndim_max: compute persistent homology up to this dimension.\nmodulus: compute persistent homology with coefficients in the prime field of integers            mod modulus.\nthreshold: compute persistent homology up to diameter smaller than threshold. Defaults to radius of input space.\nsparse: if true, use SparseRipsFiltration. Defaults to issparse(dists).\n\n\n\n\n\nripserer(filtration::AbstractFiltration)\n\nCompute persistent homology from filtration object.\n\n\n\n\n\n","category":"function"},{"location":"api/#","page":"API","title":"API","text":"RipsFiltration","category":"page"},{"location":"api/#Ripserer.RipsFiltration","page":"API","title":"Ripserer.RipsFiltration","text":"RipsFiltration{T, S<:AbstractSimplex{<:Any, T}} <: AbstractFlagFiltration{T, S}\n\nConstructor\n\nRipsFiltration(distance_matrix;\n               modulus=2,\n               threshold=default_rips_threshold(dist),\n               simplex_type=Simplex{modulus, T})\n\n\n\n\n\n","category":"type"},{"location":"api/#","page":"API","title":"API","text":"SparseRipsFiltration","category":"page"},{"location":"api/#Ripserer.SparseRipsFiltration","page":"API","title":"Ripserer.SparseRipsFiltration","text":"SparseRipsFiltration{T, S<:AbstractSimplex{<:Any, T}} <: AbstractFlagFiltration{T, S}\n\nThis type holds the information about the input values. The distance matrix will be converted to a sparse matrix with all values greater than threshold deleted. Off-diagonal zeros in the matrix are treated as typemax(T).\n\nConstructor\n\nSparseRipsFiltration(distance_matrix;\n                     modulus=2,\n                     threshold=default_rips_threshold(dist),\n                     eltype=Simplex{modulus, T})\n\n\n\n\n\n","category":"type"},{"location":"api/#Adding-New-Simplex-Types-1","page":"API","title":"Adding New Simplex Types","text":"","category":"section"},{"location":"api/#","page":"API","title":"API","text":"AbstractSimplex","category":"page"},{"location":"api/#Ripserer.AbstractSimplex","page":"API","title":"Ripserer.AbstractSimplex","text":"AbstractSimplex{C, T}\n\nAn abstract type for representing simplices. A simplex is represented by its diameter, combinatorial index and coefficient value. It does not need to hold information about its dimension or the vertices it includes.\n\nT is the type of distance and C is the coefficient type.\n\nInterface\n\nindex(::AbstractSimplex)\ncoef(::AbstractSimplex)\nset_coef(::AbstractSimplex{C}, ::C)\ndiam(::AbstractSimplex)\n\n\n\n\n\n","category":"type"},{"location":"api/#","page":"API","title":"API","text":"index(::AbstractSimplex)","category":"page"},{"location":"api/#Ripserer.index-Tuple{AbstractSimplex}","page":"API","title":"Ripserer.index","text":"index(simplex::AbstractSimplex)\n\nGet the combinatorial index of simplex. The index of is equal to\n\n(i_d i_d-1  1) mapsto sum_k=1^d+1 binomi_k - 1k\n\nwhere i_k are the simplex vertex indices.\n\n\n\n\n\n","category":"method"},{"location":"api/#","page":"API","title":"API","text":"coef","category":"page"},{"location":"api/#Ripserer.coef","page":"API","title":"Ripserer.coef","text":"coef(simplex::AbstractSimplex)\n\nGet the coefficient value of simplex.\n\n\n\n\n\n","category":"function"},{"location":"api/#","page":"API","title":"API","text":"set_coef","category":"page"},{"location":"api/#Ripserer.set_coef","page":"API","title":"Ripserer.set_coef","text":"set_coef(simplex::AbstractSimplex, value)\n\nReturn new simplex with new coefficient value.\n\n\n\n\n\n","category":"function"},{"location":"api/#","page":"API","title":"API","text":"diam(::AbstractSimplex)","category":"page"},{"location":"api/#Ripserer.diam-Tuple{AbstractSimplex}","page":"API","title":"Ripserer.diam","text":"diam(simplex::AbstractSimplex)\n\nGet the diameter of simplex.\n\n\n\n\n\n","category":"method"},{"location":"api/#Adding-New-Filtration-Types-1","page":"API","title":"Adding New Filtration Types","text":"","category":"section"},{"location":"api/#","page":"API","title":"API","text":"AbstractFiltration","category":"page"},{"location":"api/#Ripserer.AbstractFiltration","page":"API","title":"Ripserer.AbstractFiltration","text":"AbstractFiltration{T, S<:AbstractSimplex{C, T}}\n\nAn abstract type that holds information about the distances between vertices and the simplex type.\n\nInterface\n\nn_vertices(::AbstractFiltration) - return number of vertices in filtration.\nedges(::AbstractFiltration) - return all edges in filtration as (l, (i, j)) where l is the edge length and i and j are its endpoints.\ndiam(::AbstractFiltration, vs) - diameter of simplex with vertices in vs. Should return Infinity() if simplex is above threshold.\ndiam(::AbstractFiltration, sx::AbstractSimplex, vs, u) - diameter of simplex sx with vertices in vs and an added vertex u. Should return Infinity() if simplex is above threshold.\nSparseArrays.issparse(::Type{A}) where A<:AbstractFiltration - optional, defaults to false. Should be true if most of the simplices are expected to be skipped.\n\n\n\n\n\n","category":"type"},{"location":"api/#","page":"API","title":"API","text":"AbstractFlagFiltration","category":"page"},{"location":"api/#Ripserer.AbstractFlagFiltration","page":"API","title":"Ripserer.AbstractFlagFiltration","text":"AbstractFlagFiltration{T, S} <: AbstractFiltration{T, S}\n\nAn abstract flag filtration is a filtration of flag complexes. Its subtypes can overload dist(::AbstractFlagFiltration{T}, u, v)::Union{T, Infinity} instead of diam. diam(::AbstractFlagFiltration, ...) defaults to maximum dist among vertices.\n\n\n\n\n\n","category":"type"},{"location":"api/#","page":"API","title":"API","text":"n_vertices","category":"page"},{"location":"api/#Ripserer.n_vertices","page":"API","title":"Ripserer.n_vertices","text":"n_vertices(filtration::AbstractFiltration)\n\nNumber of vertices in filtration.\n\n\n\n\n\n","category":"function"},{"location":"api/#","page":"API","title":"API","text":"edges","category":"page"},{"location":"api/#Ripserer.edges","page":"API","title":"Ripserer.edges","text":"edges(filtration::AbstractFiltration)\n\nGet edges in distance matrix in filtration, sorted by decresing length and increasing combinatorial index.\n\n\n\n\n\n","category":"function"},{"location":"api/#","page":"API","title":"API","text":"diam(::AbstractFiltration, ::Any)","category":"page"},{"location":"api/#Ripserer.diam-Tuple{AbstractFiltration,Any}","page":"API","title":"Ripserer.diam","text":"diam(flt::AbstractFiltration, vertices)\ndiam(flt::AbstractFiltration, vertices, vertex)\n\nGet the diameter of list of vertices i.e. diameter of simplex with vertices. If additional vertex is given, only calculate max distance from vertices to vertex.\n\n\n\n\n\n","category":"method"},{"location":"api/#","page":"API","title":"API","text":"SparseArrays.issparse(::AbstractFiltration)","category":"page"},{"location":"api/#SparseArrays.issparse-Tuple{AbstractFiltration}","page":"API","title":"SparseArrays.issparse","text":"SparseArrays.issparse(::Type{A}) where A<:AbstractFiltration\n\nReturn true if A is a sparse filtration. A filtration should be sparse if most simplices are to be skipped. Defaults to false.\n\n\n\n\n\n","category":"method"},{"location":"#Ripserer.jl-1","page":"Home","title":"Ripserer.jl","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"Efficient computation of persistent homology.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"A Julia reimplementation of the ripser algorithm for persistent homology. This package is not a direct translation and might do or name some things differently.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Ripserer's performance is generally around 2 times slower than ripser, but in some cases, it performs just as well or even better.","category":"page"}]
}
