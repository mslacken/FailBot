#!/bin/bash
ARCH=x86_64
REPO=standard
PROJECT=openSUSE:Factory
MODEL="ollama:qwen3:0.6b"
MCPHOST=~/programming/github/mcphost/mcphost

id=`date +%s`

pattern=".*"

usage() {
  cat <<EOF
Usage: $0 [-p <pattern>] [-m <models>]
  -p, --pattern  : Filter failed packages by a pattern (default: "$pattern")
  -m, --models   : Specify the model to use (default: "$MODEL"), can be a comma seperated list
  -h, --help     : Display this help message
EOF
}

# Parse command line options
OPTS=$(getopt -o p:m:h --long pattern:,models:,help -n 'explain-failed.sh' -- "$@")
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi

eval set -- "$OPTS"

while true; do
  case "$1" in
    -p | --pattern )
      pattern="$2"
      shift 2
      ;;
    -m | --models )
      MODEL="$2"
      shift 2
      ;;
    -h | --help )
      usage
      exit 0
      ;;
    -- )
      shift
      break
      ;;
    * )
      break
      ;;
  esac
done


failedPackages=`osc prjresults $PROJECT -s F -b -r standard | awk '/'$pattern'/ {print $1}' `

IFS=',' read -ra MODELS <<< "$MODEL"

for pkg in $failedPackages; do 
	for model in "${MODELS[@]}"; do
		echo "Checking package: $pkg with model $model"
		logfile=${pkg}_${model//:/_}_${id}.md
		starttime=`date +%s`
		$MCPHOST -m "$model" --compact --stream=false script explain-mcphost --args:PKG $pkg --args:PROJECT $PROJECT --args:REPO $REPO --args:ALLOWED `pwd` --args:OUT ${logfile}
		endtime=`date +%s`
		test -e ${logfile} && echo -e "\nRun for $(( $endtime - $starttime )) s" >> ${logfile}
	done
done
