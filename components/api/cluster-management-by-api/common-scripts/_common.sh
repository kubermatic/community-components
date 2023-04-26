
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

export HEALTH_STATUS_KEY="HealthStatusUp"
setHealthStatusKey() {
  # health API returns 1 (int) to mark apiserver & other components heathy before 
  # KKP 2.20 and HealthStatusUp (string) from KKP 2.20
  apiServerStatus=$(getRequest "/projects/${KKP_PROJECT}/clusters/${cluster_id}/health" | jq .apiserver)
  #regex to check if the value is 0 or 1
  re='^[0-1]+$'
  if [[ $apiServerStatus =~ $re ]] ; then
    export HEALTH_STATUS_KEY=1
  fi
}

######### Check cluster is healthy & reachable
checkClusterHealth() {
  cluster_id=${1}
  setHealthStatusKey
  getRequest "/projects/${KKP_PROJECT}/clusters/${cluster_id}/health" \
      | jq .[] | grep -v 1 \
      | jq .[] | grep -v ${HEALTH_STATUS_KEY} \
      && echo "cluster not healthy" && return 1
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
  cluster_id=${1}
  while ! checkClusterHealth ${cluster_id}
  do
    getRequest "/projects/${KKP_PROJECT}/clusters/${cluster_id}/health" \
     | jq
    echo ".... wait for healthy cluster" && sleep 5
  done
  echo "Cluster $cluster_id healthy!"
}

function check_continue() {
    echo ""
    read -p "$1 ([y]es or [N]o): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        y|yes) echo "yes" && return 0;;
        *)     echo "no" && return 1;;
    esac
}