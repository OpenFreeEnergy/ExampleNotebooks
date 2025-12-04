[![Logo](https://img.shields.io/badge/OSMF-OpenFreeEnergy-%23002f4a)](https://openfree.energy/)
[![full_tests](https://github.com/OpenFreeEnergy/ExampleNotebooks/actions/workflows/CI.yml/badge.svg)](https://github.com/OpenFreeEnergy/ExampleNotebooks/actions/workflows/CI.yml)
[![pre-commit.ci status](https://results.pre-commit.ci/badge/github/OpenFreeEnergy/ExampleNotebooks/master.svg)](https://results.pre-commit.ci/latest/github/OpenFreeEnergy/ExampleNotebooks/main)
[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/OpenFreeEnergy/ExampleNotebooks/blob/main/showcase/openfe_showcase.ipynb)

# OpenFE Notebooks

Collection of notebooks for the Open FreeEnergy project.
These can be run in the browser via the Colab links.

| Colab link | Description |
| --- | --- |
| [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/OpenFreeEnergy/ExampleNotebooks/blob/main/showcase/openfe_showcase.ipynb) | Start here.  This notebook demonstrates how a free energy calculation can be defined, executed and analyzed using the `openfe` package. |

## Running these notebooks locally

To run these notebooks locally you will need to install the `openfe` package,
this is best done using [the instuctions here](https://docs.openfree.energy/en/stable/installation.html)

Then you can download a copy of the notebooks:

- `wget -O OpenFEExampleNotebooks.tar.gz https://github.com/OpenFreeEnergy/ExampleNotebooks/tarball/main`
- or (depending on your platform)
- `curl -L -k -o OpenFEExampleNotebooks.tar.gz https://github.com/OpenFreeEnergy/ExampleNotebooks/tarball/main`

Unpack, then navigate to the downloaded notebooks:

- `tar -xz OpenFEExampleNotebooks.tar.gz`
- `cd OpenFreeEnergy-ExampleNotebooks-b79be48`

Then launch the notebook application as:

- `jupyter notebook`

This should present a choice of notebooks to follow.
