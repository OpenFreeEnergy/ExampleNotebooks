# Task-Based Execution with the OpenFE CLI

When using `openfe quickrun`, you orchestrate the campaign. You choose which
`Transformation` to run and when to run it.

With task-based execution, **openfe** handles that orchestration for you. You provide
an entire `AlchemicalNetwork`, **openfe** breaks it into dependent tasks, and one or
more `Worker`s claim tasks as soon as they are ready to run.

A **task** is a single `ProtocolUnit`, for example the setup, simulation, or
analysis step of one repeat of one `Transformation`.

Three resources make up a task-based campaign:

- the **Warehouse** stores the campaign data needed for execution, including the
  `AlchemicalNetwork`, tasks, and results;
- the **TaskStatusDB** tracks task status and dependencies;
- one or more **Workers** claim available tasks, execute them, and store the results.

This tutorial walks through a task-based campaign using the OpenFE command-line
interface. For the equivalent workflow using the Python API, see the
[Task-Based Execution with the Python API tutorial](...).

> **Note:** To run this tutorial, clone the OpenFE ExampleNotebooks repository
> and run these commands from the tutorial directory. The example input files
> used below are included in the repository.

## 1. Start from an `AlchemicalNetwork`

The input to a task-based campaign is an `AlchemicalNetwork`.

Here we use a small MCL-1 network with pre-charged ligands and two edges,
`ligand_1 → ligand_2` and `ligand_2 → ligand_3`. Each edge has a complex and a
solvent leg, giving four `Transformation`s.

For this example, each `Transformation` has one repeat, and each repeat of the
hybrid-topology protocol consists of setup, simulation, and analysis units.
The campaign therefore contains 12 tasks in total.

If you are setting up your own campaign with `openfe plan-rbfe-network` or
`openfe plan-rhfe-network`, use `--networks-only` to generate an
`AlchemicalNetwork` for task-based execution. For example:

```bash
openfe plan-rbfe-network -M ligands.sdf -p protein.pdb --networks-only -o alchemicalNetwork_mc1_small --n-protocol-repeats=1
```

This creates an `AlchemicalNetwork` JSON file that can be used as input to
`openfe setup-task-campaign`.

> **Note:** Unlike `quickrun` execution, task-based execution creates a separate set of tasks for each repeat, 
> so different repeats can be executed in parallel by different workers. 
> For production calculations, we recommend keeping the default of `--n-protocol-repeats=3`. 
> To keep this tutorial small, however, we use a single repeat.

## 2. Set up the campaign

Use `openfe setup-task-campaign` to create the resources needed for task-based
execution. By default, the `TaskStatusDB` and `Warehouse` will be created using the input file basename, 
but you can pass in the `--name` parameter to define the identifier for the `Warehouse` and `TaskStatusDB` file names.

```bash
openfe setup-task-campaign --alchemical-network alchemicalNetwork_mc1_small/alchemicalNetwork_mc1_small.json --name mcl1
```

You should see a `Warehouse` (`warehouse_tyk2/`) in the form of a directory and a `TaskStatusDB` (`tasks_tyk2.db`) file as output.

```text
warehouse_mcl1/
tasks_mcl1.db
```

The `Warehouse` contains the campaign data and results, while the
`TaskStatusDB` contains the orchestration state of the campaign.

> **Warning:** The `Warehouse` has a specific directory structure and should not
> be edited manually.

At this point, the `Warehouse` contains the information needed to describe and
execute the campaign:

```text
warehouse_mcl1/
├── protocol_dags/
├── results/
├── setup/
├── shared/
└── tasks/
```

The `setup`, `tasks`, and `protocol_dags` stores are populated when the campaign
is created. `results` and `shared` are populated during execution.

> **Note:** If you're migrating from `quickrun`-based execution, the `Warehouse` directory contains the information that would 
> otherwise be stored across a directory of `transformation.json` files, organized in a different structure for 
> task-based execution.

## 3. Inspect task status

The `TaskStatusDB` is the source of truth for the execution state of the
campaign.

You can inspect it at any time with:

```bash
openfe status --task-db tasks_mcl1.db
```

For this network, there are initially:

```text
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━┳━━━━━━━━━━━━━━━┳━━━━━━━┳━━━━━━━━━━━┓
┃ taskid                                                                  ┃ status    ┃ last_modified ┃ tries ┃ max_tries ┃
┡━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━╇━━━━━━━━━━━━━━━╇━━━━━━━╇━━━━━━━━━━━┩
│ HybridTopologySetupUnit-31fdc6a...                                      │ AVAILABLE │ NaT           │ 0     │ 1         │
│ HybridTopologySetupUnit-15899f7...                                      │ AVAILABLE │ NaT           │ 0     │ 1         │
│ HybridTopologySetupUnit-9212216...                                      │ AVAILABLE │ NaT           │ 0     │ 1         │
│ HybridTopologySetupUnit-d5d714f...                                      │ AVAILABLE │ NaT           │ 0     │ 1         │
│ HybridTopologyMultiStateSimulationUnit-415456a...                       │ BLOCKED   │ NaT           │ 0     │ 1         │
│ HybridTopologyMultiStateSimulationUnit-23aea7d...                       │ BLOCKED   │ NaT           │ 0     │ 1         │
│ ...                                                                     │ ...       │ ...           │ ...   │ ...       │
│ HybridTopologyMultiStateAnalysisUnit-9354cb2...                         │ BLOCKED   │ NaT           │ 0     │ 1         │
└─────────────────────────────────────────────────────────────────────────┴───────────┴───────────────┴───────┴───────────┘
```

Initially, the four setup tasks are `AVAILABLE`. The simulation and analysis
tasks are `BLOCKED` because their dependencies have not completed yet.
The `tries` column records how many times a task has been attempted, while
`max_tries` gives the maximum number of attempts allowed.

To display only the number of tasks in each state, use:

```bash
openfe status --task-db tasks_mcl1.db --summary
```

```text
┏━━━━━━━━━━━━━━━━━━┳━━━━━━━━━┓
┃ status           ┃ n_tasks ┃
┡━━━━━━━━━━━━━━━━━━╇━━━━━━━━━┩
│ BLOCKED          │       8 │
│ AVAILABLE        │       4 │
│ IN_PROGRESS      │       0 │
│ COMPLETED        │       0 │
│ TOO_MANY_RETRIES │       0 │
│ ERROR            │       0 │
└──────────────────┴─────────┘
```

As execution proceeds, tasks move through states such as `AVAILABLE`,
`IN_PROGRESS`, and `COMPLETED`. Failed tasks are retried up to `max_tries`, then marked `TOO_MANY_RETRIES`.

## 4. Execute one task

A worker uses the `Warehouse` and the `TaskStatusDB` to execute tasks from the campaign.
To execute one available task, run:

```bash
openfe run-task --warehouse warehouse_mcl1/ --task-db tasks_mcl1.db --scratch scratch/
```

You do not choose which specific task is executed. `openfe run-task` claims an
`AVAILABLE` task from the `TaskStatusDB`, retrieves the corresponding
`ProtocolUnit` and any required upstream data from the `Warehouse`, and executes
it.

Now, you will see that a `scratch/` directory has been created locally, which is needed for quick read/write 
operations during execution. Use the `--scratch` argument to specify where to create this directory; 
by default, it will be created in the current directory and named `scratch/`.

You'll now see that one task has been completed, and a new task has been unblocked:

```bash
openfe status --task-db tasks_mcl1.db
```

```text
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━┳━━━━━━━━━━━┓
┃ taskid                                                                  ┃ status    ┃ last_modified       ┃ tries ┃ max_tries ┃
┡━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━╇━━━━━━━━━━━┩
│ HybridTopologySetupUnit-31fdc6a...                                      │ COMPLETED │ 2026-10-06 13:10:00 │ 1     │ 1         │
│ HybridTopologySetupUnit-15899f7...                                      │ AVAILABLE │ NaT                 │ 0     │ 1         │
│ HybridTopologySetupUnit-9212216...                                      │ AVAILABLE │ NaT                 │ 0     │ 1         │
│ HybridTopologyMultiStateSimulationUnit-415456a...                       │ AVAILABLE │ 2026-10-06 13:10:00 │ 0     │ 1         │
│ HybridTopologyMultiStateSimulationUnit-23aea7d...                       │ BLOCKED   │ NaT                 │ 0     │ 1         │
│ ...                                                                     │ ...       │ ...                 │ ...   │ ...       │
│ HybridTopologyMultiStateAnalysisUnit-9354cb2...                         │ BLOCKED   │ NaT                 │ 0     │ 1         │
└─────────────────────────────────────────────────────────────────────────┴───────────┴─────────────────────┴───────┴───────────┘
```

One setup task is now `COMPLETED`, and the simulation task that depended on it is now `AVAILABLE`. 
The remaining downstream tasks stay `BLOCKED` until their dependencies are satisfied.

## 5. Run the rest of the campaign

Running `openfe run-task` once executes one task. A worker can repeatedly
execute tasks by calling it in a loop.

For example, a simple SLURM worker script could contain:

```bash
#!/bin/bash

#SBATCH --job-name="openfe-worker"
#SBATCH --gres=gpu:1
#SBATCH --mem-per-cpu=2G

# Activate the environment containing OpenFE
conda activate openfe_env

# continue submitting run-task in serial until the wall time is hit
# you may submit this *script* multiple times to have workers execute tasks in parallel
 
while true; do
    openfe run-task --warehouse warehouse_mcl1/ --task-db tasks_mcl1.db --scratch scratch/
done
```

In production, several independent workers can run in separate jobs on an HPC
system, all operating on the same campaign to execute tasks in parallel.
For example, using a SLURM job array:

```bash
sbatch --array=1-4 run_tasks.sh
```

All workers use the same `Warehouse` and `TaskStatusDB`. The task database
coordinates which tasks are available for each worker to claim.

## 6. Gather results

Running the complete simulations would take too long for this tutorial, so for
this section we use a completed `Warehouse` from the same example network.

Download and extract the completed Warehouse:

```bash
curl -fLO https://zenodo.org/records/23072369/files/warehouse_mcl1_small.gz
tar -xzf warehouse_mcl1_small.gz
```

This creates the warehouse_mcl1_small/ directory containing the results of the
completed campaign.

The `Warehouse` contains the `ProtocolUnitResult`s produced during execution.

Because task-based execution is currently under development, there is not yet a direct command to output the results. 
To enable complete workflows in the meantime, we provide the `openfe to-legacy-json` command to
convert these results into the JSON format accepted by the existing
`openfe gather` command:

```bash
openfe to-legacy-json warehouse_mcl1_small/ -o mcl1_result_jsons
```

The resulting directory can then be passed to `openfe gather` (and `openfe gather-septop`, `openfe gather-abfe`).

```bash
openfe gather mcl1_result_jsons/ --report=raw
```

For an RBFE campaign, `--report=raw` shows the individual complex and solvent
leg results. Other `openfe gather` report types can be used to obtain
edge-level relative free energies or network-level estimates.

## Summary

In this tutorial, we:

- created a task-based campaign from an `AlchemicalNetwork` with
  `openfe setup-task-campaign`;
- inspected task state with `openfe status`;
- used `openfe run-task` to claim and execute available tasks;
- saw how completing a task makes downstream tasks available;
- showed how multiple workers can execute tasks from the same campaign;
- gathered results produced by a completed campaign.