#!/bin/bash
#SBATCH -J docker_a100          # Job name
#SBATCH -p a100_40g             # Partition. Verify the real name with `sinfo`
#SBATCH -N 1                    # 1 compute node. Docker jobs must stay on one node
#SBATCH -o %x_%j_log.txt        # stdout -> docker_a100_<jobid>_log.txt
#SBATCH -e %x_%j_err.txt        # stderr -> docker_a100_<jobid>_err.txt
#SBATCH --time 12:00:00         # Wall time. 12h is the max for the ngpu account
## GPU count (--gres=gpu:N) and CPU cores (-n) are passed by submit_docker.sh
## as command-line options, which override #SBATCH directives.

module purge

PORT=17040
NODE_IP=$(hostname -i | awk '{print $1}')

echo "==============================================="
echo " compute node : $(hostname)"
echo " node IP      : ${NODE_IP}"
echo " SSH          : ssh -p ${PORT} root@${NODE_IP}"
echo " container    : ${USER}_${SLURM_JOB_ID}"
echo "==============================================="

CONT='pealunist/universial_docker:cuda130-2404'
MOUNT=/workspace                # Mount point inside the container

## WHY WE RUN sshd EXPLICITLY:
## This image's default CMD is ["/bin/bash"] and it does NOT start sshd.
## Without -it, bash reads EOF from stdin and exits 0 immediately, the
## container dies, and SLURM marks the job COMPLETED after ~2 seconds.
## Running sshd in the foreground (-D) keeps both alive.
##
## --network host: exposes ${PORT} directly on the compute node's IP.
##
## authorized_keys is mounted read-only into /tmp and then COPIED to
## /root/.ssh as root. The original on the shared home is owned by your
## uid, but sshd inside the container runs as root, so a direct bind mount
## fails StrictModes and the key is silently ignored -> Permission denied.
##
## Only one docker container is allowed per SLURM job, so run it once.
nvidia-docker run --rm \
    --network host \
    -v "$PWD":$MOUNT -w $MOUNT \
    -v "$HOME/.ssh/authorized_keys":/tmp/authorized_keys:ro \
    $CONT \
    bash -lc "
        mkdir -p /run/sshd /root/.ssh
        cp /tmp/authorized_keys /root/.ssh/authorized_keys
        chown -R root:root /root/.ssh
        chmod 700 /root/.ssh
        chmod 600 /root/.ssh/authorized_keys
        exec /usr/sbin/sshd -D -e -p ${PORT}
    "
