#!/bin/bash 

SCRIPT_DIR="$(readlink -f "$(dirname "$0")")"
echoerr() { echo "$@" 1>&2; }
usage() { echo "$0 <OS_STORAGE_URL> <vol-data> <BACKUP_NAME>"; }
[ "$#" -eq "3" ] || { usage; exit 1; }

# Use this only for running individual containers locally
# On cpouta use docker-compose

IMAGE_NAME="swift-backup"
CONTAINER_NAME="$IMAGE_NAME"
IP="172.30.23.66"
NETWORK="seco"
NETWORK_CIDR="172.30.20.0/22"
CONTAINER_USER="$UID"
VOLUME_SOURCE="${2:-"$SCRIPT_DIR/vol-data"}"
VOLUME_TARGET="/m"
BACKUP_NAME="$3"
OS_STORAGE_URL="$1"
echo "Enter OS_AUTH_TOKEN:" && read -r OS_AUTH_TOKEN

[ ! -z "$BACKUP_NAME" ]     || { echoerr "BACKUP_NAME not defined"; exit 1; }
[ ! -z "$OS_STORAGE_URL" ]  || { echoerr "OS_STORAGE_URL not defined"; exit 1; }
[ ! -z "$OS_AUTH_TOKEN" ]   || { echoerr "OS_AUTH_TOKEN not defined"; exit 1; }


ENV1_NAME="OS_STORAGE_URL"
ENV1_VALUE="$1"
ENV2_NAME="OS_AUTH_TOKEN"
ENV2_VALUE="$OS_AUTH_TOKEN"
ENV3_NAME="BACKUP_NAME"
ENV3_VALUE="$BACKUP_NAME"

# Convert to absolute paths
VOLUME_SOURCE="$(readlink -f "$VOLUME_SOURCE")"

# Create volume source if not exist
[ -d "$VOLUME_SOURCE" ] || mkdir -p "$VOLUME_SOURCE" || { echoerr "$VOLUME_SOURCE does not exist and cannot create it"; exit 1; }

# Create docker network if it does not exist
docker network inspect "$NETWORK" > /dev/null 2>&1 || docker network create --subnet $NETWORK_CIDR $NETWORK || { echoerr "Docker network $NETWORK does not exist and cannot create it"; exit 1; } 

#Run the container
set -x
docker run -it --rm \
	-u $CONTAINER_USER \
	--name $CONTAINER_NAME \
	--network $NETWORK \
	--ip $IP \
    --mount type=bind,source="$VOLUME_SOURCE",target="$VOLUME_TARGET" \
    -e "$ENV1_NAME=$ENV1_VALUE" \
    -e "$ENV2_NAME=$ENV2_VALUE" \
    -e "$ENV3_NAME=$ENV3_VALUE" \
	$IMAGE_NAME
{ set +x; } > /dev/null 2>&1

