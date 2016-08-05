#!/bin/bash

set -x

PROCESS_REGISTRY_URL="http://127.0.0.1:8000"
PROCESS_DISPATCHER_URL="http://127.0.0.1:8001"
MISTER_CLUSTER_URL="http://127.0.0.1:8002"
CALLBACK_URL="http://requestb.in/1mstk8z1"

echo "Testing the architecture"

function extract_token {

    RESULT=$(echo $1 | sed 's/.*"token"://g' | sed 's/,.*//g' | sed 's/"//g' | sed 's/}//g')

    echo "$RESULT"
}

function extract_id {

    RESULT=$(echo $1 | sed 's/.*"id"://g' | sed 's/,.*//g')

    echo "$RESULT"
}

########################################################
# CREATION OF PROCESS
########################################################

read -r -d '' STRING_PARAMETERS_JSON_VALUE <<- EOM
[
   "env_var",
   "parameter"
]
EOM
STRING_PARAMETERS_JSON_VALUE_ESCAPED=$(echo $STRING_PARAMETERS_JSON_VALUE | sed 's/"/\\\"/g')

read -r -d '' FILE_PARAMETERS_JSON_VALUE <<- EOM
[
   "input_file"
]
EOM
FILE_PARAMETERS_JSON_VALUE_ESCAPED=$(echo $FILE_PARAMETERS_JSON_VALUE | sed 's/"/\\\"/g')

read -r -d '' PROCESS_JSON_VALUE <<- EOM
{
    "name": "LineCounter",
    "description": "A simple line counter that can be used to demonstrate the complete architecture.",
    "string_parameters": "$STRING_PARAMETERS_JSON_VALUE_ESCAPED",
    "logo_url": "http://dropbox.jonathanpastor.fr/dibbs/linecounter.png",
    "file_parameters": "$FILE_PARAMETERS_JSON_VALUE_ESCAPED"
}
EOM

echo $PROCESS_JSON_VALUE

PROCESS_REGISTRATION_OUTPUT=$(curl -u admin:pass -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d "$PROCESS_JSON_VALUE" "$PROCESS_REGISTRY_URL/processdefs/")
PROCESS_ID=$(extract_id $PROCESS_REGISTRATION_OUTPUT)
echo $PROCESS_ID

########################################################
# CREATION OF PROCESS IMPLEMENTATION
########################################################

read -r -d '' OUTPUT_PARAMS_JSON_VALUE <<- EOM
{
   "file_path": "output.txt"
}
EOM
OUTPUT_PARAMS_JSON_VALUE_ESCAPED=$(echo $OUTPUT_PARAMS_JSON_VALUE | sed 's/"/\\\"/g')

read -r -d '' PROCESS_IMPL_JSON_VALUE <<- EOM
{
    "name": "line_counter_hadoop",
    "appliance": "hadoop",
    "process_definition": $PROCESS_ID,
    "cwd": "~",
    "script": "export ENV_VAR=!{env_var} ; curl http://dropbox.jonathanpastor.fr/archive.tgz > __archive.tar.gz ; tar -xzf __archive.tar.gz ; rm -f __archive.tar.gz ; bash run_job.sh @{input_file} !{parameter} > stdout 2> stderr",
    "output_type": "file",
    "output_parameters": "$OUTPUT_PARAMS_JSON_VALUE_ESCAPED"
}
EOM

echo $PROCESS_IMPL_JSON_VALUE

PROCESS_IMPL_REGISTRATION_OUTPUT=$(curl -u admin:pass -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d "$PROCESS_IMPL_JSON_VALUE" "$PROCESS_REGISTRY_URL/processimpls/")
PROCESS_IMPL_ID=$(extract_id $PROCESS_IMPL_REGISTRATION_OUTPUT)
echo $PROCESS_IMPL_ID

exit 0
