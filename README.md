# [TerminalGat](https://github.com/AtelierArith/TerminalGat.jl) [![Build Status](https://github.com/AtelierArith/TerminalGat.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/AtelierArith/TerminalGat.jl/actions/workflows/CI.yml?query=branch%3Amain) [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://AtelierArith.github.io/TerminalGat.jl/stable/) [![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://AtelierArith.github.io/TerminalGat.jl/dev/) [![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

## TL;DR

[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code&size=16&duration=1500&pause=200&color=10F748&multiline=true&width=700&height=200&lines=julia%3E+%23+How+to+use;julia%3E+using+TerminalGat;julia%3E+gat(%22main.jl%22)+;julia%3E+gess(%22main.jl%22)+%23+gat+%2B+less;julia%3E+%40less+%40show+x+%23+InteractiveUtils.jl;julia%3E+%40gess+%40show+x+%23+gat+%2B+%40less;julia%3E+%40code+%40show+x;julia%3E+%40gode+%40show+x+%23+gat+%2B+%40code)](https://git.io/typing-svg)

## Description

[TerminalGat.jl](https://github.com/AtelierArith/TerminalGat.jl) provides a Julia interface to [`gat`](https://github.com/koki-develop/gat). It displays files and images in the Julia REPL.

## Setup

- Install Julia, then run the `julia` command in your terminal.

```sh
$ julia
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.10.3 (2024-04-30)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org/ release
|__/                   |

julia> using Pkg; Pkg.add("TerminalGat")
```

## How to use

https://github.com/user-attachments/assets/6c251619-7669-4170-afe0-dbb699f39390

`TerminalGat.jl` exports:

- `gat`
- `gess`
- `@gess`
- `@code`
- `@gode`
- `@search`
- `@gearch`

### `gat`

```julia
julia> using TerminalGat
julia> gat("Project.toml")
```

If your terminal supports Sixel, you can display images.

```julia
julia> using TerminalGat
julia> using Plots; plot(sin); savefig("sin.png")
julia> gat("sin.png")
```

### `gess`

`gess` works something like `gat` + `less`:

```julia
julia> using TerminalGat
julia> gess("Project.toml")
```

`gess` uses [TerminalPager.jl](https://github.com/ronisbr/TerminalPager.jl) to browse highlighted content.

### `@gess`, `@code`, `@gode`

The `@gess` macro works like `InteractiveUtils.@less`, but highlights Julia code:

```julia-repl
julia> @gess sin(1.0)
```

It opens the source file at the selected method's definition. You can scroll up to see earlier lines and down to see the rest of the file. TerminalPager provides navigation and search; press `?` for help and `q` to quit.

<img width="864" alt="image" src="https://github.com/user-attachments/assets/956925ae-ace7-4e53-8b93-3ca3b08d22f1">

The `@code` macro extracts a method definition from the source code that defines the method.

The `@gode` macro works like `@code`, but highlights Julia code.

<img width="552" alt="image" src="https://github.com/user-attachments/assets/a261fd09-30a0-4f14-84e3-ab9db1eae7fb">

### `@search`, `@gearch`

The `@search` macro works like [tkf/InteractiveCodeSearch.jl](https://github.com/tkf/InteractiveCodeSearch.jl), allowing you to choose a method definition to read.

The `@gearch` macro works like `@search`, with syntax highlighting by `gat`.

https://github.com/user-attachments/assets/fef6b270-1ec3-4a04-a3a8-9213cb4883ee
