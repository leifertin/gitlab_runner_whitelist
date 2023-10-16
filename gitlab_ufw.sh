#!/bin/bash

usage() {
  echo "Script to update ufw SSH list for GitLab Runners"
  echo ""
  echo "Usage: `basename $0` [options]"
  echo ""
  echo -e "## General options"
  echo ""
  echo -e "  -h, --help\t\t\tPrints this message"
  echo -e '  -d\t\t\t\tOnly DELETE old values'
  echo -e '  -c <comment>\t\t\tComment for rules (default is "GitLab Runner")'
  echo ""
  exit 0
}

# get action from cli
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  usage
fi

while getopts "dc:" option; do
  case "${option}" in
    (d) ONLY_DELETE=true;;
    (c) GITLAB_COMMENT=${OPTARG};;
  esac
done

if [ -z ${GITLAB_COMMENT+x} ]; then
  GITLAB_COMMENT="GitLab Runner"
fi

# get current rules as array
RULES=`ufw status numbered`
echo "$RULES" > temporary_current_rules_output
mapfile -t RULES < temporary_current_rules_output
rm temporary_current_rules_output

# remove filler lines
for (( i=1; i<4; i++ )); do
  RULES=("${RULES[@]:1}")
done

# reverse array
REVERSE_RULES=()
for (( i="${#RULES[@]}"; i>0; i-- )); do
  REVERSE_RULES+=("${RULES[i]}")
done
REVERSE_RULES=("${REVERSE_RULES[@]:1}")

# delete old rules
for RULE in "${REVERSE_RULES[@]}"; do  
  RULE_NUMBER=`echo "${RULE}" \
  | sed -r 's/^([^.]+).*$/\1/; s/^[^0-9]*([0-9]+).*$/\1/'`
  
  if [[ ${RULE} =~ "$GITLAB_COMMENT" ]]; then
    ufw --force delete ${RULE_NUMBER}
  fi
done

if [ -z ${ONLY_DELETE+x} ]; then
  # get google ip list
  IP_ADDRESSES=`wget -cq https://www.gstatic.com/ipranges/cloud.json -O - \
  | jq -r '.prefixes[] | select(.scope == "us-east1").ipv4Prefix'`
  IP_ADDRESSES=${IP_ADDRESSES//null/}

  # Add new rules
  while IFS='' read -ra ADDR; do
    for IP in "${ADDR[@]}"; do       
        ufw allow from ${IP} to any port 22 proto tcp comment "$GITLAB_COMMENT"
    done
  done <<< "$IP_ADDRESSES"
fi