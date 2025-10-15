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
Usage: $0 [-p <pattern>] [-m <model>]
  -p, --pattern  : Filter failed packages by a pattern (default: "$pattern")
  -m, --model    : Specify the model to use (default: "$MODEL")
  -h, --help     : Display this help message
EOF
}

# Parse command line options
OPTS=$(getopt -o p:m:h --long pattern:,model:,help -n 'explain-failed.sh' -- "$@")
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi

eval set -- "$OPTS"

while true; do
  case "$1" in
    -p | --pattern )
      pattern="$2"
      shift 2
      ;;
    -m | --model )
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

# # connect our mcp-server
# test -e ~/.mcphost.yml || cat <<EOF
# mcpServers:
#   osc-mcp:
#     type: "remote"
#     url: "http://localhost:8666"
# EOF


failedPackages=`osc prjresults $PROJECT -s F -b -r standard | awk '/'$pattern'/ {print $1}' `


for pkg in $failedPackages; do 
	echo "Checking package: $pkg"
	logfile=${pkg}_${MODEL}_${id}.md
	starttime=`date +%s`
	$MCPHOST -m $MODEL --compact --stream=false script explain-mcphost --args:PKG $pkg --args:PROJECT $PROJECT --args:REPO $REPO --args:ALLOWED `pwd` --args:OUT ${logfile}
	endtime=`date +%s`
	test -e ${logfile} && echo -e "\nRun for $(( $endtime - $starttime )) s" >> ${logfile}
done
