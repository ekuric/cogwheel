#!/bin/bash

echo "$kubeconfig" > /root/.kube/config
if [[ "$JOB" == "test" ]]; then
	echo "sleep infinity"
	sleep infinity
elif [[ "$JOB" == "mastervertical" ]]; then
	cd /root/svt/openshift_scalability
	echo "Setting up the config"
	sed -i "/- num/c  \  - num: $PROJECTS" /root/cogwheel/scale-tests/config/pyconfigMasterVertScale.yaml
	echo "Running $JOB scale test"
	./masterVertical.sh python $MODE
else
	echo "$JOB is not an supported option"
	exit 1
fi
