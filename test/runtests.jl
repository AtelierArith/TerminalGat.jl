using Test
using TerminalGat
using Aqua
using JET

@testset "Aqua" begin
    Aqua.test_all(TerminalGat)
end

@testset "search requires a function after an output stream" begin
    for search in (TerminalGat.search, TerminalGat.gearch), mod in (nothing, Main, [Main])
        @test_throws ArgumentError search(IOBuffer(), mod)
    end
end

@testset "JET" begin
    JET.report_package(TerminalGat, target_modules=(TerminalGat,))
end

@testset "source pager" begin
    using TerminalPager
    input = IOBuffer("\e[Aq")
    output = IOBuffer()
    term = TerminalGat.REPL.Terminals.TTYTerminal("", input, output, output)
    TerminalGat._start!(term, "first\nsecond\nthird", 2;
        manage_cursor_key_mode = false, manage_mouse = false, _waiter_factory = _ -> nothing)
    screen = String(take!(output))
    @test occursin("second", screen)
    @test occursin("first", screen)
    @test findfirst("second", screen) < findlast("first", screen)
    @test occursin("\e[?1049l", screen)
end
