# Binding Free Energies with the OpenFE CLI

This tutorial demonstrates how to use the OpenFE CLI (Command Line Interface) to calculate free energies - with no Python at all!

The CLI is useful for simple setups, but you may need to use the Python API for more complicated setups.

RBFE calculations with ``openfe`` are split into 3 steps: plan, run, and gather, each of which corresponds to a CLI command:

1. ``openfe plan-rbfe-network``: Define the systems and prepare simulations to be run.
2. ``openfe quickrun``: Run the simulations
3. ``openfe gather``: Gather and analyze simulation results to generate a table of free energies.

## 0. Collect input files

To work through this tutorial, start out with a fresh directory.

You can download the tutorial materials (including these instructions) using the command:

```bash
openfe fetch rbfe-tutorial
```

Then when you run `ls`, you should see that your directory has:

- `cli_tutorial.md`: the file containing these instructions
- `python_tutorial.ipynb`: a notebook detailing how to do this analysis using the Python API, instead of the CLI shown here.
- `tyk2_ligands.sdf` and `tyk2_protein.pdb` : files containing the molecules we'll use in this tutorial.

## 1. Set up the campaign

The CLI makes setting up the simulation very easy - it's just a single CLI
command.
There are separate commands for relative binding free energy (RBFE) and relative hydration free energy setups (RHFE).

For RBFE campaigns, the relevant command is `openfe plan-rbfe-network`.
For RHFE, the command is `openfe plan-rhfe-network`.
They work mostly the same, except that the RHFE planner does not take a protein.
In this tutorial, we'll perform an RBFE calculation.
The only difference for RHFE is in the setup stage - running the simulations and gathering the results are the same.

The single command:

```bash
openfe plan-rbfe-network -M tyk2_ligands.sdf -p tyk2_protein.pdb -o network_setup/ --n-protocol-repeats 1
```

performs the following steps:

- Read all the ligands from the SDF by giving the option `-M tyk2_ligands.sdf`.
  You can also use `-M` with a directory, and it will load all molecules found in any SDF or MOL2 file in that directory.
- Pass a PDB of the protein target (TYK2) with `-p tyk2_protein.pdb`.
- Create transformation JSONs, stored in the directory `network_setup/`, that contain all information needed to run simulations with `openfe quickrun`.
- Instruct `openfe` to only run one repeat of the alchemical simulation per `quickrun` call using `--n-protocol-repeats 1`.

  **Note:** `openfe`'s default behaviour is to use three repeats to calculate the uncertainty (i.e. standard deviation) in an estimate.
  When setting `--n-protocol-repeats 1`, you must execute the transformation multiple times - at minimum 2, but best practice is 3 independent repeats.

Planning the campaign may take some time due to the complex series of tasks involved:

- partial charges are generated for each of the ligands to ensure reproducibility, by default this requires a semi-empirical quantum
chemical calculation to calculate `am1bcc` charges
- atom mappings are created and scored based on the perceived difficulty for all possible ligand pairs
- an optimal network is extracted from all possible pairwise transformations which balances edge redundancy and the total difficulty score of the network

The partial charge generation can take advantage of multiprocessing which offers a significant speed-up, you can specify
the number of processors available using the `-n` flag:

```bash
openfe plan-rbfe-network -M tyk2_ligands.sdf -p tyk2_protein.pdb -o network_setup --n-protocol-repeats 1 -n 4
```

This will result in a directory called `network_setup/`, which is structured like this:

<!-- top lines from `tree network_setup` -->

```text
network_setup
├── ligand_network.graphml
├── network_setup.json
└── transformations/
    ├── rbfe_lig_ejm_31_complex_lig_ejm_42_complex.json
    ├── rbfe_lig_ejm_31_complex_lig_ejm_46_complex.json
    ├── rbfe_lig_ejm_31_complex_lig_ejm_47_complex.json
    ├── rbfe_lig_ejm_31_complex_lig_ejm_48_complex.json
    ├── rbfe_lig_ejm_31_complex_lig_ejm_50_complex.json
    ├── rbfe_lig_ejm_31_solvent_lig_ejm_42_solvent.json
    ├── rbfe_lig_ejm_31_solvent_lig_ejm_46_solvent.json
    ...
```

The `ligand_network.graphml` file describes the network of ligands connected by atom mappings.

We can visualize this network with the `openfe view-ligand-network` command:

```bash
openfe view-ligand-network network_setup/ligand_network.graphml
```

to open an interactive viewer.
You can move the ligand names around to get a better view of the structure, and if you click on the edge, you will see the
mapping for that edge.

The files that describe each individual simulation we will run are located within `network_setup/transformations/`.
Each JSON file represents a single alchemical leg to run and contains all the necessary information to run that leg.
Filenames indicate ligand names as taken from the SDF; for example, the file `rbfe_lig_ejm_31_complex_lig_ejm_42_complex.json` is the leg associated with the transformation of the ligand `lig_ejm_31` into `lig_ejm_42` while in complex with the protein.

A single RBFE between a pair of ligands requires running two legs of an alchemical cycle (JSON files) - one for the ligand in solvent, and one for the ligand complexed with the
protein.
The results from these two simulations can then be combined in the next step (``openfe gather``) to obtain a single $\Delta\Delta G$ relative binding free energy value.

Note that this specific setup makes a number of choices for you, from filenames to default values.
All of these choices can be customized in the Python API.
Here are the specifics on how these simulation are set up:

1. **kartograf** is used to generate the atom mappings between ligands.
2. The ligand network is a minimal spanning tree, with the default LOMAP scorer used to score the mappings.
3. Solvent is water with NaCl at an ionic strength of 0.15 M (neutralized) with a minimum distance of 1.2 nm from the solute to the edge of the box.
4. The protocol used is OpenFE's OpenMM-based Hybrid Topology RFE protocol, with [default settings](https://docs.openfree.energy/en/stable/reference/api/openmm_rfe.html#protocol-settings).

### Optional step: Customize your campaign setup

OpenFE contains many different options and methods for setting up a simulation campaign.
While less flexible than using the API, some options can be modified by providing a settings file in the `.yaml` format.

The default settings represented in YAML settings format is as follows:

``` yaml
mapper: kartograf
    settings:
        atom_max_distance: 0.95
        atom_map_hydrogens: true
        map_hydrogens_on_hydrogens_only: true
        map_exact_ring_matches_only: true
        allow_partial_fused_rings: true
        allow_bond_breaks: false

network:
    method: generate_minimal_spanning_network

partial_charge:
    method: am1bcc
    settings:
        off_toolkit_backend: ambertools
        number_of_conformers: None
        nagl_model: None

```

Let's assume you want to exchange the kartograf atom mapper with the LOMAP atom mapper, the Minimal Spanning Tree
Network Planner with the Maximal Network Planner and the am1bcc charge method with [OpenFF NAGL](https://docs.openforcefield.org/projects/nagl/):

1. provide a file like `settings.yaml` with the desired changes:

```yaml
mapper:
  method: lomap

network:
  method: generate_maximal_network

partial_charge:
  method: nagl
  settings:
    nagl_model: null  # null specifies the use of the latest nagl model
```

2. Plan your rbfe network with an additional `-s` flag for passing the settings:

```bash
openfe plan-rbfe-network -M tyk2_ligands.sdf -p tyk2_protein.pdb -o network_setup --n-protocol-repeats 1 -s settings.yaml
```

3. The output of the CLI program will now reflect the changes made:

```text
RBFE-NETWORK PLANNER
______________________

Parsing in Files:
	Got input:
		Small Molecules: SmallMoleculeComponent(name=lig_ejm_31) SmallMoleculeComponent(name=lig_ejm_42) SmallMoleculeComponent(name=lig_ejm_43) SmallMoleculeComponent(name=lig_ejm_46) SmallMoleculeComponent(name=lig_ejm_47) SmallMoleculeComponent(name=lig_ejm_48) SmallMoleculeComponent(name=lig_ejm_50) SmallMoleculeComponent(name=lig_jmc_23) SmallMoleculeComponent(name=lig_jmc_27) SmallMoleculeComponent(name=lig_jmc_28)
		Protein: ProteinComponent(name=)
		Cofactors: []
		Solvent: SolventComponent(name=O, Na+, Cl-)

Using Options:
	Mapper: <LomapAtomMapper (time=20, threed=True, max3d=1.0, element_change=True, seed='', shift=False)>
	Mapping Scorer: <function default_lomap_score at 0x166bc5300>
	Network Generation: <function generate_minimal_spanning_network at 0x16a413e20>
	Partial Charge Generation: am1bcc

	n_protocol_repeats=1 (1 simulation repeat(s) per transformation)
```

To see all settings customizable by YAML input, run `openfe plan-rbfe-network -h`.

## 2. Run the simulations

For this tutorial, we have precalculated data that you can load, since running the simulations can take a long time.
However, you could, in principle, run each simulation on your local machine.

You can run each leg individually by using the `openfe quickrun` command:

```bash
openfe quickrun path/to/transformation.json -o results.json -d working-directory
```

where

- `path/to/transformation.json` is the path to one of the transformation files created by ``openfe plan-rbfe-network`` in the prior step
-  `-o results.json` to give the final output JSON file and `-d` for the directory where simulation results should be stored.

to run one simulation from the tutorial data, a command might look like:

```bash
openfe quickrun transformations/rbfe_lig_ejm_31_solvent_lig_ejm_42_solvent.json -o results/rbfe_lig_ejm_31_solvent_lig_ejm_42_solvent.json -d results/rbfe_lig_ejm_31_solvent_lig_ejm_42_solvent/
```

When running a complete network of simulations, it is important to ensure that the file name for the result JSON and name of the working directory are different for each leg and each repeat, otherwise you'll overwrite results.
We recommend doing this programmatically, such as the example below, which uses the fact that the JSON files in `network_setup/transformations/` have unique names, and creates directories
and result JSON files based on those names.

In practice, you probably want to submit these to an HPC queue.
In that case, you'll want to create a new job script for each simulation JSON file, and the core of that job script will be to run the `openfe quickrun` command above.

Details of what information is needed in that job script will depend on your computing center, but below is an example of a very simple script that will create
and submit a job script for the simplest SLURM use case:

```bash
for file in network_setup/transformations/*.json; do
  relpath=${file:30}  # strip off "network_setup/transformations/"
  dirpath=${relpath%.*}  # strip off final ".json"
  for repeat in {1..3}; do
      jobpath="network_setup/transformations/${dirpath}_${repeat}.job"
      cmd="openfe quickrun $file -o results/repeat${repeat}/$relpath -d results/repeat${repeat}/$dirpath"
      echo -e "#!/usr/bin/env bash\n${cmd}" > $jobpath
      sbatch $jobpath
  done
done
```

The approach listed here is what was used for the example results that we'll download in the next section.

## 3. Gather the results

To get example simulation output data, use the following commands:

```bash
openfe fetch rbfe-tutorial-results
tar xzf rbfe_results.tar.gz
```

This will create a directory called `results/` that contains files with the file structure you would get from running the calculations as above.
The result JSON files are the actual results of a simulation.
To keep this example data a reasonable size, files typically generated during the simulation (such as detailed simulation information) have been replaced by empty files to keep the size smaller.
The structure should look something like this:

<!-- take the top lines from `tree results` -->
```text
results
├── replicate_0
│   ├── rbfe_lig_ejm_31_complex_lig_ejm_42_complex
│   │   ├── shared_RelativeHybridTopologyProtocolUnit-79c279f04ec84218b7935bc0447539a9_attempt_0
│   │   │   ├── checkpoint.nc
│   │   │   ├── db.json
│   │   │   ├── simulation_real_time_analysis.yaml
│   │   │   └── simulation.nc
│   │   ├── shared_RelativeHybridTopologyProtocolUnit-a3cef34132aa4e9cbb824fcbcd043b0e_attempt_0
│   │   │   ├── checkpoint.nc
│   │   │   ├── db.json
│   │   │   ├── simulation_real_time_analysis.yaml
│   │   │   └── simulation.nc
│   │   └── shared_RelativeHybridTopologyProtocolUnit-abb2b104151c45fc8b0993fa0a7ee0af_attempt_0
│   │       ├── checkpoint.nc
│   │       ├── db.json
│   │       ├── simulation_real_time_analysis.yaml
│   │       └── simulation.nc
│   ├── rbfe_lig_ejm_31_complex_lig_ejm_42_complex.json
│   ├── rbfe_lig_ejm_31_complex_lig_ejm_46_complex
│   │   ├── shared_RelativeHybridTopologyProtocolUnit-361500fe831c431aa830efd207db0955_attempt_0
│   │   │   ├── checkpoint.nc
│   │   │   ├── db.json
│   │   │   ├── simulation_real_time_analysis.yaml
│   │   │   └── simulation.nc
│   │   ├── shared_RelativeHybridTopologyProtocolUnit-5a6176cfbf074f92bc76caac91b1c1bf_attempt_0
│   │   │   ├── checkpoint.nc
│   │   │   ├── db.json
│   │   │   ├── simulation_real_time_analysis.yaml
│   │   │   └── simulation.nc
│   │   └── shared_RelativeHybridTopologyProtocolUnit-e16de73f07964e9096f34611e0c874ca_attempt_0
│   │       ├── checkpoint.nc
│   │       ├── db.json
│   │       ├── simulation_real_time_analysis.yaml
│   │       └── simulation.nc
│   ├── rbfe_lig_ejm_31_complex_lig_ejm_46_complex.json
...
```

The JSON results file contains not only the calculated $\Delta G$, and uncertainty estimate, but also important metadata about what happened during the simulation.
In particular, it will contain information about any errors or failures that occurred -- these errors will not cause the entire campaign to fail, and will be recorded so you can later analyze what went wrong.

To gather all the $\Delta G$ estimates into a single file, use the `openfe gather` command from within the working directory used above:

```bash
openfe gather results/ --report dg -o final_results.tsv
```

Note that if you have multiple results directories, you can pass multiple directories, e.g. ``openfe gather results_0/ results_1/``.

This will write out a tab-separated table of results where the results reported are controlled by the `--report` option:

- `dg` (default) reports the ligand and the results are the maximum
 likelihood estimate of its absolute free, and the associated
 uncertainty from DDG replica averages and standard deviations.
- `ddg` reports pairs of `ligand_i` and `ligand_j`, the calculated
 relative free energy `DDG(i->j) = DG(j) - DG(i)` and its uncertainty.
- `raw` reports the raw results, giving the leg (`vacuum`, `solvent`, or
 `complex`), `ligand_i`, `ligand_j`, the raw `DG(i->j)` associated with it.

The resulting file (`final_results.tsv`) will look something like this:

<!-- take top lines from `cat final_results.tsv` -->

```text
ligand	DG(MLE) (kcal/mol)	uncertainty (kcal/mol)
lig_ejm_31	-0.09	0.05
lig_ejm_42	0.7	0.1
lig_ejm_46	-0.98	0.05
lig_ejm_47	-0.1	0.1
lig_ejm_48	0.53	0.09
lig_ejm_50	0.91	0.06
lig_ejm_43	2.0	0.2
lig_jmc_23	-0.68	0.09
lig_jmc_27	-1.1	0.1
lig_jmc_28	-1.25	0.08
```
