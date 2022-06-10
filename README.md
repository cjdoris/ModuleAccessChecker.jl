# ModuleAccessChecker.jl

Experimental Julia package to wrap a module so that only API can be accessed.

Properties not considered to be API can throw errors or warning when accessed. Accesses are
as fast as accessing the original module.

By default, only exported functions are considered to be API. You can pass a whitelist of
property names to extend this list.

If you are relying on internal non-API functions from a module, you can add those to the
whitelist too. In this way, which internals are being used is recorded in one place.

## Install

```julia-repl
pkg> add https://github.com/cjdoris/ModuleAccessChecker.jl
```

## Usage

```julia
ModuleAccessChecker.wrap(@__MODULE__, src_module, [wrapped_module_name])
```

Wrap the `src_module` as a new object called `wrapped_module_name` such that property access
can show warnings or throw errors for properties not considered to be API.

The default name is the name of `src_module` prefixed with `X`. For example `Base` is
wrapped as `XBase`

### Keyword Arguments
- `default_level::Symbol=:error`: The default way to treat property access. One of:
  - `:ignore`: Do nothing, allow the access.
  - `:error`: Throw an error.
  - `:warn`: Show a warning, allow the access.
  - `:debug`: Log a debug message, allow the access.
- `whitelist::Vector{Symbol}=[]`: List of properties to allow (these have level `:ignore`).
- `allow_exported::Bool=true`: Include all exported properties in the whitelist.
- `levels::Dict{Symbol,Symbol}=Dict()`: Mapping of properties to levels.

### Example

```julia-repl
julia> using ModuleAccessChecker, BenchmarkTools

julia> ModuleAccessChecker.wrap(@__MODULE__, :Base, default_level=:warn)

julia> XBase.modules_warned_for
┌ Warning: modules_warned_for is not part of the API
└ @ Main [...]/ModuleAccessChecker/src/ModuleAccessChecker.jl:38
Set{Base.PkgId}()
```
