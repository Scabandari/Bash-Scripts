#!/bin/bash
#
# This script produces a directory and corresponding boiler plate
# files for a functional React component 
#

COMPONENT=""
HAS_CONTAINER=false
USE_EFFECT=false
USE_STATE=false
USE_REDUCER=false
USE_REF=false
REFERENCE=""  # "myRef:initialValue"
COMPONENT_STATE=()  # (key:value, key:value, ...)
CURRENT_FILE=""  # Will be adding text to multiple files using updateFile()

exitWithError() {
    echo "${1}" >&2
    exit 1
}

checkLastCommand() {
    if [[ "${?}" -ne 0 ]];
    then
        exitWithError "${1}"
    fi
}

tabsToString() {
  local tabs=''
  if [ ! -z "$1" ];
  then
    local num_tabs=$1
    while [ $num_tabs -gt 0 ];
    do
      let num_tabs=num_tabs-1
      tabs=${tabs}$'\t'
    done
  fi
  echo "${tabs}"
}

linesToString() {
  local new_lines=''
  if [ ! -z "$1" ];
  then
    local num_lines=$1
    while [ $num_lines -gt 0 ];
    do
      let num_lines=num_lines-1
      new_lines=${new_lines}$'\r'
    done
  fi
  echo "${new_lines}"
}

# Adding text without a newline after
updateLine() {
  # So you don't have to keep inputing the filename everytime
  sed -i "$ s/$/$1/" $CURRENT_FILE                              
}

# Adding 1 or more lines, appends new line after
# $2 is an integer for the number of tabs to indent
# $3 is an integer for the number of new lines above content
updateFile() {
  local new_lines="$(linesToString ${3})" 
  local tabs="$(tabsToString ${2})"
  echo "${new_lines}""${tabs}""$1" >> $CURRENT_FILE 
}

# I'm editing multiple files and constantly need to show what's in the current file
# I'd like the command to be as short as possible, JUST FOR DEVELOPMENT/TESTING!
show() {
  cat $CURRENT_FILE
}

importFromReact() {
  echo "import React" >> $CURRENT_FILE;   
  if $USE_STATE || $USE_REDUCER || $USE_EFFECT;
  then
    updateLine ', { '
    $USE_STATE && updateLine 'useState, '
    $USE_REDUCER && updateLine 'useReducer, '
    $USE_EFFECT && updateLine 'useEffect, '
    updateLine '}'
  fi
  updateLine " from 'react';"
}

# useState needs quotes around its argument if it's a string else must be a number
stringOrNumber() {
  re='^[0-9]+$'
  if [[ $1 =~ $re ]];  # it's a number
  then
    echo $1
  else
    echo "'"$1"'"
  fi
}

useState() {
  local KEY
  local VALUE
  for var in $COMPONENT_STATE;
  do
    KEY=${var%:*}
    VALUE=${var#*:}
    VALUE="$(stringOrNumber $VALUE)"
    local LINE="const [$KEY, set${KEY^}] = useState(${VALUE});"
    updateFile "${LINE}" 1
  done
}

useReducer() {
   local string='const [localState, dispatch] = useReducer(reducer, initialState);'
   updateFile "$string" 1
}

initializeState() {
  local string='const initialState = {};
    const reducer = (state, { type, payload }) => {
      switch (type) {
        default:
          throw new Error("Undefined type in reducer");
      }
    };'
  updateFile "$string"  0 1
}

useEffect() {
  local use_effect='useEffect(() => {
    console.log("Hi from first render");

    return function cleanUp() {
      console.log("Clean up code goes here")
    }
  }, []);'
  updateFile "$use_effect" 1 1
}

componentDeclaration() {
  local string="const ${COMPONENT} = props => {"
  updateFile "${string}" 0 1
}

returnStatement() {
  local content="return (<div>${COMPONENT}</div>);"
  updateFile "$content" 1 1
}

exportDefault() {
  local content="export default ${COMPONENT};"
  updateFile "$content" 0 1
}

closeBracket() {
  updateFile "};"
} 

componentCreate() {
  # set +x
  mkdir "${COMPONENT}" && cd "${COMPONENT}"
  touch "${COMPONENT}.js" && CURRENT_FILE="${COMPONENT}.js"
  checkLastCommand "Error while creating component file"
  > $CURRENT_FILE;  # Empty file if already exists
  importFromReact
  $USE_REDUCER && initializeState
  componentDeclaration 
  $USE_STATE && useState
  $USE_REDUCER && useReducer 
  $USE_EFFECT && useEffect
  returnStatement
  closeBracket 
  exportDefault
  # set -x
}

# Pass the component name as $1 and get back name of container
getContainer() {
  echo "${1}"'Container'
}

containerCreate() {
  local container="$(getContainer $COMPONENT)"
  touch "${container}.js" && CURRENT_FILE="${container}.js" && > $CURRENT_FILE 
  checkLastCommand "Error while trying to create container file"
  local string="import React, { useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import axios from 'axios';

import ${COMPONENT} from './${COMPONENT}';

const ${container} = () => {
  const myState = useSelector(
    state => state.myReducer.reduxState
  );
  const dispatch = useDispatch();

  useEffect(() => {
    const fetchData = async () => {
      const response = await axios.get();
      // ... use response
    };
    fetchData();
  }, []);

  return <${COMPONENT} />;
};

export default ${container};"
  updateFile "${string}"
}

findDirectory() {
  cd src/components
  checkLastCommand "Failed to find /src/components. Are you running this script from the project root directory?"
}

indexFileCreate() {
  touch "index.js" && CURRENT_FILE="index.js" && > $CURRENT_FILE
  checkLastCommand "Error while creating the index.js file"
  local container="$(getContainer $COMPONENT)"
  local file_name
  local string
  if $1;
  then
    file_name="$container"
  else
    file_name="$COMPONENT"
  fi
  string="import ${file_name} from './${file_name}'

export default ${file_name};" 
  updateFile "${string}"
}

while getopts "es:n:rdc" OPTION;
do 
  case $OPTION in 
    s)
      COMPONENT_STATE+=("$OPTARG")
      USE_STATE=true
      ;;
    n)
      COMPONENT="${OPTARG}"
      ;;
    e)
      USE_EFFECT=true
      ;;
    r)
      USE_REF=true  # TODO
      ;;
    d)
      USE_REDUCER=true
      ;;
    c)
      HAS_CONTAINER=true
      ;;
    ?)
      echo 'Invalid option.' >&2
      exit 1
      ;;
  esac
done

findDirectory
componentCreate
${HAS_CONTAINER} && containerCreate
indexFileCreate ${HAS_CONTAINER}




 
