# Relative Free Energies with the OpenFE CLI

This tutorial will show how to use the OpenFE command line interface to get
free energies -- with no Python at all! This will work for simple setups, you
may need to use the Python interface for more complicated setups.

The entire process of running the campaign of simulations is split into 3
stages; each of which corresponds to a CLI command:

1. Setting up the campaign creating files that describe each of the individual
   simulations to run.
2. Running the simulations.
3. Gathering the results of separate simulations into a single table.

To work through this tutorial, start out with a fresh directory. You can download the tutorial materials (including this file) using the command:

```bash
openfe fetch rbfe-tutorial
```

Then when you run `ls`, you should see that your directory has this file,
`cli_tutorial.md`, a notebook called `python_tutorial.ipynb`, and
<!-- TODO --> 

## Setting up the campaign

The CLI makes setting up the simulation very easy -- it's just a single CLI
command. There are separate commands for relative binding free energy (RBFE)
and relative hydration free energy setups (RHFE).

For RBFE campaigns, the relevant command is `openfe plan-rbfe-network`. For
RHFE, the command is `openfe plan-rhfe-network`. They work mostly the same,
except that the RHFE planner does not take a protein. In this tutorial, we'll
do an RBFE calculation. The only difference for RBFE is in the setup stage --
running the simulations and gathering the results are the same.

<!-- TODO To run the setup, we'll tell it search for SDF/MOL2 files in the current
directory using `-M `. --> 
We'll tell it to output into a directory called `setup` with the we're working
in with the `-o setup` option.

<!-- TODO -->
```bash
```

Planning the campaign may a take a few minutes, as it tries to find the best
network from all possible transformations. This will create a file for each
leg that we will calculate, all within a directory called `transformations`.
Now you're ready to run the simulations! Let's look at the structure of the
`transformations` directory:

<!-- take the top lines from `tree transformations/` -->

```text
setup
├── ligand_network.graphml
├── setup.json
└── transformations
    ├── easy_rhfe_lig_10_solvent_lig_15_solvent.json
    ├── easy_rhfe_lig_10_vacuum_lig_15_vacuum.json
    ├── easy_rhfe_lig_11_solvent_lig_14_solvent.json
    ├── easy_rhfe_lig_11_vacuum_lig_14_vacuum.json
[continues]
```

There is a subdirectory for each edge, named according to the ligand pair.
Within that, there are directories for the two "legs" associated with this
ligand transformation: the ligand transformation in solvent and in vacuum.
Each JSON file represents a single leg to run, and contains all the necessary
information to run that leg.

Note that this specific setup makes a number of choices for you. All of
these choices can be customized in the Python API, and some can be customized
using the CLI. To see additional CLI options, use `openfe plan-rhfe-network
--help`. Here are the specifics on how these simulation are set up:

1. LOMAP is used to generate the atom mappings between ligands, with the
   parameters <!-- TODO -->
2. The network is a minimal spanning tree, with the default LOMAP score used to
   score the mappings.
3. Solvent is water with NaCl at an ionic strength of 0.15 M (neutralized).
4. The protocol used is OpenFE's OpenMM-based RFE protocol, with default settings.

<!-- TODO there should be a link to the default settings here -->


## Running the simulations

For this tutorial, we have precalculated data that you can load, since
running the simulations can take a long time. However, you could, in principle,
run each simulation on your local machine with something like:

```bash
# this will take a very long time! don't actually do it!
for file in setup/transformations/*.json; do
  relpath=${file:22}  # strip off "setup/transformations/"
  dirpath=${relpath%.*}  # strip off final ".json"
  openfe quickrun $file -o results/$relpath -d results/$dirpath
done
```

In practice, you probably want to submit these to a queue. In that case, you'll
want to create a new job script for each simulation JSON file, and the core of
that job script will be to run the `openfe quickrun` command above.

Details of what information is needed in that job script will depend on your
computing center. Here is an example of a very simple script that will create
and submit a job script for the simplest SLURM use case:

```bash
for file in setup/transformations/*.json; do
  relpath=${file:22}  # strip off "setup/transformations/"
  dirpath=${relpath%.*}  # strip off final ".json"
  jobpath="setup/transformations/${dirpath}.job"
  cmd="openfe quickrun $file -o results/$relpath -d results/$dirpath"
  echo -e "#!/usr/bin/env bash\n${cmd}" > $jobpath
  sbatch $jobpath
done
```

## Gathering the results

To get example data, use the following commands:

```bash
openfe fetch rhfe-tutorial-results
tar xzf results.tar.gz
```

This will create a directory called `results/` that contains files in the file
structure you would get from running the calculations as above. The result JSON
files are the actual results of a simulation. Other files that are generated
during the simulation (such as detailed simulation information) have been
replaced by empty files to keep the size smaller. The structure looks something
like this:

<!-- take the top lines from `tree results` -->

```text
results
├── easy_rhfe_lig_10_solvent_lig_15_solvent
│   ├── shared_RelativeHybridTopologyProtocolUnit-333f0749f2554d6794c0dfb495c32bc3
│   │   ├── checkpoint.nc
│   │   └── simulation.nc
│   ├── shared_RelativeHybridTopologyProtocolUnit-3a17c1c3a438403a88766e2ad4986d62
│   │   ├── checkpoint.nc
│   │   └── simulation.nc
│   └── shared_RelativeHybridTopologyProtocolUnit-9aa9c8b808b64f6089ef22c9c83bc89d
│       ├── checkpoint.nc
│       └── simulation.nc
├── easy_rhfe_lig_10_solvent_lig_15_solvent.json
[continues]
```

The JSON results file contains not only the calculated $\Delta G$, and
uncertainty estimate, but also important metadata about what happened during
the simulation. In particular, it will contain information about any errors or
failures that occurred -- these errors will not cause the entire campaign to
fail, and will be recorded so you can later analyze what went wrong.

To gather all the $\Delta G$ estimates into a single file, use the `openfe
gather` command from withing the working directory used above:

```bash
openfe gather ./results/ -o final_results.tsv
```

This will write out a tab-separated table of results, including both the
$\Delta G$ for each leg and the $\Delta\Delta G$ computed from pairs of legs.
The first column labels the data, e.g., `DGvacuum(ligandB,ligandA)` for the
$\Delta G$ of the transformation of ligand A into ligand B in vacuum, or
`DDGsolv(ligandB,ligandA)` for the $\Delta\Delta G$ of binding ligand A vs.
ligand B: $\Delta G$<sub>solv, $B$</sub>$ - \Delta G$<sub>solv$A$</sub>.

The resulting file looks something like this:

<!-- take top lines from `cat final_results.tsv`; make sure to add a [snip] and
     get some of the DGs as well as the DDGs -->

```text
measurement     estimate (kcal/mol)     uncertainty
DDGhyd(lig_8, lig_6)    4.1     +-0.074
DDGhyd(lig_6, lig_1)    -3.5    +-0.038
DDGhyd(lig_15, lig_14)  3.3     +-0.056
DDGhyd(lig_14, lig_13)  0.49    +-0.038
[snip]
DGvacuum(lig_6, lig_8)  -10.0   +-0.027
DGsolvent(lig_6, lig_8) -6.1    +-0.069
DGsolvent(lig_1, lig_6) 17.0    +-0.032
DGvacuum(lig_1, lig_6)  20.0    +-0.022
DGvacuum(lig_14, lig_15)        6.9     +-0.0028
DGsolvent(lig_14, lig_15)       10.0    +-0.056
DGsolvent(lig_13, lig_14)       15.0    +-0.037
[continues]
```
