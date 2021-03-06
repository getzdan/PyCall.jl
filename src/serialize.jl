const _pickle = PyNULL()

pickle() = _pickle.o == C_NULL ? copy!(_pickle, pyimport(PyCall.pyversion.major ≥ 3 ? "pickle" : "cPickle")) : _pickle

function Base.serialize(s::AbstractSerializer, pyo::PyObject)
    Base.serialize_type(s, PyObject)
    if pyo.o == C_NULL
        serialize(s, pyo.o)
    else
        b = PyBuffer(pycall(pickle()["dumps"], PyObject, pyo))
        serialize(s, unsafe_wrap(Array, Ptr{UInt8}(pointer(b)), sizeof(b)))
    end
end

"""
    pybytes(b::Union{String,Vector{UInt8}})

Convert `b` to a Python `bytes` object.   This differs from the default
`PyObject(b)` conversion of `String` to a Python string (which may fail if `b`
does not contain valid Unicode), or from the default conversion of a
`Vector{UInt8}` to a `bytearray` object (which is mutable, unlike `bytes`).
"""
pybytes(b::Union{String,Array{UInt8}}) = PyObject(@pycheckn ccall(@pysym(PyString_FromStringAndSize),
                                                  PyPtr, (Ptr{UInt8}, Int),
                                                  b, sizeof(b)))

function Base.deserialize(s::AbstractSerializer, t::Type{PyObject})
    b = deserialize(s)
    if isa(b, PyPtr)
        @assert b == C_NULL
        return PyNULL()
    else
        return pycall(pickle()["loads"], PyObject, pybytes(b))
    end
end
