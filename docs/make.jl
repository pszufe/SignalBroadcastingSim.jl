using Documenter

try
    using ZombieCar
catch
    if !("../src/" in LOAD_PATH)
       push!(LOAD_PATH,"../src/")
       @info "Added \"../src/\"to the path: $LOAD_PATH "
       using ZombieCar
    end
end

makedocs(
    sitename = "ZombieCar",
    format = format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    modules = [ZombieCar],
    pages = ["index.md", "reference.md"],
    doctest = true
)

deploydocs(
    repo ="github.com/jacfilip/ZombieCar.jl.git",
    target="build"
)
