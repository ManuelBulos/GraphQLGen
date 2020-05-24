#!/bin/bash
# Downloads the latest schema.json file from the GraphQL endpoint

declare -r endpoint="ENTER-YOUR-OWN-ENDPOINT"
declare -r directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $directory
echo "⬇️ Downloading schema.json file from: "$endpoint
apollo schema:download --endpoint=$endpoint schema.json

echo "⬇️ Downloading schema.graphql file from: "$endpoint
apollo client:download-schema --endpoint=$endpoint schema.graphql
