var documenterSearchIndex = {"docs":
[{"location":"api/#API-1","page":"API","title":"API","text":"","category":"section"},{"location":"api/#","page":"API","title":"API","text":"ripserer","category":"page"},{"location":"api/#Ripserer.ripserer","page":"API","title":"Ripserer.ripserer","text":"ripserer(dists::AbstractMatrix{T}; dim_max=1, modulus=2, threshold=typemax(T))\n\nCompute the persistent homology of metric space represented by dists.\n\nKeyoword Arguments\n\ndim_max: compute persistent homology up to this dimension.\nmodulus: compute persistent homology with coefficients in the prime field of integers            mod modulus.\nthreshold: compute persistent homology up to diameter smaller than threshold.              Defaults to radius of input space.\n\n\n\n\n\nripserer(filtration::AbstractFiltration)\n\nCompute persistent homology from filtration object.\n\n\n\n\n\n","category":"function"},{"location":"api/#","page":"API","title":"API","text":"RipsFiltration","category":"page"},{"location":"api/#Ripserer.RipsFiltration","page":"API","title":"Ripserer.RipsFiltration","text":"RipsFiltration{T, S<:AbstractSimplex{<:Any, T}}\n\nThis type holds the information about the input values. The distance matrix has to be a dense matrix.\n\nConstructor\n\nRipsFiltration(distance_matrix;\n               dim_max=1,\n               modulus=2,\n               threshold=default_threshold(dist),\n               eltype=Simplex{modulus, T})\n\n\n\n\n\n","category":"type"},{"location":"api/#","page":"API","title":"API","text":"SparseRipsFiltration","category":"page"},{"location":"api/#Ripserer.SparseRipsFiltration","page":"API","title":"Ripserer.SparseRipsFiltration","text":"SparseRipsFiltration{T, S<:AbstractSimplex{<:Any, T}}\n\nThis type holds the information about the input values. The distance matrix will be converted to a sparse matrix with all values greater than threshold deleted. Off-diagonal zeros in the matrix are treaded as typemax(T).\n\nConstructor\n\nSparseRipsFiltration(distance_matrix;\n                     dim_max=1,\n                     modulus=2,\n                     threshold=default_threshold(dist),\n                     eltype=Simplex{modulus, T})\n\n\n\n\n\n","category":"type"},{"location":"api/#Adding-New-Simplex-Types-1","page":"API","title":"Adding New Simplex Types","text":"","category":"section"},{"location":"api/#","page":"API","title":"API","text":"AbstractSimplex","category":"page"},{"location":"api/#Ripserer.AbstractSimplex","page":"API","title":"Ripserer.AbstractSimplex","text":"AbstractSimplex{C, T}\n\nAn abstract type for representing simplices. A simplex is represented by its diameter, combinatorial index and coefficient value. It does not need to hold information about its dimension or the vertices it includes.\n\nT is the type of distance and C is the coefficient type.\n\nInterface\n\nindex(::AbstractSimplex)\ncoef(::AbstractSimplex)\nset_coef(::AbstractSimplex{C}, ::C)\ndiam(::AbstractSimplex)\n\n\n\n\n\n","category":"type"},{"location":"api/#","page":"API","title":"API","text":"index(::AbstractSimplex)","category":"page"},{"location":"api/#Ripserer.index-Tuple{AbstractSimplex}","page":"API","title":"Ripserer.index","text":"index(simplex::AbstractSimplex)\n\nGet the combinatorial index of simplex. The index of is equal to\n\n(i_d i_d-1  1) mapsto sum_k=1^d+1 binomi_k - 1k\n\nwhere i_k are the simplex vertex indices.\n\n\n\n\n\n","category":"method"},{"location":"api/#","page":"API","title":"API","text":"coef","category":"page"},{"location":"api/#Ripserer.coef","page":"API","title":"Ripserer.coef","text":"coef(simplex::AbstractSimplex)\n\nGet the coefficient value of simplex.\n\n\n\n\n\n","category":"function"},{"location":"api/#","page":"API","title":"API","text":"set_coef","category":"page"},{"location":"api/#Ripserer.set_coef","page":"API","title":"Ripserer.set_coef","text":"set_coef(simplex::AbstractSimplex, value)\n\nReturn new simplex with new coefficient value.\n\n\n\n\n\n","category":"function"},{"location":"api/#","page":"API","title":"API","text":"diam(::AbstractSimplex)","category":"page"},{"location":"api/#Ripserer.diam-Tuple{AbstractSimplex}","page":"API","title":"Ripserer.diam","text":"diam(simplex::AbstractSimplex)\n\nGet the diameter of simplex.\n\n\n\n\n\n","category":"method"},{"location":"api/#Adding-New-Filtration-Types-1","page":"API","title":"Adding New Filtration Types","text":"","category":"section"},{"location":"api/#","page":"API","title":"API","text":"AbstractFiltration","category":"page"},{"location":"api/#Ripserer.AbstractFiltration","page":"API","title":"Ripserer.AbstractFiltration","text":"AbstractFiltration{T, S<:AbstractSimplex{C, T}}\n\nAn abstract type that holds information about the distances between vertices and the simplex type.\n\nInterface\n\nBase.length(::AbstractFiltration)\ndist(::AbstractFiltration, ::Integer, ::Integer)\nedges(::AbstractFiltration)\ndim_max(::AbstractFiltration)\ndiam(::AbstractFiltration, iterable) - optional, defaults to diameter of vertex set.\nBase.binomial(::AbstractFiltration, n, k) - optional, but recommended.\nthreshold(::AbstractFiltration) - optional, defaults to typemax(T).\n\n\n\n\n\n","category":"type"},{"location":"api/#","page":"API","title":"API","text":"length(::AbstractFiltration)","category":"page"},{"location":"api/#Base.length-Tuple{AbstractFiltration}","page":"API","title":"Base.length","text":"length(filtration::AbstractFiltration)\n\nNumber of vertices in filtration.\n\n\n\n\n\n","category":"method"},{"location":"api/#","page":"API","title":"API","text":"dist","category":"page"},{"location":"api/#Ripserer.dist","page":"API","title":"Ripserer.dist","text":"dist(filtration::AbstractFiltration, i, j)\n\nGet the distance between vertex i and vertex j.\n\n\n\n\n\n","category":"function"},{"location":"api/#","page":"API","title":"API","text":"edges","category":"page"},{"location":"api/#Ripserer.edges","page":"API","title":"Ripserer.edges","text":"edges(filtration::AbstractFiltration)\n\nGet edges in distance matrix in filtration, sorted by decresing length and increasing combinatorial index.\n\n\n\n\n\n","category":"function"},{"location":"api/#","page":"API","title":"API","text":"dim_max","category":"page"},{"location":"api/#Ripserer.dim_max","page":"API","title":"Ripserer.dim_max","text":"dim_max(filtration::AbstractFiltration)\n\nGet the maximum dimension of simplices in filtration.\n\n\n\n\n\n","category":"function"},{"location":"api/#","page":"API","title":"API","text":"diam(::AbstractFiltration, ::Any)","category":"page"},{"location":"api/#Ripserer.diam-Tuple{AbstractFiltration,Any}","page":"API","title":"Ripserer.diam","text":"diam(flt::AbstractFiltration, vertices)\ndiam(flt::AbstractFiltration, vertices, vertex)\n\nGet the diameter of list of vertices i.e. diameter of simplex with vertices. If additional vertex is given, only calculate max distance from vertices to vertex.\n\n\n\n\n\n","category":"method"},{"location":"api/#","page":"API","title":"API","text":"binomial(::AbstractFiltration, ::Any, ::Any)","category":"page"},{"location":"api/#Base.binomial-Tuple{AbstractFiltration,Any,Any}","page":"API","title":"Base.binomial","text":"binomial(filtration::AbstractFiltration, n, k)\n\nAn abstract filtration may have binomial coefficients precomputed for better performance.\n\n\n\n\n\n","category":"method"},{"location":"api/#","page":"API","title":"API","text":"threshold","category":"page"},{"location":"api/#Ripserer.threshold","page":"API","title":"Ripserer.threshold","text":"threshold(flt::AbstractFiltration)\n\nGet the threshold of flt. Simplices with diameter strictly larger than this value will be ignored.\n\n\n\n\n\n","category":"function"},{"location":"api/#","page":"API","title":"API","text":"SparseArrays.issparse(::AbstractFiltration)","category":"page"},{"location":"api/#SparseArrays.issparse-Tuple{AbstractFiltration}","page":"API","title":"SparseArrays.issparse","text":"SparseArrays.issparse(::Type{A}) where A<:AbstractFiltration\n\nReturn true if A is a sparse filtration. A filtration should be sparse if most simplices are to be skipped. Defaults to false.\n\n\n\n\n\n","category":"method"},{"location":"#Ripserer.jl-1","page":"Home","title":"Ripserer.jl","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"Efficient computation of persistent homology.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"A Julia reimplementation of the ripser algorithm for persistent homology. This package is not a direct translation and might do or name some things differently.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Ripserer's performance is generally around 2 times slower than ripser, but in some cases, it performs just as well or even better.","category":"page"}]
}
