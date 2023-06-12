# OpenFE RBFE Tutorial

This tutorial is a recommended starting place for working with OpenFE. This
tutorial consists of 2 stages: first, there is the command line tutorial, where
you will work with the OpenFE command line interface (CLI) to set up a
simulation campaign, see how to run each simulation with the CLI, and then
gather results from a previously-run simulation into a final table. The second
stage uses a Jupyter notebook to perform the exact same setup as the CLI, but
shows how you have more flexibility when working with the Python interface.

## Step-by-step

1. To get an overview of OpenFE, you can view [the slides](https://docs.google.com/presentation/d/12xIu7V-izt-j5nlsPD9IOXih1qm4fPPVwVdulipjSv4/) that were given with
   this tutorial at the OMSF workshop in May 2023.

2. If you haven't already, install OpenFE using [our recommended install
   instructions](https://docs.openfree.energy/en/stable/installation.html#installation-with-mambaforge-recommended).
   We highly recommend installing with `mamba` over `conda`; there is a huge
   gap in performance.

3. Follow the [CLI tutorial](cli_tutorial.md), which includes downloading the
   tutorial materials with the `openfe fetch` command.

4. Follow the notebook tutorial, running with `jupyter notebook
   python_tutorial.ipynb`. The notebook tutorial reproduces the setup stage of
   the CLI tutorial, but illustrates how you can customize things using the
   Python API that cannot be customized using the CLI.
