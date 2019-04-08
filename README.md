
MolecularGraph.jl
===================================================

[![Build Status](https://travis-ci.org/mojaie/MolecularGraph.jl.svg?branch=master)](https://travis-ci.org/mojaie/MolecularGraph.jl)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://mojaie.github.io/MolecularGraph.jl/dev)


<img src="./assets/image/demo.svg" width="200"/><img src="./assets/image/Acetohexamide.svg" width="200"/><img src="./assets/image/Bivalirudin.svg" width="200"/><img src="./assets/image/Cefmenoxime.svg" width="200"/><img src="./assets/image/Succinic acid.svg" width="200"/><img src="./assets/image/Quinacrine.svg" width="200"/><img src="./assets/image/Docetaxel.svg" width="200"/><img src="./assets/image/FerrocenylethylMaleimide.svg" width="200"/>


**MolecularGraph.jl** is a graph-based molecule modeling and chemoinformatics analysis toolkit which is fully implemented in Julia.


## Installation

```
 (v1.0) pkg> add MolecularGraph
```


## Usage

- Try examples and tutorials in the [notebook directory](./notebook)
- [Documentation and API Reference](https://mojaie.github.io/MolecularGraph.jl/dev)


## Features

- Chemical structure file I/O
  - Structure image drawing and export to SVG
  - SDFile import/export (.sdf, .mol)
  - SMILES/SMARTS parser

- Basic descriptors
  - Molecular weight, composition and formula
  - H-bond donor/acceptor
  - rotatable bonds
  - Aromaticity
  - Wildman-Crippen logP

- Molecular graph topology
  - Ring, scaffold, connectivity
  - Graph traversal

- Sub(super)structure
  - Library search by using SMARTS query
  - Subgraph isomorphism detection with VF2 algorithm
  - Node-induced and edge-induced
  - Constraints (mandatory/forbidden mapping)

- Ontology-based functional group detection/analysis

- Maximum common substructure (MCS)
  - By clique detection algorithm
  - Node-induced (MCIS) and edge-induced (MCES)
  - Connected and disconnected
  - Topological constraint (known as tdMCS)
  - Diameter restriction (MCS-DR) and graph-based local similarity (GLS)


## License

[MIT license](http://opensource.org/licenses/MIT)


## Copyright

(C) 2018-2019 Seiji Matsuoka
