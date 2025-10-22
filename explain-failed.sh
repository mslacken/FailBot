#!/bin/bash
ARCH=x86_64
REPO=standard
PROJECT=openSUSE:Factory
MODEL="ollama:qwen3:0.6b"
MCPHOST=~/programming/github/mcphost/mcphost

func create_mcp_conf() {
  mkdir -p .mcphost
cat <<EOF
hooks:
    PostToolUse:
        - matcher: .*
          hooks:
            - type: command
              command: 'jq  -c ''{tool: .tool_name, respones: (.tool_response | tostring )}''>> tools.out'
              timeout: 5
    PreToolUse:
        - matcher: .*
          hooks:
            - type: command
              command: 'jq  -c ''{name: .tool_name, input: .tool_input }''>> tools.in'
              timeout: 5

EOF
}

id=`date +%s`

test -d ${id} || mkdir ${id}

usage() {
  cat <<EOF
Usage: $0 [-p <package>] [-m <models>]
  -p, --package  : Only check for given package
  -m, --models   : Specify the model to use (default: "$MODEL"), can be a comma seperated list
  -h, --help     : Display this help message
EOF
}

# Parse command line options
OPTS=$(getopt -o p:m:h --long package:,models:,help -n 'explain-failed.sh' -- "$@")
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi

eval set -- "$OPTS"

while true; do
  case "$1" in
    -p | --package )
      package="$2"
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

test -d .mcphost || 


if [ x"$package" == "x" ] ; then
  failedPackages=`osc prjresults $PROJECT -s F -b -r standard | awk '{print $1}' `
else
  IFS=',' read -ra failedPackages <<< "$package"
fi

IFS=',' read -ra MODELS <<< "$MODEL"

for pkg in ${failedPackages[@]}; do 
	for model in "${MODELS[@]}"; do
	  echo
		echo "Checking package: $pkg with model $model"
		starttime=`date +%s`
		logfile=${id}/${pkg}_${model}.md
		$MCPHOST -m "$model" --quiet --compact=true --stream=false script explain-mcphost --args:PKG $pkg --args:PROJECT $PROJECT --args:REPO $REPO | tee $logfile
		cat tools.in >> $logfile && rm tools.in
		mv tools.out ${logfile}.tools
		endtime=`date +%s`
		test -e ${logfile} && echo -e "\nRun for $(( $endtime - $starttime )) s" >> ${logfile}
		sleep 10
	done
done
