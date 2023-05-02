# Relative Free Energies with the OpenFE CLI

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/OpenFreeEnergy/ExampleNotebooks/blob/switch_to_colab/easyCampaign/Cli%20Demo.ipynb)

This tutorial will show how to use the OpenFE command line interface to get
free energies -- with no Python at all! This will work for simple setups, you
may need to use the Python interface for more complicated setups.

The entire process of running the campaign of simulations is split into 3
stages; each of which corresponds to a CLI command:

1. Setting up the campaign creating files that describe each of the individual
   simulations to run.
2. Running the simulations.
3. Gathering the results of separate simulations into a single table.

To work through this tutorial, let's start out with a fresh directory
containing files from the tutorial in our [examples
repository](https://github.com/OpenFreeEnergy/ExampleNotebooks). If
`$EXAMPLES_REPO` is a path to a local copy of that repository, then after
switching to an empty directory, you can get the files with:

```bash
cp $EXAMPLES_REPO/easyCampaign/molecules/rhfe/* ./
```

Then when you run `ls`, you should see that your directory has one file in it:
`benzenes_RHFE.sdf`. That will be the starting point for the tutorial.

## Setting up the campaign

The CLI makes setting up the simulation very easy -- it's just a single CLI
command. There are separate commands for binding free energy and hydration free
energy setups.

For RBFE campaigns, the relevant command is `openfe plan-rbfe-network`. For
RHFE, the command is `openfe plan-rhfe-network`. They work mostly the same,
except that the RHFE planner does not take a protein. In this tutorial, we'll
do an RHFE calculation. The only difference for RBFE is in the setup stage --
running the simulations and gathering the results are the same.

To run the setup, we'll tell it search for SDF/MOL2 files in the current
directory using `-M ./`. We'll tell it to output into the same directory that
we're working in with the `-o ./` option.

```bash
openfe plan-rhfe-network -M ./ -o ./
```

Planning the campaign may a take a few minutes, as it tries to find the best
network from all possible transformations. This will create a file for each
leg that we will calculate, all within a directory called `transformations`.
Now you're ready to run the simulations! Let's look at the structure of the
`transformations` directory:


<!-- take the top lines from `tree transformations/` -->

```text
transformations
├── lig_10_lig_15
│   ├── solvent
│   │   └── openfe-tutorial_easy_rhfe_lig_10_solvent_lig_15_solvent.json
│   └── vacuum
│       └── openfe-tutorial_easy_rhfe_lig_10_vacuum_lig_15_vacuum.json
├── lig_10_lig_5
│   ├── solvent
│   │   └── openfe-tutorial_easy_rhfe_lig_5_solvent_lig_10_solvent.json
│   └── vacuum
│       └── openfe-tutorial_easy_rhfe_lig_5_vacuum_lig_10_vacuum.json
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

1. LOMAP is used to generate the atom mappings between ligands.
2. The network is a minimal spanning tree, with the default LOMAP score used to
   score the mappings.
3. Solvent is water with NaCl at an ionic strength of 0.15 M (neutralized).
4. The protocol used is OpenFE's OpenMM RFE protocol, with default settings.

<!-- TODO there should be a link to the default settings here -->


## Running the simulations

In principle, you can run each simulation on your local machine with something
like:

```
# this will take a long time!
for file in transformations/*/*/*.json; do
  relpath=${file:16}  # strip off "transformations/"
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

```
for file in transformations/*/*/*.json; do
  relpath=${file:16}  # strip off "transformations/"
  dirpath=${relpath%.*}  # strip off final ".json"
  jobpath="transformations/${dirpath}.job"
  cmd="openfe quickrun $file -o results/$relpath -d results/$dirpath"
  echo -e "#!/usr/bin/env bash\n${cmd}" > $jobpath
  sbatch $jobpath
done
```

## Gathering the results

Once the simulations have been run, you will see many results in the results
directory. For each simulation, there will be a result JSON file, as well as a
directory that includes files created during the simulation, with the names as
given to the `openfe quickrun` command.

<!-- TODO directory structure -->

The JSON results file contains not only the calculated $\Delta G$, and
uncertainty estimate, but also important metadata about what happened during
the simulation. In particular, it will contain information about any errors or
failures that occurred -- these errors will not cause the entire campaign to
fail, and will be recorded so you can later analyze what went wrong.

To gather all the $\Delta G$ estimates into a single file, use the `openfe
gather` command from withing the working directory used above:

```
openfe gather ./results/ -o final_results.tsv
```

This will write out a tab-separated table of results, including both the
$\Delta G$ for each leg and the $\Delta\Delta G$ computed from pairs of legs.
The first column labels the data, e.g., `DGvacuum(ligandB,ligandA)` for the
$\Delta G$ of the transformation of ligand A into ligand B in vacuum, or
`DDGsolv(ligandB,ligandA)` for the $\Delta\Delta G$ of binding ligand A vs.
ligand B: $\Delta G$<sub>solv, $B$</sub>$ - \Delta G$<sub>solv$A$</sub>.

<!-- TODO example of output -->
