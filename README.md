# CogWheel
OpenShift Scale Tests Orchestrator

![Alt text](logo/cogwheel.png)

### Dependencies
```
- Git
- Latest OC client
```

### Run
```
$ git clone https://github.com/chaitanyaenr/cogwheel.git
$ cd cogwheel
$ cp cogwheel_env.example.sh cogwheel_env.sh 
```

Options supported by cogwheel:
```
$ ./cogwheel.sh help

Usage: source cogwheel_env.example.sh; ./cogwheel.sh

Options supported:
	 run_scale_test=str,            str=true or false
	 scale_test_image=str,          str=Image to run
	 cleanup=str,                   str=true or false
	 kubeconfig_path=str,           str=path to the kubeconfig
	 cogwheel_repo_location=str,    str=path to the cogwheel repo
	 properties_file_path=str,      str=path to the properties file
	 capture_prometheus_db=str,     str=true or false
	 prometheus_db_path=str,        str=path to export the prometheus DB
```

Images supported:

Image | Description | Privileged | Scale Cluster | Starter | OSD |
----- | ----------- | ---------- | ------------- | ------- | --- |
ravielluri/image:nodevertical | kubelet density focused test which creates max pods per compute node | False | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
ravielluri/image:mastervertial | control plane density focused test | False | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
BYO ( Bring your own workload ) | Any image which works on OCP cluster | True/False ( False is preferred for it to work on Starter and OSD clusters | NA | NA | NA |

Set the environment variables in cogwheel_env.sh and source it. Available options:
```
$ source cogwheel_env.sh
$ ./cogwheel.sh
```

#### Credits
Created my free logo at LogoMakr.com.
