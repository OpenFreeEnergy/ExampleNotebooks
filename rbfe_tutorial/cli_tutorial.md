# Relative Free Energies with the OpenFE CLI

This tutorial will show how to use the OpenFE command line interface to get
free energies -- with no Python at all! This will work for simple setups, you
may need to use the Python interface for more complicated setups.

The entire process of running the campaign of simulations is split into 3
stages; each of which corresponds to a CLI command:

1. Setting up the necessary files to describe each of the individual
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

To run the command, we do the following:
  * Read all the ligands from the SDF by giving
    the option `-M tyk2_ligands.sdf`. You can also use `-M` with a directory, and
    it will load all molecules found in any SDF or MOL2 file in that directory.
  * Pass a PDB of the protein target (TYK2) with `-p tyk2_protein.pdb`.
  * Instruct `openfe` to ouput files into a directory called `network_setup`
    with the `-o network_setup` option.

```bash
openfe plan-rbfe-network -M tyk2_ligands.sdf -p tyk2_protein.pdb -o network_setup
```

Planning the campaign may take some time, as it tries to find the best
network from all possible transformations. This will create a directory called
`network_setup`, which is structured like this:

<!-- top lines from `tree network_setup` -->

```text
network_setup
├── ligand_network.graphml
├── network_setup.json
└── transformations
    ├── easy_rbfe_lig_ejm_31_complex_lig_ejm_42_complex.json
    ├── easy_rbfe_lig_ejm_31_complex_lig_ejm_46_complex.json
    ├── easy_rbfe_lig_ejm_31_complex_lig_ejm_47_complex.json
    ├── easy_rbfe_lig_ejm_31_complex_lig_ejm_48_complex.json
    ├── easy_rbfe_lig_ejm_31_complex_lig_ejm_50_complex.json
    ├── easy_rbfe_lig_ejm_31_solvent_lig_ejm_42_solvent.json
    ├── easy_rbfe_lig_ejm_31_solvent_lig_ejm_46_solvent.json
[continues]
```

The `ligand_network.graphml` file describes the atom mappings between the
ligands. We can visualize it with the `openfe view-ligand-network` command:

```bash
openfe view-ligand-network network_setup/ligand_network.graphml
```

This opens an interactive viewer. You can move the ligand names around to get a
better view of the structure, and if you click on the edge, you will see the
mapping for that edge.

The files that describe each individual simulation we will run are located in the
`transformations` subdirectory. Each JSON file represents a single alchemical leg to run,
and contains all the necessary information to run that leg.

Note that this specific setup makes a number of choices for you. All of
these choices can be customized in the Python API. Here are the specifics on
how these simulation are set up:

1. LOMAP is used to generate the atom mappings between ligands, with a
   20-second timeout, core-core element changes disallowed, and max3d set to 1.
2. The network is a minimal spanning tree, with the default LOMAP score used to
   score the mappings.
3. Solvent is water with NaCl at an ionic strength of 0.15 M (neutralized) with a
   minimum distance of 1.2 nm from the solute to the edge of the box.
4. The protocol used is OpenFE's OpenMM-based Hybrid Topology RFE protocol, with [default settings](https://docs.openfree.energy/en/stable/reference/api/openmm_rfe.html#protocol-settings).


## Running the simulations

For this tutorial, we have precalculated data that you can load, since
running the simulations can take a long time. However, you could, in principle,
run each simulation on your local machine with something like:

```bash
# this will take a very long time! don't actually do it!
for file in network_setup/transformations/*.json; do
  relpath=${file:30}  # strip off "network_setup/transformations/"
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
  relpath=${file:30}  # strip off "network_setup/transformations/"
  dirpath=${relpath%.*}  # strip off final ".json"
  jobpath="network_setup/transformations/${dirpath}.job"
  cmd="openfe quickrun $file -o results/$relpath -d results/$dirpath"
  echo -e "#!/usr/bin/env bash\n${cmd}" > $jobpath
  sbatch $jobpath
done
```

## Gathering the results

To get example data, use the following commands:

```bash
openfe fetch rbfe-tutorial-results
tar xzf rbfe_results.tar.gz
```

This will create a directory called `results/` that contains files with the file
structure you would get from running the calculations as above. The result JSON
files are the actual results of a simulation. Other files that are generated
during the simulation (such as detailed simulation information) have been
replaced by empty files to keep the size smaller. The structure looks something
like this:

<!-- take the top lines from `tree results` -->

```text
results
├── easy_rbfe_lig_ejm_31_complex_lig_ejm_42_complex
│   ├── shared_RelativeHybridTopologyProtocolUnit-3ea82011-75f0-4bb6-b415-e7d05bd012f6
│   │   ├── checkpoint.nc
│   │   └── simulation.nc
│   ├── shared_RelativeHybridTopologyProtocolUnit-5262feb6-cb50-4bb2-90a2-359810c2bb9c
│   │   ├── checkpoint.nc
│   │   └── simulation.nc
│   └── shared_RelativeHybridTopologyProtocolUnit-7a6def34-2967-4452-8d47-483bc7219c06
│       ├── checkpoint.nc
│       └── simulation.nc
├── easy_rbfe_lig_ejm_31_complex_lig_ejm_42_complex.json
├── easy_rbfe_lig_ejm_31_complex_lig_ejm_46_complex
│   ├── shared_RelativeHybridTopologyProtocolUnit-ad113e55-5636-474e-9be3-ee77fe887e77
│   │   ├── checkpoint.nc
│   │   └── simulation.nc
│   ├── shared_RelativeHybridTopologyProtocolUnit-ca74ad3c-2ac8-4961-be7c-fa802a1ec76b
│   │   ├── checkpoint.nc
│   │   └── simulation.nc
│   └── shared_RelativeHybridTopologyProtocolUnit-f848e671-fdd3-4b8d-8bd2-6eb5140e3ed3
│       ├── checkpoint.nc
│       └── simulation.nc
├── easy_rbfe_lig_ejm_31_complex_lig_ejm_46_complex.json
[continues]
```

The JSON results file contains not only the calculated $\Delta G$, and
uncertainty estimate, but also important metadata about what happened during
the simulation. In particular, it will contain information about any errors or
failures that occurred -- these errors will not cause the entire campaign to
fail, and will be recorded so you can later analyze what went wrong.

To gather all the $\Delta G$ estimates into a single file, use the `openfe
gather` command from within the working directory used above:

```bash
openfe gather ./results/ -o final_results.tsv
```

This will write out a tab-separated table of results, including both the
$\Delta G$ for each leg and the $\Delta\Delta G$ computed from pairs of legs.
The first column is a description of the data, e.g., `DGcomplex(ligandB,
ligandA)` for the $\Delta G$ of the transformation of ligand
A into ligand B complexed to a protein, or `DDGbind(ligeandB, ligandA)` for the binding
$\Delta\Delta G$ going from ligand A to ligand B. The second column tells the type of
the result, either `RBFE` for a relative result or `solvent`/`complex` for an
individual leg. The next two columns are the labels of the ligands, and then
the computed result and its uncertainty.

The resulting file looks something like this:

<!-- take top lines from `cat final_results.tsv` -->

```text
measurement  type    ligand_i    ligand_j    estimate (kcal/mol) uncertainty (kcal/mol)
DDGbind(lig_ejm_48, lig_ejm_31) RBFE    lig_ejm_31  lig_ejm_48  0.45    0.17
DDGbind(lig_jmc_28, lig_ejm_46) RBFE    lig_ejm_46  lig_jmc_28  -0.12   0.044
DDGbind(lig_ejm_46, lig_ejm_31) RBFE    lig_ejm_31  lig_ejm_46  -0.73   0.097
DDGbind(lig_ejm_50, lig_ejm_31) RBFE    lig_ejm_31  lig_ejm_50  0.94    0.072
DDGbind(lig_ejm_42, lig_ejm_31) RBFE    lig_ejm_31  lig_ejm_42  0.49    0.09
DDGbind(lig_jmc_23, lig_ejm_46) RBFE    lig_ejm_46  lig_jmc_23  -0.39   0.046
DDGbind(lig_ejm_43, lig_ejm_42) RBFE    lig_ejm_42  lig_ejm_43  1.2 0.14
DDGbind(lig_jmc_27, lig_ejm_46) RBFE    lig_ejm_46  lig_jmc_27  -0.65   0.1
DDGbind(lig_ejm_47, lig_ejm_31) RBFE    lig_ejm_31  lig_ejm_47  0.016   0.15
DGsolvent(lig_ejm_31, lig_ejm_48)   solvent lig_ejm_31  lig_ejm_48  -20.0   0.043
DGcomplex(lig_ejm_31, lig_ejm_48)   complex lig_ejm_31  lig_ejm_48  -19.0   0.17
DGsolvent(lig_ejm_46, lig_jmc_28)   solvent lig_ejm_46  lig_jmc_28  14.0    0.043
DGcomplex(lig_ejm_46, lig_jmc_28)   complex lig_ejm_46  lig_jmc_28  14.0    0.0069
[continues]
```
