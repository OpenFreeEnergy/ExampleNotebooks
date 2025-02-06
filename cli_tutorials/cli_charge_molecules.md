# Generating Partial Charges with the OpenFE CLI

This tutorial will show you how to use the OpenFE CLI to generate and store partial charges for a series of ligands 
which can be used with OpenFE protocols. It is recommended to use a single set of charges for each ligand to ensure reproducibility
between repeats or consistent charges between different legs of a calculation involving the same ligand, like a relative binding
affinity calculation for example. As such both the `plan-rbfe-network` and `plan-rhfe-network` commands will calculate 
partial charges for ligands making it expensive to run multiple network mappings while finding the optimal one for the resources 
available. Hence, the `charge-molecules` command offers a way to generate and store the charges into an SDF file which 
can be used with the rest of the OpenFE CLI and python API. 

## Charging Molecules

The `charge-molecules` command allows you to generate partial charges a series of small molecules saved in SDF or MOL2 
format using the `am1bcc` method calculated using `ambertools`:

```bash
openfe charge-molecules -M tyk2_ligands.sdf -o charged_tyk2_ligands.sdf
```

This will result in a new SDF file `charged_tyk2_ligands.sdf` which contains the same ligands and their partial charges 
stored in a new SD tag like so:

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

Generating partial charges with the `am1bcc` method can be slow as they require a semi-empirical quantum chemical calculation, 
we can however take advantage of multiprocessing to calculate the charges in parallel for each ligand which offers a 
significant speed-up. The number of processors available for the workflow can be specified using the `-n` flag:

```bash
openfe charge-molecules -M tyk2_ligands.sdf -o charged_tyk2_ligands.sdf -n 4
```

## Customizing the Charge Method

There are a wide range of partial charge generation methods available with `am1bcc` based schemes being most commonly 
used with OpenFF force fields. The choice of charge scheme can be easily customised by providing a settings file in `.yaml` format. 
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

The full range of partial charge settings can be found in the snipit bellow, note that some may require installing extra packages.

```yaml
partial_charge:
  method: am1bcc
  # method: am1bccelf10
  # method: espaloma
  # method: nagl
  settings:
    off_toolkit_backend: ambertools
    # off_toolkit_backend: openeye  # required for the am1bccelf10 method
    number_of_conformers: null  # null specifies the use of the input conformer, a value requests that a new conformer be generated
    # nagl_model: null  # null specifies the use of the latest nagl model
```

## Overwriting Charges

By default, the `charge-molecules` command will only assign partial charges to ligands which **do not** already have charges, 
this behaviour can be changed via the `--overwrite-charges` flag which will assign new charges using the specified settings.