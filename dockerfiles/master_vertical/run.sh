#!/bin/bash

echo "$kubeconfig" > /root/.kube/config
cd /root/svt/openshift_scalability
echo "Setting up the config"
sed -i "/- num/c  \  - num: $PROJECTS" /root/cogwheel/scale-tests/config/pyconfigMasterVertScale.yaml
echo "Running $JOB scale test"
./masterVertical.sh python $MODE
