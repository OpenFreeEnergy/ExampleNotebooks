# Relative Free Energies with the OpenFE CLI

This tutorial will show how to use the OpenFE CLI (Command Line Interface) to calculate
free energies - with no Python at all! This CLI works for simple setups, but you
may need to use the Python API for more complicated setups.

The entire process of running the campaign of simulations is split into 3
stages, each of which corresponds to a CLI command:

1. Setting up the files necessary to run each of the simulations
2. Running the simulations
3. Gathering the results of the simulations into a single table

To work through this tutorial, start out with a fresh directory. You can download the tutorial materials (including these instructions) using the command:

```bash
openfe fetch rbfe-tutorial
```

Then when you run `ls`, you should see that your directory has:

- `cli_tutorial.md`: the file containing these instructions
- `python_tutorial.ipynb`: a notebook detailing how to do this analysis using the Python API, instead of the CLI shown here.
- `tyk2_ligands.sdf` and `tyk2_protein.pdb` : files containing the molecules we'll use in this tutorial.

## Setting up the campaign

The CLI makes setting up the simulation very easy - it's just a single CLI
command. There are separate commands for relative binding free energy (RBFE)
and relative hydration free energy setups (RHFE).

For RBFE campaigns, the relevant command is `openfe plan-rbfe-network`. For
RHFE, the command is `openfe plan-rhfe-network`. They work mostly the same,
except that the RHFE planner does not take a protein. In this tutorial, we'll
do an RBFE calculation. The only difference for RHFE is in the setup stage -
running the simulations and gathering the results are the same.

With the single command:

```bash
openfe plan-rbfe-network -M tyk2_ligands.sdf -p tyk2_protein.pdb -o network_setup
```

we do the following:

- Read all the ligands from the SDF by giving
    the option `-M tyk2_ligands.sdf`. You can also use `-M` with a directory, and
    it will load all molecules found in any SDF or MOL2 file in that directory.
- Pass a PDB of the protein target (TYK2) with `-p tyk2_protein.pdb`.
- Instruct `openfe` to output files into a directory called `network_setup`
    with the `-o network_setup` option.

Planning the campaign may take some time, as it tries to find the best
network from all possible transformations. This will create a directory called
`network_setup/`, which is structured like this:

<!-- top lines from `tree network_setup` -->

```text
network_setup
├── ligand_network.graphml
├── network_setup.json
└── transformations/
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

The files that describe each individual simulation we will run are located within
`network_setup/transformations/`. Each JSON file represents a single alchemical
leg to run and contains all the necessary information to run that leg.
Filenames indicate ligand names as taken from the SDF; for example, the file
`easy_rbfe_lig_ejm_31_complex_lig_ejm_42_complex.json` is the leg
associated with the tranformation of the ligand `lig_ejm_31` into `lig_ejm_42`
while in complex with the protein.

A single RBFE between a pair of ligands requires running two legs of an alchemical cycle (JSON files):
one for the ligand in solvent, and one for the ligand complexed with the
protein. The results from these two simulations can then be combined to obtained a single $\Delta\Delta G$ relative binding free energy value.

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

## Customize your campaign setup

OpenFE contains many different options and methods for setting up a simulation campaign.
The options can be easily accessed and modified by providing a settings
file in the `.yaml` format.
Let's assume you want to exchange the LOMAP atom mapper with the Kartograf
atom mapper and the Minimal Spanning Tree
Network Planner with the Maximal Network Planner, then you could do the following:

1. provide a file like `settings.yaml` with the desired changes:

```yaml
mapper:
  method: kartograf

network:
  method: generate_maximal_network
```

2. Plan your rbfe network with an additional `-s` flag for passing the settings:

```bash
openfe plan-rbfe-network -M tyk2_ligands.sdf -p tyk2_protein.pdb -o network_setup -s settings.yaml
```

3. The output of the CLI program will now reflect the changes made:

```text
RBFE-NETWORK PLANNER
______________________

Parsing in Files: 
        Got input: 
                Small Molecules: SmallMoleculeComponent(name=lig_ejm_54) SmallMoleculeComponent(name=lig_jmc_23) SmallMoleculeComponent(name=lig_ejm_47) SmallMoleculeComponent(name=lig_jmc_27) SmallMoleculeComponent(name=lig_ejm_46) SmallMoleculeComponent(name=lig_ejm_31) SmallMoleculeComponent(name=lig_ejm_42) SmallMoleculeComponent(name=lig_ejm_50) SmallMoleculeComponent(name=lig_ejm_45) SmallMoleculeComponent(name=lig_jmc_28) SmallMoleculeComponent(name=lig_ejm_55) SmallMoleculeComponent(name=lig_ejm_43) SmallMoleculeComponent(name=lig_ejm_48)
                Protein: ProteinComponent(name=)
                Cofactors: []
                Solvent: SolventComponent(name=O, Na+, Cl-)

Using Options:
        Mapper: <kartograf.atom_mapper.KartografAtomMapper object at 0x7fea079de790>
        Mapping Scorer: <function default_lomap_score at 0x7fea1b423d80>
        Networker: functools.partial(<function generate_maximal_network at 0x7fea18371260>)
```

That concludes the straightforward process of tailoring your OpenFE setup to your specifications.
Additionally, we've provided a snippet for generating YAML files with
various of the current options for your convenience.

Option Examples:

```yaml
mapper:
  method: lomap
  # method: kartograf

network:
  method: generate_minimal_spanning_network
  # method: generate_radial_network
  # method: generate_maximal_network
  # method: generate_minimal_redundant_network
```

**Customize away!**

## Running the simulations

For this tutorial, we have precalculated data that you can load, since
running the simulations can take a long time. However, you could, in principle,
run each simulation on your local machine.

You can run each leg individually by using the `openfe quickrun` command. It
takes a transformation JSON as input, and the flags `-o` to give the final
output JSON file and `-d` for the directory where simulation results should be
stored. For example,

```bash
openfe quickrun path/to/transformation.json -o results.json -d working-directory
```

where `path/to/transformation.json` is the path to one of the files created above.

When running a complete network of simulations, it is important to ensure that
the file name for the result JSON and name of the working directory are
different for each leg, otherwise you'll overwrite results. We recommend doing
that with something like the following, which uses the fact that the JSON files
in `network_setup/transformations/` have unique names, and creates directories
and result JSON files based on those names. To run all legs sequentially (not
recommended) you could do something like:

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
for file in network_setup/transformations/*.json; do
  relpath=${file:30}  # strip off "network_setup/transformations/"
  dirpath=${relpath%.*}  # strip off final ".json"
  jobpath="network_setup/transformations/${dirpath}.job"
  cmd="openfe quickrun $file -o results/$relpath -d results/$dirpath"
  echo -e "#!/usr/bin/env bash\n${cmd}" > $jobpath
  sbatch $jobpath
done
```

Note that the exact structure of the results directory is not important, as
long as all result JSON files are contained within a single directory tree. The
approach listed here is what was used for the example results that we'll
download in the next section.

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
openfe
<!-- take the top lines from `tree results` -->

```text
results/
├── easy_rbfe_lig_ejm_31_complex_lig_ejm_42_complex
│   ├── shared_RelativeHybridTopologyProtocolUnit-79c279f04ec84218b7935bc0447539a9_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   ├── shared_RelativeHybridTopologyProtocolUnit-a3cef34132aa4e9cbb824fcbcd043b0e_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   └── shared_RelativeHybridTopologyProtocolUnit-abb2b104151c45fc8b0993fa0a7ee0af_attempt_0
│       ├── checkpoint.nc
│       ├── db.json
│       ├── simulation.nc
│       └── simulation_real_time_analysis.yaml
├── easy_rbfe_lig_ejm_31_complex_lig_ejm_42_complex.json
├── easy_rbfe_lig_ejm_31_complex_lig_ejm_46_complex
│   ├── shared_RelativeHybridTopologyProtocolUnit-361500fe831c431aa830efd207db0955_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   ├── shared_RelativeHybridTopologyProtocolUnit-5a6176cfbf074f92bc76caac91b1c1bf_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   └── shared_RelativeHybridTopologyProtocolUnit-e16de73f07964e9096f34611e0c874ca_attempt_0
│       ├── checkpoint.nc
│       ├── db.json
│       ├── simulation.nc
│       └── simulation_real_time_analysis.yaml
├── easy_rbfe_lig_ejm_31_complex_lig_ejm_46_complex.json
├── easy_rbfe_lig_ejm_31_complex_lig_ejm_47_complex
│   ├── shared_RelativeHybridTopologyProtocolUnit-98d2dbe13d77422d918e3d69146f492f_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   ├── shared_RelativeHybridTopologyProtocolUnit-e30b3256ac5d4582b842b7abb20dafdd_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   └── shared_RelativeHybridTopologyProtocolUnit-f1892688746a4279b862b024fcbad1b1_attempt_0
│       ├── checkpoint.nc
│       ├── db.json
│       ├── simulation.nc
│       └── simulation_real_time_analysis.yaml
├── easy_rbfe_lig_ejm_31_complex_lig_ejm_47_complex.json
├── easy_rbfe_lig_ejm_31_complex_lig_ejm_48_complex
│   ├── shared_RelativeHybridTopologyProtocolUnit-5e71ee600e1d4991b9b0a5572bd25aab_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   ├── shared_RelativeHybridTopologyProtocolUnit-b27bfd7141894e868b3657733b4c2c43_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   ├── shared_RelativeHybridTopologyProtocolUnit-ec6d52ba2769435ab98c5bc48e88afad_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── nan-error-logs
│   │   │   ├── iteration0-replica4-state4-integrator.xml
│   │   │   ├── iteration0-replica4-state4-move.json
│   │   │   ├── iteration0-replica4-state4-state.xml
│   │   │   └── iteration0-replica4-state4-system.xml
│   │   └── simulation.nc
│   └── shared_RelativeHybridTopologyProtocolUnit-ec6d52ba2769435ab98c5bc48e88afad_attempt_1
│       ├── checkpoint.nc
│       ├── db.json
│       ├── simulation.nc
│       └── simulation_real_time_analysis.yaml
├── easy_rbfe_lig_ejm_31_complex_lig_ejm_48_complex.json
├── easy_rbfe_lig_ejm_31_complex_lig_ejm_50_complex
│   ├── shared_RelativeHybridTopologyProtocolUnit-16c84d712bce424b80b607cd2b5b69c5_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   ├── shared_RelativeHybridTopologyProtocolUnit-b071ec9b5b04478d995144e9cc3d4370_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   └── shared_RelativeHybridTopologyProtocolUnit-e0d41b9e7a8b41b5aee845beebdc7be5_attempt_0
│       ├── checkpoint.nc
│       ├── db.json
│       ├── simulation.nc
│       └── simulation_real_time_analysis.yaml
├── easy_rbfe_lig_ejm_31_complex_lig_ejm_50_complex.json
├── easy_rbfe_lig_ejm_31_solvent_lig_ejm_42_solvent
│   ├── shared_RelativeHybridTopologyProtocolUnit-2955a31793c0462e96bbc9ac7fdf9d5c_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   ├── shared_RelativeHybridTopologyProtocolUnit-62ecdfe2aaa2411ea3b79b68001061c4_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   └── shared_RelativeHybridTopologyProtocolUnit-64e65ac639c242f293784482ca0183d5_attempt_0
│       ├── checkpoint.nc
│       ├── db.json
│       ├── simulation.nc
│       └── simulation_real_time_analysis.yaml
├── easy_rbfe_lig_ejm_31_solvent_lig_ejm_42_solvent.json
├── easy_rbfe_lig_ejm_31_solvent_lig_ejm_46_solvent
│   ├── shared_RelativeHybridTopologyProtocolUnit-91a47d662aa943608a37d8be94455218_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   ├── shared_RelativeHybridTopologyProtocolUnit-c683e0b16bb14a3d93b8c14d965ad12e_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   └── shared_RelativeHybridTopologyProtocolUnit-e350fa7b5fe149bdb97411343c9abe05_attempt_0
│       ├── checkpoint.nc
│       ├── db.json
│       ├── simulation.nc
│       └── simulation_real_time_analysis.yaml
├── easy_rbfe_lig_ejm_31_solvent_lig_ejm_46_solvent.json
├── easy_rbfe_lig_ejm_31_solvent_lig_ejm_47_solvent
│   ├── shared_RelativeHybridTopologyProtocolUnit-962ca809a03e4098965ffbd598350693_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   ├── shared_RelativeHybridTopologyProtocolUnit-af88efbfc2044211af65d3e13ac1c3fd_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   └── shared_RelativeHybridTopologyProtocolUnit-de29f887e4504d83a5e1f9b11190753b_attempt_0
│       ├── checkpoint.nc
│       ├── db.json
│       ├── simulation.nc
│       └── simulation_real_time_analysis.yaml
├── easy_rbfe_lig_ejm_31_solvent_lig_ejm_47_solvent.json
├── easy_rbfe_lig_ejm_31_solvent_lig_ejm_48_solvent
│   ├── shared_RelativeHybridTopologyProtocolUnit-50f509db4d414e1e8f705e3d11c15bb8_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   ├── shared_RelativeHybridTopologyProtocolUnit-5103f758a5804ae389acc3610b4f9fcb_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   └── shared_RelativeHybridTopologyProtocolUnit-edf6329e8639476eb03ad2388f1d5fd3_attempt_0
│       ├── checkpoint.nc
│       ├── db.json
│       ├── simulation.nc
│       └── simulation_real_time_analysis.yaml
├── easy_rbfe_lig_ejm_31_solvent_lig_ejm_48_solvent.json
├── easy_rbfe_lig_ejm_31_solvent_lig_ejm_50_solvent
│   ├── shared_RelativeHybridTopologyProtocolUnit-04add6486b1d45ecaeaf080a755e9adc_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   ├── shared_RelativeHybridTopologyProtocolUnit-8ed001eb1c994ee794d07d8656d2d759_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── nan-error-logs
│   │   │   ├── iteration0-replica6-state6-integrator.xml
│   │   │   ├── iteration0-replica6-state6-move.json
│   │   │   ├── iteration0-replica6-state6-state.xml
│   │   │   └── iteration0-replica6-state6-system.xml
│   │   └── simulation.nc
│   ├── shared_RelativeHybridTopologyProtocolUnit-8ed001eb1c994ee794d07d8656d2d759_attempt_1
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   └── shared_RelativeHybridTopologyProtocolUnit-944bf8f60e9545ada837b5fd370e7afc_attempt_0
│       ├── checkpoint.nc
│       ├── db.json
│       ├── simulation.nc
│       └── simulation_real_time_analysis.yaml
├── easy_rbfe_lig_ejm_31_solvent_lig_ejm_50_solvent.json
├── easy_rbfe_lig_ejm_42_complex_lig_ejm_43_complex
│   ├── shared_RelativeHybridTopologyProtocolUnit-35fdb1172f9e4158b75a17e6d227000a_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   ├── shared_RelativeHybridTopologyProtocolUnit-436f4e31a6624441a5cb13fcecabbf95_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   └── shared_RelativeHybridTopologyProtocolUnit-e9ebcb03a29446839bfbc8707d457a09_attempt_0
│       ├── checkpoint.nc
│       ├── db.json
│       ├── simulation.nc
│       └── simulation_real_time_analysis.yaml
├── easy_rbfe_lig_ejm_42_complex_lig_ejm_43_complex.json
├── easy_rbfe_lig_ejm_42_solvent_lig_ejm_43_solvent
│   ├── shared_RelativeHybridTopologyProtocolUnit-2e826890deb24b7c811f4c19d58ac06e_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   ├── shared_RelativeHybridTopologyProtocolUnit-33ab8a39e317441eb698504a9b2ac9fa_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   └── shared_RelativeHybridTopologyProtocolUnit-4eb19a89aba3424194a9b5a91a9b9f5b_attempt_0
│       ├── checkpoint.nc
│       ├── db.json
│       ├── simulation.nc
│       └── simulation_real_time_analysis.yaml
├── easy_rbfe_lig_ejm_42_solvent_lig_ejm_43_solvent.json
├── easy_rbfe_lig_ejm_46_complex_lig_jmc_23_complex
│   ├── shared_RelativeHybridTopologyProtocolUnit-0b4187b6cbc449d38d6f86eb16e4cc8e_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   ├── shared_RelativeHybridTopologyProtocolUnit-5d8a4c4cedfc4f25be6f79291aabd8f2_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   └── shared_RelativeHybridTopologyProtocolUnit-d1609591a3df4bae8cabd1f3fb13666d_attempt_0
│       ├── checkpoint.nc
│       ├── db.json
│       ├── simulation.nc
│       └── simulation_real_time_analysis.yaml
├── easy_rbfe_lig_ejm_46_complex_lig_jmc_23_complex.json
├── easy_rbfe_lig_ejm_46_complex_lig_jmc_27_complex
│   ├── shared_RelativeHybridTopologyProtocolUnit-c6a62dbb56ad47c980cb8c31eebaf86d_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   ├── shared_RelativeHybridTopologyProtocolUnit-d19e3720aa8b444c91891dd73b1dfb28_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   └── shared_RelativeHybridTopologyProtocolUnit-e04de566fd2e4736ab55e7211ef56150_attempt_0
│       ├── checkpoint.nc
│       ├── db.json
│       ├── simulation.nc
│       └── simulation_real_time_analysis.yaml
├── easy_rbfe_lig_ejm_46_complex_lig_jmc_27_complex.json
├── easy_rbfe_lig_ejm_46_complex_lig_jmc_28_complex
│   ├── shared_RelativeHybridTopologyProtocolUnit-53142c3b31a6425caa3696590e91955e_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   ├── shared_RelativeHybridTopologyProtocolUnit-b6910c47aabe4abd91f5d4dee3434bfd_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   └── shared_RelativeHybridTopologyProtocolUnit-cc9155666425432bb137c2de6ee4ac05_attempt_0
│       ├── checkpoint.nc
│       ├── db.json
│       ├── simulation.nc
│       └── simulation_real_time_analysis.yaml
├── easy_rbfe_lig_ejm_46_complex_lig_jmc_28_complex.json
├── easy_rbfe_lig_ejm_46_solvent_lig_jmc_23_solvent
│   ├── shared_RelativeHybridTopologyProtocolUnit-13f850b796b747febbdddf1d5053961f_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   ├── shared_RelativeHybridTopologyProtocolUnit-7852489b28a041f4afc325c620fff0a9_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   ├── shared_RelativeHybridTopologyProtocolUnit-f19951263162439e8c96b19037d86f1c_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── nan-error-logs
│   │   │   ├── iteration0-replica3-state3-integrator.xml
│   │   │   ├── iteration0-replica3-state3-move.json
│   │   │   ├── iteration0-replica3-state3-state.xml
│   │   │   └── iteration0-replica3-state3-system.xml
│   │   └── simulation.nc
│   └── shared_RelativeHybridTopologyProtocolUnit-f19951263162439e8c96b19037d86f1c_attempt_1
│       ├── checkpoint.nc
│       ├── db.json
│       ├── simulation.nc
│       └── simulation_real_time_analysis.yaml
├── easy_rbfe_lig_ejm_46_solvent_lig_jmc_23_solvent.json
├── easy_rbfe_lig_ejm_46_solvent_lig_jmc_27_solvent
│   ├── shared_RelativeHybridTopologyProtocolUnit-04bc53fa4e4a4398910307cd354f8179_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   ├── shared_RelativeHybridTopologyProtocolUnit-3319d7e202354cba98f344a3c4c2a5e9_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   └── shared_RelativeHybridTopologyProtocolUnit-4e61c716d7b4414a8f8b16599da3d335_attempt_0
│       ├── checkpoint.nc
│       ├── db.json
│       ├── simulation.nc
│       └── simulation_real_time_analysis.yaml
├── easy_rbfe_lig_ejm_46_solvent_lig_jmc_27_solvent.json
├── easy_rbfe_lig_ejm_46_solvent_lig_jmc_28_solvent
│   ├── shared_RelativeHybridTopologyProtocolUnit-302a5fe948b14083a359b7e91aaad876_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   ├── shared_RelativeHybridTopologyProtocolUnit-60df96a488094f63978880d19487d299_attempt_0
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── nan-error-logs
│   │   │   ├── iteration0-replica1-state1-integrator.xml
│   │   │   ├── iteration0-replica1-state1-move.json
│   │   │   ├── iteration0-replica1-state1-state.xml
│   │   │   └── iteration0-replica1-state1-system.xml
│   │   └── simulation.nc
│   ├── shared_RelativeHybridTopologyProtocolUnit-60df96a488094f63978880d19487d299_attempt_1
│   │   ├── checkpoint.nc
│   │   ├── db.json
│   │   ├── simulation.nc
│   │   └── simulation_real_time_analysis.yaml
│   └── shared_RelativeHybridTopologyProtocolUnit-fada12bc48b748a987a25375b31ac8c7_attempt_0
│       ├── checkpoint.nc
│       ├── db.json
│       ├── simulation.nc
│       └── simulation_real_time_analysis.yaml
└── easy_rbfe_lig_ejm_46_solvent_lig_jmc_28_solvent.json
```

The JSON results file contains not only the calculated $\Delta G$, and
uncertainty estimate, but also important metadata about what happened during
the simulation. In particular, it will contain information about any errors or
failures that occurred -- these errors will not cause the entire campaign to
fail, and will be recorded so you can later analyze what went wrong.

To gather all the $\Delta G$ estimates into a single file, use the `openfe
gather` command from within the working directory used above:

```bash
openfe gather results/ --report dg -o final_results.tsv
```

This will write out a tab-separated table of results where the results
reported are controlled by the `--report` option:

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
