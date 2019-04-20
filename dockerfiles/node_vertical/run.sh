#!/bin/bash

echo "$kubeconfig" > /root/.kube/config
if [[ "$JOB" == "nodevertical" ]]; then
	cd /root/cogwheel/scale-tests
	echo "Running $JOB"
	./nodeVertical.sh /root/.kube/config
elif [[ "$JOB" == "test" ]]; then
	echo "sleep infinity"
	sleep infinity
else
	echo "$JOB is not a valid option"
	exit 1
fi
