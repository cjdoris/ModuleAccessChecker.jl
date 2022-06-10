module ModuleAccessChecker

"""
    wrap(@__MODULE__, src_module, [wrapped_module_name])

Wrap the `src_module` as a new object called `wrapped_module_name` such that property access
can show warnings or throw errors for properties not considered to be API.

The default name is the name of `src_module` prefixed with `X`. For example `Base` is
wrapped as `XBase`

# Keyword Arguments
- `default_level::Symbol=:error`: The default way to treat property access. One of:
  - `:ignore`: Do nothing, allow the access.
  - `:error`: Throw an error.
  - `:warn`: Show a warning, allow the access.
  - `:debug`: Log a debug message, allow the access.
- `whitelist::Vector{Symbol}=[]`: List of properties to allow (these have level `:ignore`).
- `allow_exported::Bool=true`: Include all exported properties in the whitelist.
- `levels::Dict{Symbol,Symbol}=Dict()`: Mapping of properties to levels.

# Example

```julia-repl
julia> using ModuleAccessChecker, BenchmarkTools

julia> ModuleAccessChecker.wrap(@__MODULE__, :Base, default_level=:warn)

julia> XBase.modules_warned_for
┌ Warning: modules_warned_for is not part of the API
└ @ Main [...]/ModuleAccessChecker/src/ModuleAccessChecker.jl:38
Set{Base.PkgId}()
```
"""
function wrap(
    eval_module::Module,
    src_module::Module,
    wrapped_module::Symbol=Symbol("X", nameof(src_module));
    default_level::Symbol=:error,
    allow_exported::Bool=true,
    whitelist::Vector{Symbol}=Symbol[],
    levels::Dict{Symbol,Symbol}=Dict{Symbol,Symbol}(),
)
    if allow_exported
        append!(whitelist, names(src_module, imported=true))
    end
    for k in whitelist
        get!(levels, k, :ignore)
    end
    wrapped_module_type = gensym(wrapped_module)
    code = []
    for (k, v) in levels
        msg = "$k is not part of the API"
        if v == :ignore
            warn = nothing
        elseif v == :error
            warn = :(Base.error($msg))
        elseif v == :warn
            warn = :(Base.@warn $msg)
        elseif v == :debug
            warn = :(Base.@debug $msg)
        else
            error("levels[$(repr(k))]=$(repr(v)) is an invalid level")
        end
        push!(code, :(if k == $(QuoteNode(k)); $warn; return $src_module.$k; end))
    end
    if default_level == :ignore
        warn = nothing
    elseif default_level == :error
        warn = :(Base.error("$k is not part of the API"))
    elseif default_level == :warn
        warn = :(Base.@warn "$k is not part of the API")
    elseif default_level == :debug
        warn = :(Base.@debug "$k is not part of the API")
    else
        error("default_level=$(repr(default_level)) is an invalid level")
    end
    push!(code, warn)
    push!(code, :(return Base.getproperty($src_module, k)))
    @eval eval_module begin
        struct $wrapped_module_type end
        const $wrapped_module = $wrapped_module_type()
        function Base.getproperty(m::$wrapped_module_type, k::Symbol)
            $(code...)
        end
        function Base.propertynames(m::$wrapped_module_type, private::Bool=false)
            return Base.propertynames($src_module, private)
        end
    end
end

end # module
