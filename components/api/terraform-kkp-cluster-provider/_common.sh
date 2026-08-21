
### environment variables managed in source ./.kkp-env file

### check cluster ID set
checkClusterIDSet() {
  script_name=$1
  cluster_id=$2
    if [ -z $cluster_id ] || [ "${cluster_id}" == "--help" ]; then
    echo "Usage: $script_name <cluster_id>"
    echo "   OR  CLUSTER_ID=xxxx $script_name"
    echo ""
    echo "-------------- CLUSTERS in project: ${KKP_PROJECT} ------------------"
    getRequest "/projects/${KKP_PROJECT}/clusters" | jq
    exit 1
  fi
}

##### Some Request Wrapper
getRequest(){
  api_path=${1}
  if [ "$#" -lt 1 ]; then
    echo "Usage: getRequest API_PATH"
    echo "e.g.: getRequest /projects"
    exit 0
  fi
  curl -k -X GET \
      "${KKP_API}${api_path}" \
    -H  "accept: application/json" \
    -H  "Content-Type: application/json" \
    -H  "authorization: Bearer ${KKP_TOKEN}"
}

postRequest(){
  api_path=${1}
  payload_file_path=${2}
  if [ "$#" -lt 2 ]; then
    echo "Usage: postRequest API_PATH PAYLOAD_FILE_PATH"
    echo "e.g.: postRequest /projects/PROJECT_ID/clusters path/cluster.json"
    exit 0
  fi
  curl -k -X POST \
      "${KKP_API}${api_path}" \
    -H  "accept: application/json" \
    -H  "Content-Type: application/json" \
    -H  "authorization: Bearer ${KKP_TOKEN}" \
    -d  @"${payload_file_path}"
}

postRequestRaw(){
  api_path=${1}
  payload_string=${2}
  if [ "$#" -lt 2 ]; then
    echo "Usage: postRequest API_PATH PAYLOAD_STRING"
    echo "e.g.: postRequest /projects/PROJECT_ID/clusters '{count: 1}'"
    exit 0
  fi
  curl -k -X POST \
      "${KKP_API}${api_path}" \
    -H  "accept: application/json" \
    -H  "Content-Type: application/json" \
    -H  "authorization: Bearer ${KKP_TOKEN}" \
    -d  "${payload_string}"
}

patchRequest(){
  api_path=${1}
  payload_file_path=${2}
  if [ "$#" -lt 2 ]; then
    echo "Usage: patchRequest API_PATH PAYLOAD_FILE_PATH"
    echo "e.g.: patchRequest /projects/PROJECT_ID/clusters path/cluster.json"
    exit 0
  fi
  curl -k -X PATCH \
      "${KKP_API}${api_path}" \
    -H  "accept: application/json" \
    -H  "Content-Type: application/json" \
    -H  "authorization: Bearer ${KKP_TOKEN}" \
    -d  @"${payload_file_path}"
}

deleteRequest(){
  api_path=${1}
  if [ "$#" -lt 1 ]; then
    echo "Usage: deleteRequest API_PATH"
    echo "e.g.: deleteRequest /projects"
    exit 0
  fi
  curl -k -X DELETE \
      "${KKP_API}${api_path}" \
    -H  "accept: application/json" \
    -H  "Content-Type: application/json" \
    -H  "authorization: Bearer ${KKP_TOKEN}"
}

checkKKPVersion() {
  if KKP_API=${KKP_API/v2/v1} getRequest "/version" | jq .api | grep -v 2.20 | grep -v 2.1; then
    echo "KKP version supported!"
  else
    KKP_API=${KKP_API/v2/v1} getRequest "/version"
    echo "KKP version not supported!"
    return 1
  fi
}

export HEALTH_STATUS_KEY="HealthStatusUp"
######### Check cluster is healthy & reachable
checkClusterHealth() {
  cluster_id=${1}
  ### check cluster health
  getRequest "/projects/${KKP_PROJECT}/clusters/${cluster_id}/health" \
      | jq .apiserver | grep -v ${HEALTH_STATUS_KEY} \
      && echo "cluster apiserver not healthy" && return 1
  getRequest "/projects/${KKP_PROJECT}/clusters/${cluster_id}/health" \
      | jq .machineController | grep -v ${HEALTH_STATUS_KEY} \
      && echo "cluster machine controller not healthy" && return 1
  getRequest "/projects/${KKP_PROJECT}/clusters/${cluster_id}/health" \
        | jq .operatingSystemManager | grep -v ${HEALTH_STATUS_KEY} \
        && echo "cluster machine controller not healthy" && return 1
  ### check status code as well
  local code=200
  local status=$(curl -k -X GET \
     --head --location --connect-timeout 5 --write-out %{http_code} --silent --output /dev/null \
     "${KKP_API}/projects/${KKP_PROJECT}/clusters/${cluster_id}/health" \
     -H  "accept: application/json" \
     -H  "Content-Type: application/json" \
     -H  "authorization: Bearer ${KKP_TOKEN}")
  [[ $status == ${code} ]] || [[ $status == 000 ]]
}

waitForClusterHealth() {
  if checkKKPVersion; then
    cluster_id=${1}
    while ! checkClusterHealth ${cluster_id}
    do
      getRequest "/projects/${KKP_PROJECT}/clusters/${cluster_id}/health" \
       | jq
      echo ".... wait for healthy cluster" && sleep 5
    done
    echo "Cluster $cluster_id healthy!"
  else return 1; fi
}

function check_continue() {
    echo ""
    read -p "$1 ([y]es or [N]o): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        y|yes) echo "yes" && return 0;;
        *)     echo "no" && return 1;;
    esac
}