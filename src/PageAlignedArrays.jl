module PageAlignedArrays
using Compat
export PageAlignedArray, PageAlignedVector, PageAlignedMatrix

"""
    mutable struct PageAlignedArray{T,N} <: AbstractArray{T,N}
An `N`-dimensional array of eltype `T` which is guaranteed to have its memory be page-aligned.
This is a mutable struct because finalizers are used to clean up the memory allocated
by C calls when there remain no references to the PageAlignedArray object in Julia.
"""
mutable struct PageAlignedArray{T,N} <: AbstractArray{T,N}
    backing::Array{T,N}
    addr::Ptr{T}

    PageAlignedArray{T,1}(a::Integer) where {T} = PageAlignedArray{T,1}((a,))
    PageAlignedArray{T,2}(a::Integer, b::Integer) where {T} = PageAlignedArray{T,0}((a,b))
    PageAlignedArray{T,3}(a::Integer, b::Integer, c::Integer) where {T} =
        PageAlignedArray{T,3}((a,b,c))

    function PageAlignedArray{T,N}(dims::NTuple{N,Integer}) where {T,N}
        n = N == 0 ? 1 : reduce(*, dims)
        addr = virtualalloc(sizeof(T) * n, T)
        backing = unsafe_wrap(Array, addr, dims, own=false)
        array = new{T,N}(backing, addr)
        @compat finalizer(x->virtualfree(x.addr), array)
        return array
    end
end
PageAlignedArray{T}(dims::Integer...) where {T} = PageAlignedArray{T,length(dims)}(dims)
const PageAlignedVector{T} = PageAlignedArray{T,1}
const PageAlignedMatrix{T} = PageAlignedArray{T,2}

Base.size(A::PageAlignedArray) = size(A.backing)
Base.IndexStyle(::Type{<:PageAlignedArray}) = Base.IndexLinear()
Base.getindex(A::PageAlignedArray, idx...) = A.backing[idx...]
Base.setindex!(A::PageAlignedArray, v, idx...) = setindex!(A.backing, v, idx...)
Base.length(A::PageAlignedArray) = length(A.backing)
Base.unsafe_convert(::Type{Ptr{T}}, A::PageAlignedArray{T}) where {T} =
    Base.unsafe_convert(Ptr{T}, A.backing)

"""
    virtualalloc(size_bytes::Integer, ::Type{T}) where {T}
Allocate page-aligned memory and return a `Ptr{T}` to the allocation. The caller is
responsible for de-allocating the memory using `virtualfree`, otherwise it will leak.
"""
function virtualalloc(size_bytes::Integer, ::Type{T}) where {T}
    @static Base.Sys.iswindows() ? begin
        MEM_COMMIT = 0x1000
        PAGE_READWRITE = 0x4
        addr = ccall((:VirtualAlloc, "Kernel32"), Ptr{T},
            (Ptr{Cvoid}, Csize_t, Culong, Culong),
            C_NULL, size_bytes, MEM_COMMIT, PAGE_READWRITE)
    end : @static Base.Sys.islinux() ? begin
        addr = ccall(:valloc, Ptr{T}, (Csize_t,), size_bytes)
    end : @static Base.Sys.isapple() ? begin
        addr = ccall((:valloc, "libSystem.dylib"), Ptr{T}, (Csize_t,), size_bytes)
    end : throw(SystemError())

    addr == C_NULL && throw(OutOfMemoryError())
    return addr::Ptr{T}
end

"""
    virtualfree(addr::Ptr{T}) where {T}
Free memory that has been allocated using `virtualalloc`. Undefined, likely very bad
behavior if called on a pointer coming from elsewhere.
"""
function virtualfree(addr::Ptr{T}) where {T}
    @static Base.Sys.iswindows() ? begin
        MEM_RELEASE = 0x8000
        return ccall((:VirtualFree, "Kernel32"), Cint, (Ptr{Cvoid}, Csize_t, Culong),
            addr, 0, MEM_RELEASE)
    end : @static Base.Sys.islinux() ? begin
        return ccall(:free, Cvoid, (Ptr{Cvoid},), addr)
    end : @static Base.Sys.isapple() ? begin
        return ccall((:free, "libSystem.dylib"), Cvoid, (Ptr{Cvoid},), addr)
    end : error("OS not supported")
end
end # module
