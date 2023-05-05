#!/usr/bin/env bash
# RUN an easy RHFE calculaion Campaign
# ==============================
# To install OpenFE use:
# conda install -c conda-forge openfe

# Preperations:
shopt -s nullglob
set -euxo pipefail

mkdir rhfe_calculation -p
cd rhfe_calculation || exit

# PLAN the calculations
openfe plan-rhfe-network -M ../molecules/rhfe/benzenes_RHFE.sdf -o a_alchemicalNetwork

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
