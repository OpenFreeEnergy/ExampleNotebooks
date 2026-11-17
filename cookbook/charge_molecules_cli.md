# Assign partial charges with the CLI

This guide shows how to use the `openfe charge-molecules` command to assign partial charges to a set of ligands once,
and store them in an SDF file that can be used with OpenFE protocols.

Using a single set of charges for each ligand keeps the charges consistent between repeats and between the different
legs of a calculation involving the same ligand. This is necessary for reproducible results: AM1-BCC charges can differ
slightly each time they are calculated, which affects the calculated free energies
(see [Osato et al.](https://chemrxiv.org/engage/chemrxiv/article-details/67579833085116a133e39d86)).
`plan-rbfe-network` and `plan-rhfe-network` assign charges every time they are run, so charging the ligands once
ahead of time also keeps the charges the same across planning runs, and saves time when you try out several network setups.

## Charge the molecules

Pass the molecules as an SDF file, or as a directory of SDF or MOL2 files, and the name of the output SDF file:

```bash
openfe charge-molecules -M tyk2_ligands.sdf -o charged_tyk2_ligands.sdf
```

By default, the charges are calculated with the `am1bcc` method using `ambertools`.
The output file (`charged_tyk2_ligands.sdf`) contains the same ligands, with their partial charges stored in an `atom.dprop.PartialCharge` SD tag:

```text
lig_ejm_42
     RDKit          3D

 35 36  0  0  0  0  0  0  0  0999 V2000
   -4.7651   -2.8327  -16.5085 H   0  0  0  0  0  0  0  0  0  0  0  0
   -5.3566   -3.6931  -16.2274 C   0  0  0  0  0  0  0  0  0  0  0  0
   -4.7703   -4.9699  -16.2000 C   0  0  0  0  0  0  0  0  0  0  0  0
[continues]
 28 31  1  0
M  END

>  <ofe-name>
lig_ejm_42

>  <atom.dprop.PartialCharge>
0.14794282857142857 -0.096057171428571425 -0.12905717142857143 ...
[continues]
```

Generating partial charges with the `am1bcc` method can be slow as they require a semi-empirical quantum chemical calculation. 
We can however take advantage of multiprocessing to calculate the charges in parallel for each ligand which offers a 
significant speed-up. The number of processors available for the workflow can be specified using the `-n` flag. For 
example to spread out the calculation over 4 cores:

```bash
openfe charge-molecules -M tyk2_ligands.sdf -o charged_tyk2_ligands.sdf -n 4
```

## Use the charged ligands

Pass the output file to the planning commands in place of the original ligands:

```bash
openfe plan-rbfe-network -M charged_tyk2_ligands.sdf -p tyk2_protein.pdb -o network_setup
```

Charges that are already present in the input are used as they are, so the planning commands do not assign new ones.

## Use a different charge method

To use a different charge method, pass a settings file in YAML format with `-s`.

For example to recreate the current default settings in the workflow you would do the following:

1. Provide a file like `settings.yaml` with the desired settings:

```yaml
partial_charge:
  method: am1bcc
  settings:
    off_toolkit_backend: ambertools
```

2. Charge the ligands with an additional `-s` flag for passing the settings:

```bash
openfe charge-molecules -M tyk2_ligands.sdf -o charged_tyk2_ligands.sdf -n 4 -s settings.yaml
```

3. The output of the CLI program will now reflect the changes made:

```text
SMALL MOLECULE PARTIAL CHARGE GENERATOR
_________________________________________

Parsing in Files: 
	Got input: 
		Small Molecules: SmallMoleculeComponent(name=lig_ejm_31) SmallMoleculeComponent(name=lig_ejm_42) SmallMoleculeComponent(name=lig_ejm_43) SmallMoleculeComponent(name=lig_ejm_46) SmallMoleculeComponent(name=lig_ejm_47) SmallMoleculeComponent(name=lig_ejm_48) SmallMoleculeComponent(name=lig_ejm_50) SmallMoleculeComponent(name=lig_jmc_23) SmallMoleculeComponent(name=lig_jmc_27) SmallMoleculeComponent(name=lig_jmc_28)
Using Options:
	Partial Charge Generation: am1bcc
```

The full range of partial charge settings can be found in the snippet below, note that some may require installing extra packages.

```yaml
partial_charge:
  # Choose one method:
  method: am1bcc
  # method: am1bccelf10
  # method: espaloma
  # method: nagl
  # method: forcefield  # use a SMIRNOFF force field to assign charges; requires `forcefields` to be set below
  
  settings:
    off_toolkit_backend: ambertools
    # off_toolkit_backend: openeye  # required for the am1bccelf10 method
    number_of_conformers: null  # null specifies the use of the input conformer, a value requests that a new conformer be generated. Recommended to use a value of 500 for am1bccelf10.
    # nagl_model: null  # null specifies the use of the latest nagl model
    # forcefields: [openff-2.3.0.offxml]  # list the SMIRNOFF force field(s) used by `method: forcefield`
```

## Overwrite existing charges

By default, `charge-molecules` only assigns partial charges to ligands that **do not** already have them.
To replace existing charges with new ones calculated using the chosen settings, add `--overwrite-charges`.