#!/bin/bash
## Prints connection details for your currently RUNNING container job.
## The compute node (and therefore its IP) changes every time you resubmit,
## so run this after each submission.
##
## Usage: bash container_info.sh

PORT=17040
JOB_NAME=docker_a100
LOGIN_IP=10.0.7.71              # hlogin01
LOGIN_PORT=2123

JOBID=$(squeue -u "$USER" -h -n "$JOB_NAME" -t R -o "%i" | head -1)

if [ -z "$JOBID" ]; then
    echo "No RUNNING (R) '$JOB_NAME' job found."
    echo "Submit one with:  bash submit_docker.sh <number_of_gpus>"
    echo
    squeue -u "$USER"
    exit 1
fi

LOG="${JOB_NAME}_${JOBID}_log.txt"
NODE=$(squeue -j "$JOBID" -h -o "%N")
NODE_IP=$(grep "node IP" "$LOG" 2>/dev/null | awk '{print $4}')

if [ -z "$NODE_IP" ]; then
    echo "Could not read the node IP from: $LOG"
    echo "Run this from the directory you submitted the job from."
    exit 1
fi

echo "==============================================="
echo " JobID        : ${JOBID}"
echo " compute node : ${NODE}"
echo " node IP      : ${NODE_IP}"
echo " time left    : $(squeue -j "$JOBID" -h -o '%L')"
echo "==============================================="
echo
echo "[1] From the login node, test this FIRST:"
echo "    ssh -i ~/.ssh/id_rsa -p ${PORT} root@${NODE_IP}"
echo
echo "[2] On your own PC, put this in ~/.ssh/config and connect with"
echo "    VS Code Remote-SSH. Your PC's public key must already be in"
echo "    ~/.ssh/authorized_keys on the cluster."
cat <<EOF

Host hawk-login
    HostName ${LOGIN_IP}
    Port ${LOGIN_PORT}
    User ${USER}

Host hawk-container
    HostName ${NODE_IP}
    Port ${PORT}
    User root
    ProxyJump hawk-login
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
