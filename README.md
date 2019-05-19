# CogWheel
OpenShift Scale Tests Orchestrator

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

Set the environment variables in cogwheel_env.sh and source it. Available options:
```
$ source cogwheel_env.sh
$ ./cogwheel.sh
```
