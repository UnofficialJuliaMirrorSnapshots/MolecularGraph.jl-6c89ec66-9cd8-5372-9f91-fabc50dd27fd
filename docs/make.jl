
using Documenter, MolecularGraph


makedocs(
    sitename="MolecularGraph.jl",
    pages = [
        "Home" => "index.md",
        "MolecularGraph" => [
            "I/O" => "moleculargraph/io.md",
            "Structure drawing" => "moleculargraph/draw.md",
            "Basic chemical properties" => "moleculargraph/properties.md",
            "Molecular descriptor" => "moleculargraph/descriptor.md",
            "Preprocessing" => "moleculargraph/preprocess.md",
            "Structure match" => "moleculargraph/structure.md"
        ],
        "GraphModel" => [
            "Models" => "graph/model.md",
            "Interface" => "graph/interface.md",
            "Generator" => "graph/generator.md",
            "Shortest path" => "graph/shortestpath.md",
            "Line graph" => "graph/linegraph.md",
            "Connectivity" => "graph/connectivity.md",
            "Planarity" => "graph/planarity.md",
            "Clique" => "graph/clique.md"
        ],
        "Python interface" => "python.md",
        "Design of molecular graph models" => "design.md"
    ]
)

deploydocs(repo="github.com/mojaie/MolecularGraph.jl.git")
