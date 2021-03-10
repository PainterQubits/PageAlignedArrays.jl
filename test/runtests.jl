using PageAlignedArrays
using Test
using Mmap


p = PageAlignedVector{Int}(512)
@test (p[:] = 1) == 1
@test eltype(p) == Int
@test @inferred(p[1]) == 1
@test all(p .== 1)
@test length(p) == 512
@test size(p) == (512,)
@test Base.IndexStyle(p) == Base.IndexLinear()

@test Integer(pointer(p)) % Mmap.PAGESIZE == 0
