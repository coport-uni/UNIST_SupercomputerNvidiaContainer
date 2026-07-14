#!/bin/bash
## Submits docker_a100.sh with a matching GPU / CPU-core count.
##
## Usage:   bash submit_docker.sh <number_of_gpus>
## Example: bash submit_docker.sh 1
##
## NOTE: with no argument this defaults to 8 GPUs, i.e. a whole node. Pass 1
## when you are just testing, otherwise you may queue for a very long time.
##
## Handy:
##   squeue -u $USER
##   scancel <JobID>
##   scontrol show job <JobID>
##   squeue -u $USER -o "%.10i %.20j %.12M %.12L %.12l %R"

GPUS=${1:-8}
CORES=$((GPUS * 16))    # Cluster rule: 16 CPU cores per GPU.
                        # Asking for more cores per GPU makes the job pend forever.

echo "Submitting with ${GPUS} GPU(s), ${CORES} CPU core(s)."
sbatch --gres=gpu:${GPUS} -n ${CORES} docker_a100.sh
