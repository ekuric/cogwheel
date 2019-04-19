#!/bin/bash

echo "$kubeconfig" > /root/.kube/config
cd /root/cogwheel/scale-tests
echo "Running $JOB"
./nodeVertical.sh /root/.kube/config
