import openfe
from rdkit import Chem
from rdkit.Chem import AllChem
from openfe import SmallMoleculeComponent
from openfe.setup import LomapAtomMapper
# from openfe.setup.ligand_network_planning import generate_lomap_network

import lomap

# Extract the contents of the sdf file and visualise it
ligands_rdmol = [
    mol for mol in Chem.SDMolSupplier("inputs/tyk2_ligands.sdf", removeHs=False)
]

for ligand in ligands_rdmol:
    AllChem.Compute2DCoords(ligand)

Chem.Draw.MolsToGridImage(ligands_rdmol)


# Load ligands using RDKit
ligands_sdf = Chem.SDMolSupplier("inputs/tyk2_ligands.sdf", removeHs=False)

# Now pass these to form a list of Molecules
ligand_mols = [SmallMoleculeComponent(sdf) for sdf in ligands_sdf]

mapper = LomapAtomMapper()
lomap_mapping = next(mapper.suggest_mappings(ligand_mols[0], ligand_mols[4]))

lomap_network = lomap.generate_lomap_network(
    molecules=ligand_mols,
    scorer=openfe.lomap_scorers.default_lomap_score,
    mappers=[
        LomapAtomMapper(),
    ],
)
