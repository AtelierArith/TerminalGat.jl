var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = TerminalGat","category":"page"},{"location":"#TerminalGat","page":"Home","title":"TerminalGat","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for TerminalGat.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [TerminalGat]","category":"page"},{"location":"#TerminalGat.code-Tuple{IO, Vararg{Any}}","page":"Home","title":"TerminalGat.code","text":"gode([io::IO], f, types)\n\nPrint a code giving the location of a generic Function definition.\n\n\n\n\n\n","category":"method"},{"location":"#TerminalGat.extractcode-Tuple{Vector{String}}","page":"Home","title":"TerminalGat.extractcode","text":"extractcode(lines::Vector{String})\n\nExtract code that reporensents the definition of a function from lines, scanning lines line by line using Meta.parse.\n\n\n\n\n\n","category":"method"},{"location":"#TerminalGat.gat-Tuple{AbstractString}","page":"Home","title":"TerminalGat.gat","text":"gat(filename::AbstractString)\n\nHightlight text This is a thin wrapper for gat command written in Go.\n\nif filename is a Markdown, the --render-markdown option is added.\n\nExample\n\njulia> using TerminalGat\njulia> gat(\"README.md\")\njulia> gat(\"src/TerminalGat.jl\")\n\nIf your terminal supports Sixel, you can display images in your terminal\n\njulia> using TerminalGat\njulia> using Plots; plot(sin); savefig(\"sin.png\")\njulia> gat(\"sin.png\")\n\n\n\n\n\n","category":"method"},{"location":"#TerminalGat.gat-Tuple{Markdown.MD}","page":"Home","title":"TerminalGat.gat","text":"gat(md::Markdown.MD)\n\nExample\n\nHightlight docstrings with monokai theme\n\njulia> gat(@doc sin)\n\n\n\n\n\n","category":"method"},{"location":"#TerminalGat.gess-Tuple{AbstractString}","page":"Home","title":"TerminalGat.gess","text":"gess(filename::AbstractString)\n\ngess works something like gat + less:\n\njulia> using TerminalGat\njulia> gess(\"Project.toml\")\n\n\n\n\n\n","category":"method"},{"location":"#TerminalGat.gess-Tuple{Markdown.MD}","page":"Home","title":"TerminalGat.gess","text":"gat(md::Markdown.MD)\n\nExample\n\njulia> gess(@doc sin)\n\n\n\n\n\n","category":"method"},{"location":"#TerminalGat.gode-Tuple{IO, Vararg{Any}}","page":"Home","title":"TerminalGat.gode","text":"gode(io::IO, f, types)\n\nPrint a code giving the location of a generic Function definition with syntax highlighting by gat command.\n\n\n\n\n\n","category":"method"},{"location":"#TerminalGat.@code-Tuple{Any}","page":"Home","title":"TerminalGat.@code","text":"@gode(ex0)\n\nApplied to a function or macro call, it evaluates the arguments to the specified call, and returns code giving the location for the method that would be called for those arguments.  It calls out to the code function.\n\n\n\n\n\n","category":"macro"},{"location":"#TerminalGat.@gearch-Tuple{Any}","page":"Home","title":"TerminalGat.@gearch","text":"@gearch f [mod]\n\nIt works like methods(f, [mod::Module]) with the Fizzy Finder feature.  Then print a highlighted code that gives the method definition of f specified by the user.\n\n\n\n\n\n","category":"macro"},{"location":"#TerminalGat.@gode-Tuple{Any}","page":"Home","title":"TerminalGat.@gode","text":"@gode(ex0)\n\nApplied to a function or macro call, it evaluates the arguments to the specified call, and returns code giving the location for the method that would be called for those arguments.  It calls out to the gode function.\n\n\n\n\n\n","category":"macro"},{"location":"#TerminalGat.@search-Tuple{Any}","page":"Home","title":"TerminalGat.@search","text":"@search f [mod]\n\nIt works like methods(f, [mod::Module]) with the Fizzy Finder feature.  Then print a code that gives the method definition of f specified by the user.\n\n\n\n\n\n","category":"macro"}]
}
