# PageAlignedArrays

[![Build Status](https://travis-ci.org/ajkeller34/PageAlignedArrays.jl.svg?branch=master)](https://travis-ci.org/ajkeller34/PageAlignedArrays.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/953iyvhr2520hahg?svg=true)](https://ci.appveyor.com/project/ajkeller34/pagealignedarrays-jl)
[![Coverage Status](https://coveralls.io/repos/ajkeller34/PageAlignedArrays.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/ajkeller34/PageAlignedArrays.jl?branch=master)
[![codecov.io](http://codecov.io/github/ajkeller34/PageAlignedArrays.jl/coverage.svg?branch=master)](http://codecov.io/github/ajkeller34/PageAlignedArrays.jl?branch=master)

A `PageAlignedArray{T,N}` is an `N`-dimensional array of eltype `T` which is guaranteed to have its memory be
page-aligned. This has to be a mutable struct because finalizers are used to clean up the
memory allocated by C calls when there remain no references to the PageAlignedArray object
in Julia. Two convenient aliases are provided: `PageAlignedVector{T} = PageAlignedArray{T,1}`
and `PageAlignedMatrix{T} = PageAlignedArray{T,2}`.

These arrays should not be preferred in ordinary circumstances. However, some streaming
DMA (direct memory access) peripherals may require a block of memory to be allocated on a
page boundary, and therefore having an array in Julia that satisfies this requirement can be
useful.
