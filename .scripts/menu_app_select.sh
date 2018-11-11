#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

menu_app_select() {
    local APPLIST
    APPLIST=()

    while IFS= read -r line; do
        local APPNAME
        APPNAME=${line/_ENABLED=*/}
        local FILENAME
        FILENAME=${APPNAME,,}
        local APPSUPPORTED
        APPSUPPORTED=false
        local APPNICENAME
        local APPDESCRIPTIOM
        if [[ -d ${SCRIPTPATH}/compose/.apps/${FILENAME}/ ]]; then
            if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml ]]; then
                APPNICENAME=$(grep '^#/APPNICENAME=' "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml" | cut -c15- || echo "${APPNAME}")
                APPDESCRIPTION=$(grep '^#/APPDESCRIPTION=' "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml" | cut -c18- || echo "! Missing description !")
                if [[ ${ARCH} == "aarch64" ]]; then
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.arm64.yml ]]; then
                        APPSUPPORTED=true
                    elif [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.armhf.yml ]]; then
                        APPSUPPORTED=true
                    fi
                fi
                if [[ ${ARCH} == "armv7l" ]]; then
                    if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.armhf.yml ]]; then
                        APPSUPPORTED=true
                    fi
                fi
                if [[ ${ARCH} == "x86_64" ]]; then
                    APPSUPPORTED=true
                fi
            fi
        fi
        if [[ ${APPSUPPORTED} == true ]]; then
            local APPONOFF
            if [[ $(run_script 'env_get' "${APPNAME}_ENABLED") == true ]]; then
                APPONOFF="on"
            else
                APPONOFF="off"
            fi
            APPLIST+=("${APPNICENAME}" "${APPDESCRIPTION}" "${APPONOFF}")
        fi
    done < <(grep '_ENABLED=' < "${SCRIPTPATH}/compose/.env")

    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        SELECTEDAPPS=$(whiptail --fb --clear --title "DockSTARTer" --separate-output --checklist "Choose which apps you would like to install:\\n Use [up], [down], and [space] to select apps, and [tab] to switch to the buttons at the bottom." 0 0 0 "${APPLIST[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
        if [[ ${SELECTEDAPPS} == "Cancel" ]]; then
            return 1
        else
            info "Disabling all apps."
            while IFS= read -r line; do
                local APPNAME
                APPNAME=${line/_ENABLED=true/}
                run_script 'env_set' "${APPNAME}_ENABLED" false
            done < <(grep '_ENABLED=true' < "${SCRIPTPATH}/compose/.env")
            info "Enabling selected apps."
            while IFS= read -r line; do
                local APPNAME
                APPNAME=${line^^}
                run_script 'env_set' "${APPNAME}_ENABLED" true
            done < <(echo "${SELECTEDAPPS}")
        fi
    fi
}
