# ibex-machine-learning-modules

Environment configuration files for the Ibex machine-learning modules.

## Creating the Conda environment

The most efficient way to build Conda environments on Ibex is to launch the environment creation script as a job on 
the debug partition via Slurm. For your convenience a Slurm job script `./bin/create-conda-env.sbatch` is included. 
The script should be run from the project root directory as follows.

```bash
sbatch ./bin/create-conda-env.sbatch
```

## Listing the contents of the Conda environment

The list of explicit dependencies can be found in the `environment.yml` and the `requirements.txt` files. To see the 
full list of packages installed into the environment run the following command.

```bash
conda list --prefix $ENV_PREFIX
```

## Exporting the Conda environment file

It is sometimes useful to generate a Conda environment file from the already created environment that explicitly 
includes the version and build numbers for every package included in the environment. You can do this with the 
following command.

```bash
conda env export --prefix $ENV_PREFIX | head -n -1 > exported-environment.yml
```

Be sure to confirm that the channel priority in the `exported-environment.yml` file matches the channel priority 
in the `environment.yml` file. If the channel priorities are not the same, then manually edit the channel priorities 
of the `exported-environment.yml` file to match those of the `environment.yml` file.

