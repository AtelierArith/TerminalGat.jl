using Test
using TerminalGat
using Aqua
using JET

@testset "Aqua" begin
    Aqua.test_all(TerminalGat, ambiguities = false)
    Aqua.test_ambiguities(TerminalGat, exclude=[TerminalGat.search, TerminalGat.gearch]) 
end

@testset "JET" begin
    JET.report_package(TerminalGat, target_defined_modules=true)
end
