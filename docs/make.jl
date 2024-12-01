using TerminalGat
using Documenter

DocMeta.setdocmeta!(TerminalGat, :DocTestSetup, :(using TerminalGat); recursive=true)

makedocs(;
    modules=[TerminalGat],
    authors="Satoshi Terasaki <terasakisatoshi.math@gmail.com> and contributors",
    sitename="TerminalGat.jl",
    format=Documenter.HTML(;
        canonical="https://atelierarith.github.io/TerminalGat.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/AtelierArith/TerminalGat.jl",
    devbranch="main",
)
