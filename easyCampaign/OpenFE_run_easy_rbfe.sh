#!/usr/bin/env bash
# RUN an easy RBFE calculaion Campaign
# ==============================
# To install OpenFE use:
# conda install -c conda-forge openfe

# Preperations:
shopt -s nullglob
set -euxo pipefail

mkdir rbfe_calculation -p
cd rbfe_calculation || exit

# PLAN the calculations
openfe plan-rbfe-network -m ../molecules/rbfe/p38_old_ligands.sdf -p ../molecules/rbfe/p38_old_protein.pdb -o a_alchemicalNetwork

# DO the calculations
mkdir b_simulation c_results -p
cd b_simulation || exit
for transformation in ../a_alchemicalNetwork/transformations/*/a_alchemicalNetwork*.json
  do
    filename=$(basename "${transformation%.json}")
    echo "${filename}"
    cmd="openfe quickrun ${transformation} -d ./ -o ../c_results/result_${filename}.json\n"
    echo -e "${cmd}"
    echo -e "#!/usr/bin/env bash\n" > "job_${filename}.sh"
    echo -e "${cmd}" >> "job_${filename}.sh"

    sbatch "job_${filename}.sh"
  done

cd ..

# Analysis: FUTURE
# openfe gather_result_jsons -result_json_dir c_results -out_csv dG.csv
