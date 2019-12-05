#!/bin/sh
RESOURCE_URL="${1}"
SCAN_SERVERITY="${2}"
HARBOR_USER="admin"
AUTH=$(echo -n ${HARBOR_USER}:${HARBOR_PASS}| base64)
HARBOR_URL=$(echo "${RESOURCE_URL}" | cut -d \/ -f1)
PROJECT=$(echo "${RESOURCE_URL}" | cut -d \/ -f2)
IMAGE_TAG=$(echo "${RESOURCE_URL}" | cut -d \/ -f3)
IMAGE=$(echo ${IMAGE_TAG} | cut -d \: -f1)
TAG=$(echo ${IMAGE_TAG} | cut -d \: -f2)

gather_label_id(){
  local LABEL_NAME="${1}"
  local LABEL_ID=$(curl -Ss -X GET \
                    --connect-timeout 30 \
                    --retry 10 \
                    --retry-delay 5 \
                    "https://${HARBOR_URL}/api/labels?name=CVE%3A${LABEL_NAME}&scope=g" \
                    -H "accept: application/json" \
                    -H "authorization: Basic ${AUTH}" | \
                    grep '"id"' | \
                    grep -m1 -Eo "[0-9]{1,9}"
                  )
  echo "${LABEL_ID}"
}

save_label_id(){
  local LABEL_NAME="${1}"
  echo $(gather_label_id "${LABEL_NAME}") > "${LABEL_NAME}.id"
}

set_label(){
  local LABEL_NAME="${1}"
  if ! check_file "${LABEL_NAME}.id"
  then
    save_label_id "${LABEL_NAME}"
  fi

  local LABEL_ID="$(cat ${LABEL_NAME}.id)"

  curl \
    --write-out %{http_code} \
    --connect-timeout 30 \
    --retry 10 \
    --retry-delay 5 \
    -Ss -X POST \
    "https://${HARBOR_URL}/api/repositories/${PROJECT}%2F${IMAGE}/tags/${TAG}/labels" \
    -H "accept: application/json" \
    -H "authorization: Basic ${AUTH}" \
    -H "Content-Type: application/json" \
    -d "{  \"id\": ${LABEL_ID},  \"name\": \"CVE:${LABEL_NAME}\"}"
}

create_global_label(){
  local DESCRIPTION="${1}"
  local COLOR="${2}"
  local NAME="${3}"
  curl \
    --write-out %{http_code} \
    --connect-timeout 30 \
    --retry 10 \
    --retry-delay 5 \
    -Ss -X POST \
    "https://${HARBOR_URL}/api/labels" \
    -H "accept: application/json" \
    -H "authorization: Basic ${AUTH}" \
    -H "Content-Type: application/json" \
    -d "{  \"description\": \"${DESCRIPTION}\",
           \"color\": \"${COLOR}\",
           \"scope\": \"g\",
           \"name\": \"${NAME}\"
        }"
}

ensure_global_labels(){
  create_global_label "No known CVEs" "#48960C" "CVE:None"
  create_global_label "Unknown"       "#DDDDDD" "CVE:Unknown"
  create_global_label "Low CVE"       "#F57600" "CVE:Low"
  create_global_label "Medium CVE"    "#FF5501" "CVE:Medium"
  create_global_label "High CVE"      "#F52F52" "CVE:High"
}

file_older_than_1h(){
  local FILE_NAME="${1}"
  local SECONDS_SINCE_CHANGE=$(echo "$(date +%s) - $(stat ${FILE_NAME} -c %Y)" | bc)
  if [[ "${SECONDS_SINCE_CHANGE}" -gt 3600 ]]
  then
    true
  else
    false
  fi
}

check_file(){
  local FILE_NAME="${1}"
  if [[ -f "${FILE_NAME}" ]] && [[ ! $(file_older_than_1h "${FILE_NAME}") ]]
  then
    true
  else
    false
  fi
}

if ! check_file "FILE_global_labels.lock"
then
  ensure_global_labels
  touch FILE_global_labels.lock
fi

case "${2}" in
  1)
    set_label "None"
    ;;
  2)
    set_label "Unknown"
    ;;
  3)
    set_label "Low"
    ;;
  4)
    set_label "Medium"
    ;;
  5)
    set_label "High"
    ;;
esac
