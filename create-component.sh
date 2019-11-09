#!/bin/bash

DIRECTORY=${1}
COMPONENT=${1}
COMPONENT_FILE="${1}.js"
SCSSS_FILE="${COMPONENT}.scss"
CONTAINER="${COMPONENT}Container"
CONTAINER_FILE="${CONTAINER}.js"


#echo "${DIRECTORY}"
#echo "${JS_FILE}"
#echo "${SCSSS_FILE}"

exitWithError() {
    echo "${1}" >&2
    exit 1
}

checkCommand() {
    if [[ "${?}" -ne 0 ]];
    then
        exitWithError "${1}"
    fi
}


cd src/components
checkCommand "Failed to find /src/components. Are you running this script from the project root directory?"

mkdir "${DIRECTORY}" && cd "${DIRECTORY}" && touch "${COMPONENT_FILE}" "${SCSSS_FILE}" index.js

echo "import React, { useEffect, useState } from 'react';

import './${SCSSS_FILE}';

const ${COMPONENT} = (props) => {
  //const [height, setHeight] = useState(0);

  //useEffect(() => {
  //}, []);

  return (
    <div>

    </div>
  );
};

export default ${COMPONENT};"  >> "${COMPONENT_FILE}";

if [[ "${#}" -gt 1 && "${2}" -eq -c ]]
then 
    touch "${CONTAINER_FILE}"
    echo "import ${CONTAINER} from './${CONTAINER}';

export default ${CONTAINER};" >> index.js
    echo "import React from 'react';
import { connect } from 'react-redux';

import ${COMPONENT} from './${COMPONENT}'
//import {  } from '../../actions';

const FooterContainer = (props) => {
    return (
        <${COMPONENT}  />
    );
};

// const mapStateToProps = state => {
//     return {

//     };
//   };
  
export default connect(null, null)(${CONTAINER});" >> "${CONTAINER_FILE}"
else 
    echo "import ${COMPONENT} from './${COMPONENT}';

export default ${COMPONENT};" >> index.js
fi
