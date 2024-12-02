module TerminalGat

using InteractiveUtils: gen_call_with_extracted_types
using Markdown: Markdown

using gat_jll: gat_jll
export gat, gess

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
