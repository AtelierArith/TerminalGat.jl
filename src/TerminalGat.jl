module TerminalGat

using InteractiveUtils: gen_call_with_extracted_types
using Markdown: Markdown

using gat_jll: gat_jll
export gat, gess, @gess, @code, @gode, @search, @gearch

using JLFzf: inter_fzf
using IOCapture: IOCapture
using TerminalPager: pager

"""
    gat(filename::AbstractString)

Hightlight text This is a thin wrapper for `gat` command written in Go.

if `filename` is a Markdown, the `--render-markdown` option is added.

# Example

```julia-repl
julia> using TerminalGat
julia> gat("README.md")
julia> gat("src/TerminalGat.jl")
```

If your terminal supports Sixel, you can display images in your terminal

```julia-repl
julia> using TerminalGat
julia> using Plots; plot(sin); savefig("sin.png")
julia> gat("sin.png")
```
"""
function gat(filename::AbstractString)
    if splitext(filename)[end] == ".md"
        run(`$(gat_jll.gat()) --render-markdown $(filename) --force-color`)
    else
        run(`$(gat_jll.gat()) $(filename) --force-color`)
    end
    nothing
end

"""
    gat(md::Markdown.MD)

# Example

Hightlight docstrings with monokai theme

```julia-repl
julia> gat(@doc sin)
```
"""
function gat(md::Markdown.MD)
    str = sprint(show, MIME"text/plain"(), md, context=:color => false)
    colored_text = colorize_by_gat(str)
    # If docstring contains an example about REPL session, we color `julia` as red `38;5;197m` that is used in the original `gat` command.
    # gat(@doc TerminalGat) reads README.md which may contain a Julia prompt `julia>`
    colored_text = replace(colored_text, "julia>" => "\033[38;5;197mjulia>\033[0m")
    # gat(@doc sin) reads Markdown which may contain highlighted Julia prompt "julia\e[0m\e[38;5;197m>\e[0m"
    colored_text = replace(
        colored_text,
        "julia\e[0m\e[38;5;197m>\e[0m" => "\033[38;5;197mjulia>\033[0m",
    )
    # display(colored_text) # <-- use for debugging.
    print(colored_text)
end

function colorize_by_gat(str::AbstractString)
    buf = IOBuffer()
    open(
        pipeline(`$(gat_jll.gat()) --theme monokai --force-color --lang julia`),
        "w",
        buf,
    ) do tmp
        println(tmp, str)
    end
    String(take!(buf))
end

"""
    extractcode(lines::Vector{String})

Extract code that reporensents the definition of a function from `lines`, scanning
`lines` line by line using `Meta.parse`.
"""
function extractcode(lines::Vector{String})
    r = -1
    for n in eachindex(lines)
        try
            expr = Meta.parse(join(lines[1:n], "\n"), raise=true)
            if expr.head !== :incomplete
                r = n
                break
            end
        catch e
            e isa Meta.ParseError && continue
        end
    end
    join(lines[begin:r], "\n")
end

"""
    gess(filename::AbstractString)

`gess` works something like `gat` + `less`:

```julia-repl
julia> using TerminalGat
julia> gess("Project.toml")
```
"""
function gess(filename::AbstractString)
    c = IOCapture.capture() do
        gat(filename)
    end
    c.output |> pager
end

function gess(filename::AbstractString, line::Integer)
    lines = open(filename, "r") do f
        for _ in 1:line-1
            readline(f)
        end
        lines = readlines(f)
    end
    str = join(lines, "\n")
    colorize_by_gat(str) |> pager
end

gess(f, @nospecialize t) = gess(functionloc(f, t)...)

macro gess(ex0)
    ex = gen_call_with_extracted_types(__module__, :gess, ex0)
end

###
# code and gode
# @code and @gode
###

"""
    gode(io::IO, f, types)

Print a code giving the location of a generic Function definition
with syntax highlighting by gat command.
"""
function gode(io::IO, args...)
    file, linenum = functionloc(args...)
    lines = readlines(file)[linenum:end]
    str = extractcode(lines)
    print(io, colorize_by_gat(str))
end

"""
    gode([io::IO], f, types)

Print a code giving the location of a generic Function definition.
"""
function code(io::IO, args...)
    file, ln = functionloc(args...)
    lines = readlines(file)[ln:end]
    str = extractcode(lines)
    print(io, str)
end

code(args...) = (@nospecialize; code(stdout, args...))
gode(args...) = (@nospecialize; gode(stdout, args...))

"""
    @gode(ex0)

Applied to a function or macro call, it evaluates the arguments to the specified call, and returns code giving the location for the method that would be called for those arguments. 
It calls out to the `gode` function.
"""
macro gode(ex0)
    ex = gen_call_with_extracted_types(__module__, :gode, ex0)
end

"""
    @gode(ex0)

Applied to a function or macro call, it evaluates the arguments to the specified call, and returns code giving the location for the method that would be called for those arguments. 
It calls out to the `code` function.
"""
macro code(ex0)
    ex = gen_call_with_extracted_types(__module__, :code, ex0)
end

"""
    gat(md::Markdown.MD)

# Example

```julia-repl
julia> gess(@doc sin)
```
"""
function gess(md::Markdown.MD)
    c = IOCapture.capture() do
        gat(md)
    end
    c.output |> pager
end

########
# search and gearch
# @search and @gearch
########

function search(io::IO, args...)
    ms = methods(args...)
    x = inter_fzf(ms, "--read0")
    if isempty(x)
        error("could not determine location of method definition")
    end
    file_line = last(split(x))
    file, ln_str = split(file_line, ":")
    ln = Base.parse(Int, ln_str)
    if ln <= 0 || isempty(x)
        error("could not determine location of method definition")
    else
        file, ln = (Base.find_source_file(expanduser(string(file))), ln)
        lines = readlines(file)[ln:end]
        str = extractcode(lines)
        print(io, str)
    end
end

function gearch(io::IO, args...)
    ms = methods(args...)
    x = inter_fzf(ms, "--read0")
    if isempty(x)
        error("could not determine location of method definition")
    end
    file_line = last(split(x))
    file, ln_str = split(file_line, ":")
    ln = Base.parse(Int, ln_str)
    if ln <= 0 || isempty(x)
        error("could not determine location of method definition")
    else
        file, ln = (Base.find_source_file(expanduser(string(file))), ln)
        lines = readlines(file)[ln:end]
        str = extractcode(lines)
        colored_str = colorize_by_gat(str)
        print(io, colored_str)
    end
end

search(args...) = (@nospecialize; search(stdout, args...))

function search(@nospecialize(f),
    mod::Union{Module,AbstractArray{Module},Nothing}=nothing)
    # return all matches
    return search(f, Tuple{Vararg{Any}}, mod)
end

gearch(args...) = (@nospecialize; gearch(stdout, args...))

function gearch(@nospecialize(f),
    mod::Union{Module,AbstractArray{Module},Nothing}=nothing)
    # return all matches
    return gearch(f, Tuple{Vararg{Any}}, mod)
end

macro search(fn::Symbol)
    :(search($(esc(fn))))
end

macro gearch(fn::Symbol)
    :(gearch($(esc(fn))))
end

"""
    @search f [mod]

It works like `methods(f, [mod::Module])` with the Fizzy Finder feature. 
Then print a code that gives the method definition of f specified by the user.
"""
macro search(fn::Symbol, mod::Symbol)
    :(search($(esc(fn)), $(esc(mod))))
end

"""
    @gearch f [mod]

It works like `methods(f, [mod::Module])` with the Fizzy Finder feature. 
Then print a highlighted code that gives the method definition of f specified by the user.
"""
macro gearch(fn::Symbol, mod::Symbol)
    :(gearch($(esc(fn)), $(esc(mod))))
end

end # module
