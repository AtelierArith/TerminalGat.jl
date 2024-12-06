module TerminalGat

using InteractiveUtils: gen_call_with_extracted_types
using Markdown: Markdown

using gat_jll: gat_jll
export gat, gess, @gess, @code, @gode

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
    io = IOBuffer()
    open(pipeline(`$(gat_jll.gat()) --theme monokai --force-color --lang julia`), "w", io) do f
        println(f, str)
    end
    # If docstring contains an example about REPL session, we color `julia` as red `38;5;197m` that is used in the original `gat` command.
    colored_text = replace(String(take!(io)), "julia" => "\033[38;5;197mjulia\033[0m")
    print(colored_text)
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
    io = IOBuffer()
    open(pipeline(`$(gat_jll.gat()) --theme monokai --force-color --lang julia`), "w", io) do f
        println(f, str)
    end
    (String(take!(io))) |> pager
end

gess(f, @nospecialize t)  = gess(functionloc(f,t)...)

macro gess(ex0)
    ex = gen_call_with_extracted_types(__module__, :gess, ex0)
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
            expr = Meta.parse(join(lines[1:n], "\n"), raise = true)
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
    gode(Function, types)

Print the definition of a function
"""
function gode(args...)
    file, linenum = functionloc(args...)
    lines = readlines(file)[linenum:end]
    str = extractcode(lines)
    io = IOBuffer()
    open(pipeline(`$(gat_jll.gat()) --theme monokai --force-color --lang julia`), "w", io) do f
        println(f, str)
    end
    print(String(take!(io)))
end

"""
    gode(Function, types)

Print the definition of a function
"""
function code(args...)
    file, linenum = functionloc(args...)
    lines = readlines(file)[linenum:end]
    str = extractcode(lines)
    print(str)
end

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
It calls out to the `gode` function.
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

end # module
