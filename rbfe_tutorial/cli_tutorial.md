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
`cli_tutorial.md`, a notebook called `python_tutorial.ipynb`, and files with
the molecules we'll use in this tutorial: `tyk2_ligands.sdf` and
`tyk2_protein.pdb`.

## Setting up the campaign

The CLI makes setting up the simulation very easy -- it's just a single CLI
command. There are separate commands for relative binding free energy (RBFE)
and relative hydration free energy setups (RHFE).

For RBFE campaigns, the relevant command is `openfe plan-rbfe-network`. For
RHFE, the command is `openfe plan-rhfe-network`. They work mostly the same,
except that the RHFE planner does not take a protein. In this tutorial, we'll
do an RBFE calculation. The only difference for RBFE is in the setup stage --
running the simulations and gathering the results are the same.

To run the command, we'll tell it get all the ligands from the SDF by giving
the option `-M tyk2_ligands.sdf`. You can also use `-M` with a directory, and
it will load all molecules found in any SDF or MOL2 file in that directory.
We'll tell the command to use the our PDB for the protein with `-p
tyk2_protein.pdb`.  Finally, we'll tell it to output into a directory called
`network_setup` with the `-o network_setup` option.

```bash
openfe plan-rbfe-network -M tyk2_ligands.sdf -p tyk2_protein.pdb -o network_setup
```

Planning the campaign may take some time, as it tries to find the best
network from all possible transformations. This will create directory called
`network_setup`, which is structured like this:

<!-- top lines from `tree network_setup` -->

```text
[add this after #402 is merged in; could affect resulting network]
[continues]
```

The `ligand_network.graphml` file describes the atom mappings between the
ligands. We can visualize it with the `openfe ligand-network-viewer` command:

```bash
openfe ligand-network-viewer network_setup/ligand_network.graphml
```

This opens an interactive viewer. You can move the ligand names around to get a
better view of the structure, and if you click on the edge, you'll see the
mapping for that edge.

The files that describe each individual process we will run are located in the
`transformations` subdirectory. Each JSON file represents a single leg to run,
and contains all the necessary information to run that leg.

Note that this specific setup makes a number of choices for you. All of
these choices can be customized in the Python API. Here are the specifics on
how these simulation are set up:

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
openfe fetch rbfe-tutorial-results
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
[add this after #402 is merged in; could affect resulting network]
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
<!-- TODO The first column labels the data, e.g., `DGvacuum(ligandB,ligandA)` for the
$\Delta G$ of the transformation of ligand A into ligand B in vacuum, or
`DDGsolv(ligandB,ligandA)` for the $\Delta\Delta G$ of binding ligand A vs.
ligand B: $\Delta G$<sub>solv, $B$</sub>$ - \Delta G$<sub>solv$A$</sub>. -->

The resulting file looks something like this:

<!-- take top lines from `cat final_results.tsv` -->

```text
[add this after #402 is merged in; could affect resulting network]
[continues]
```
