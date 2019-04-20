#!/bin/bash

cogwheel_repo_location=$1
controller_namespace=controller
counter_time=5
wait_time=25
kubeconfig_path=$2
scale_test_image=$3
properties_file_path=$4

export KUBECONFIG=$kubeconfig_path

if [[ $# -ne 4 ]]; then
	echo "syntax: $0 <cogwheel-repo-location> <path-to-kubeconfig> <scale-test-image> <properties-file-path>"
	echo "<scale-test-image> can be ravielluri/image:nodevertical or ravielluri/image:mastervertical"
	exit 1
fi

# Cleanup
function cleanup() {
	oc process -p SCALE_TEST_IMAGE=$scale_test_image -f $cogwheel_repo_location/cogwheel/openshift-templates/controller/controller-job-template.yml | oc delete -n $controller_namespace -f -
	oc delete cm scale-config -n $controller_namespace
	sleep $wait_time
	oc delete project $controller_namespace
	sleep $wait_time
}

# Ensure that the host has congwheel repo cloned
if [[ ! -d $cogwheel_repo_location/cogwheel ]]; then
	 git clone https://github.com/chaitanyaenr/cogwheel.git $cogwheel_repo_location/cogwheel
fi

# Check if the project already exists
oc project $controller_namespace &>/dev/null
if [[ $? == 0 ]]; then
        echo "Looks like the $controller_namespace already exists, deleting it"
	cleanup
fi

# create controller ns, configmap, job to run the scale test
oc create -f $cogwheel_repo_location/cogwheel/openshift-templates/controller/controller-ns.yml
oc create configmap kube-config --from-literal=kubeconfig="$(cat $kubeconfig_path)" -n $controller_namespace
oc create configmap scale-config --from-env-file=$properties_file_path -n $controller_namespace
oc process -p SCALE_TEST_IMAGE=$scale_test_image -f $cogwheel_repo_location/cogwheel/openshift-templates/controller/controller-job-template.yml | oc create -n $controller_namespace -f -
sleep $wait_time
controller_pod=$(oc get pods -n $controller_namespace | grep "controller" | awk '{print $1}')
counter=0
while [[ $(oc --namespace=default get pods $controller_pod -n $controller_namespace -o json | jq -r ".status.phase") != "Running" ]]; do
	sleep $counter_time
	counter=$((counter+1))
	if [[ $counter -ge 120 ]]; then
		echo "Looks like the $controller_pod is not up after 120 sec, please check"
		exit 1
	fi
done

# logging
logs_counter=0
logs_counter_limit=500
oc logs -f $controller_pod -n $controller_namespace
while true; do
        logs_counter=$((logs_counter+1))
        if [[ $(oc --namespace=default get pods $controller_pod -n $controller_namespace -o json | jq -r ".status.phase") == "Running" ]]; then
                if [[ $logs_counter -le $logs_counter_limit ]]; then
			echo "=================================================================================================================================================================="
			echo "Attempt $logs_counter to reconnect and fetch the controller pod logs"
			echo "=================================================================================================================================================================="
			echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------"
			echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------"
                        oc logs -f $controller_pod -n $controller_namespace
                else
                        echo "Exceeded the retry limit trying to get the controller logs: $logs_counter_limit, exiting."
                        exit 1
                fi
        else
                echo "Job completed"
                break
        fi
done

# check the status of the controller pod
while [[ $(oc --namespace=default get pods $controller_pod -n $controller_namespace -o json | jq -r ".status.phase") != "Succeeded" ]]; do
	if [[ $(oc --namespace=default get pods $controller_pod -n $controller_namespace -o json | jq -r ".status.phase") == "Failed" ]]; then
   		echo "JOB FAILED"
		echo "CLEANING UP"
   		cleanup
   		exit 1
   	else        
    		sleep $wait_time
        fi
done
echo "JOB SUCCEEDED"

# cleanup
echo "CLEANING UP"
cleanup
