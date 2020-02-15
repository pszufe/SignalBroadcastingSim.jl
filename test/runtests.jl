using Test, Random
using SignalBroadcastingSim

@testset "start" begin

Random.seed!(0)

@test rand(Int) == -4635026124992869592
@test 1+2 == 3

end 

