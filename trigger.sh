#!/usr/bin/env bash

#Parameters given in Jenkins
export release=$1
export stream=$2

#Server specific variables
export IRES_HOME="/data/share/4.0_Cluseter_Res_Home"
export DOMAIN="/data/iflyres/4.0_XQ_FunctionalCluster_Server/Cluster_40_Domain"
export NODE1="nodeName=MAC1_RES1"
export NODE2="nodeName=MAC1_RES2"
export JAVA=" /data/jdk1.7.75/bin/amd64/java"
export WEBLOGIC="/data/weblogic1213/Oracle_Home/wlserver/server/lib/mbeantypes"
export CLIENT='XQ'
export DOWNLOAD_CLT='download_XQ'
export SCRIPT_PATH="/data/iflyres/Jenkins_shell_scripts/Functional_Clustering"
export CACHE_FOLDER1='Res_ManagedServer_Machine_1_1'
export CACHE_FOLDER2='Res_ManagedServer_Machine_1_2'
export MACHINE1='local_MAC1_Res1'
export MACHINE2='local_MAC1_Res2'
export MACHINE3='local_MAC2_DCS1'
export MACHINE4='local_MAC3_MsgSwitch1'
export MACHINE5='local_MAC1_Rpt1'
export MACHINE3_IP="192.168.8.109"
export MACHINE4_IP="192.168.8.112"
export MACHINE5_IP="192.168.8.115"
export HOST='192.168.8.99'
export USER='anonymous'
export PASSWD='password'
export CHANGESET="${IRES_HOME}/ChangeSet"
export DEPLOYABLE="${IRES_HOME}/deployable"
export FTP_HOME="/Release Area/SYTReleaseArea/${stream}"

[[ "${#BASH_SOURCE[@]}" -gt "1" ]] && { return 0; }

#Details of the machine where deployment scripts are copied 
USERNAME='iflyres'
PASSWORD='Res@dm!n'
HST='192.168.8.118'

cd ${IRES_HOME}/shell_scripts
${IRES_HOME}/shell_scripts/shutdown.sh

ftp -n -v $HST << EOL
user $USERNAME $PASSWORD
ascii
cd "${SCRIPT_PATH}"
get deploy.sh
EOL

chmod 777 deploy.sh

${IRES_HOME}/shell_scripts/deploy.sh