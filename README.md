# Ripserer.jl

_Flexible and efficient persistent homology computation._

[![Coverage Status](https://coveralls.io/repos/github/mtsch/Ripserer.jl/badge.svg?branch=master)](https://coveralls.io/github/mtsch/Ripserer.jl?branch=master)
[![Build Status](https://github.com/mtsch/Ripserer.jl/workflows/Test/badge.svg)](https://github.com/mtsch/Ripserer.jl/actions?query=workflow%3ATest)
[![Documentation](https://img.shields.io/badge/docs-latest-blue.svg)](https://mtsch.github.io/Ripserer.jl/dev)
[![status](https://joss.theoj.org/papers/0c8b6abead759ba068ee178fedc998a9/status.svg)](https://joss.theoj.org/papers/0c8b6abead759ba068ee178fedc998a9)

![](docs/src/assets/title_plot.svg)

Ripserer is a pure Julia implementation of the [ripser](https://github.com/Ripser/ripser)
algorithm for computing persistent homology. It aims to provide an easy to use, generic and
fast implementation of persistent homology.

See the [docs](https://mtsch.github.io/Ripserer.jl/dev) for more info and usage examples.

If you're looking for persistence diagram-related functionality such as matching distances,
persistence images, or persistence curves, please see
[PersistenceDiagrams.jl](https://github.com/mtsch/PersistenceDiagrams.jl).

## Installation

This package is registered. To install it, run the following.

```julia
julia> using Pkg
julia> Pkg.add("Ripserer")
```
