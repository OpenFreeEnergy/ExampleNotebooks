[![Logo](https://img.shields.io/badge/OSMF-OpenFreeEnergy-%23002f4a)](https://openfree.energy/)
[![full_tests](https://github.com/OpenFreeEnergy/ExampleNotebooks/actions/workflows/CI.yml/badge.svg)](https://github.com/OpenFreeEnergy/ExampleNotebooks/actions/workflows/CI.yml)
[![pre-commit.ci status](https://results.pre-commit.ci/badge/github/OpenFreeEnergy/ExampleNotebooks/master.svg)](https://results.pre-commit.ci/latest/github/OpenFreeEnergy/ExampleNotebooks/main)
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/OpenFreeEnergy/ExampleNotebooks/HEAD)

# OpenFE Notebooks

Collection of notebooks for the Open FreeEnergy project.
These can be ran in the browser via the Binder links.

| Binder link | Description |
| --- | --- |
| [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/OpenFreeEnergy/ExampleNotebooks/HEAD?labpath=openmm-rbfe%2FOpenFE_showcase_1_RBFE_of_T4lysozyme.ipynb) | Showcase of the OpenFE package as a whole |
| [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/OpenFreeEnergy/ExampleNotebooks/HEAD?labpath=openmm-rbfe%2FApplyingProtocolToNetworkQuickrunDemo.ipynb) | Demonstrating how to plan a free energy network and apply a protocol |

## Running these notebooks locally

To run these notebooks locally you will need to install the `openfe` package,
this is best done using [miniconda](https://docs.conda.io/en/latest/miniconda.html)

Once miniconda is installed, from a terminal run:

-  `conda create -n openfe -c conda-forge openfe jupyter MDAnalysis nglview`
-  `conda activate openfe`

Then you can download a copy of the notebooks:

- https://github.com/OpenFreeEnergy/ExampleNotebooks/archive/refs/tags/nov-2022.tar.gz

Or via the command line as:

- `wget https://github.com/OpenFreeEnergy/ExampleNotebooks/archive/refs/tags/nov-2022.tar.gz`
- `tar xf nov-2022.tar.gz`

Then navigate to the downloaded notebooks:

- `cd ExampleNotebooks-nov-2022/openmm-rbfe`

Then launch the notebook application as:

- `jupyter notebook`

This should present a choice of two notebooks to follow.
