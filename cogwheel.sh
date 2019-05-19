#!/bin/bash

set -eo pipefail

function help () {
	printf "\n"
        printf "Usage: source cogwheel_env.example.sh; $0\n"
        printf "\n"
        printf "Options supported:\n"
	printf "\t run_scale_test=str,            str=true or false\n"
        printf "\t scale_test_image=str,          str=Image to run\n"
	printf "\t cleanup=str,                   str=true or false\n"
        printf "\t kubeconfig_path=str,           str=path to the kubeconfig\n"
        printf "\t cogwheel_repo_location=str,    str=path to the cogwheel repo\n"
        printf "\t properties_file_path=str,      str=path to the properties file\n"
        printf "\t capture_prometheus_db=str,     str=true or false\n"
        printf "\t prometheus_db_path=str,        str=path to export the prometheus DB\n"
}


# help
if [[ "$#" -ne 0 ]]; then
	help
	exit 1
fi

# Check if the vars have been defined
if [[ -z "$cogwheel_repo_location" ]]; then
	echo "cogwheel_repo_location is not defined, please check if it's defined as an environment variable"
	help
	exit 1
fi

if [[ -z "$scale_test_image" ]]; then
        echo "scale_test_image is not defined, please check if it's defined as an environment variable"
	help
        exit 1
fi

if [[ -z "$kubeconfig_path" ]]; then
        echo "kubeconfig_path is not defined, please check if it's defined as an environment variable"
	help
        exit 1
fi

if [[ -z "$properties_file_path" ]]; then
        echo "properties_file_path is not defined, please check if it's defined as an environment variable"
	help
        exit 1
fi

if [[ -z "$capture_prometheus_db" ]]; then
        echo "capture_prometheus_db is not defined, please check if it's defined as an environment variable"
	help
        exit 1
fi

if [[ -z "$prometheus_db_path" ]]; then
        echo "prometheus_db_path is not defined, please check if it's defined as an environment variable"
        help
        exit 1
fi

if [[ -z "$run_scale_test" ]]; then
	echo "run_scale_test is not defined, please check it's defined as an env variable"
	help
	exit 1
fi

if [[ -z "$cleanup" ]]; then
        echo "cleanup is not defined, please check if it's defined as an environment variable"
	exit 1
fi

# Defaults
controller_namespace=controller
counter_time=5
wait_time=25
prometheus_namespace=openshift-monitoring

export KUBECONFIG=$kubeconfig_path

# Cleanup
function cleanup() {
	oc delete project --wait=true $controller_namespace
	echo "sleeping for $wait_time for the cluster to settle"
	sleep $wait_time
}

function promtheus_db_capture() {
        # pick a prometheus pod
        prometheus_pod=$(oc get pods -n $prometheus_namespace | grep -w "Running" | awk -F " " '/prometheus-k8s/{print $1}' | tail -n1)
        # copy the prometheus DB from the prometheus pod
        echo "copying prometheus DB from $prometheus_pod"
        oc cp $prometheus_namespace/$prometheus_pod:/prometheus/wal -c prometheus wal/
        echo "creating a tarball of the captured DB at $prometheus_db_path"
        XZ_OPT=--threads=0 tar cJf $prometheus_db_path/prometheus.tar.xz wal
        if [[ $? == 0 ]]; then
                rm -rf wal
        fi
}

function run_scale_test() {
	# Ensure that the host has congwheel repo cloned
	if [[ ! -d $cogwheel_repo_location/cogwheel ]]; then
		git clone https://github.com/chaitanyaenr/cogwheel.git $cogwheel_repo_location/cogwheel
	fi

	# Check if the project already exists
	if [[ $(oc project $controller_namespace &>/dev/null) ]]; then
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
}

# run scale test
if [[ "$run_scale_test" == true ]]; then
	run_scale_test
fi

# cleanup
if [[ "$cleanup" == true ]]; then
	echo "CLEANING UP"
        cleanup
fi

# capture prometheus DB
if [[ "$capture_prometheus_db" == true ]]; then
	echo "Capturing prometheus DB"
	promtheus_db_capture
fi
