#Download changeset funtion
download_changeset(){

cd ${CHANGESET}

ftp -n -v $HOST << EOL
user $USER $PASSWD
ascii
cd "Release Area/SYTReleaseArea/"
get ChangeSet.txt
bye
EOL

# Creating config file list
grep -w "CommonFiles/config" ChangeSet.txt | sed "s.CommonFiles/..g" > configlist.txt
grep -w "lib" ChangeSet.txt | grep -vw "CommonFiles" > lib_files.txt
grep -w "images" ChangeSet.txt | grep -vw "jar" > images_files.txt
}

#Function to deploy config files
deploy_config_files () {

if [ -d ${IRES_HOME}/${dir} ]; then
cd ${IRES_HOME}/${dir}

ftp -n -v $HOST << EOL
user $USER $PASSWD
binary
cd "${FTP_HOME}/${release}/Server Files/${dir}"
get ${file}
EOL

chmod 777 ${file}

echo ""
echo "${line}"
echo ""

fi
}

#Server shutdown funtion
shutdown(){
	PID1=`ps -ef | grep ${JAVA} | grep ${NODE1} | awk '{ print $2 }'`
	PID2=`ps -ef | grep ${JAVA} | grep ${NODE2} | awk '{ print $2 }'`
	if [ ! -z "$PID1" ]; then
		kill -9 $PID1
		echo ""
		echo "${NODE1} IS DOWN"
		echo ""
		cd ${DOMAIN}/servers
		rm -r ${CACHE_FOLDER1}
		
	else
		echo ""
		echo "${NODE1} IS ALREADY DOWN"
		echo ""
	fi
	
	if [ ! -z "$PID2" ]; then
		kill -9 $PID2
		echo ""
		echo "${NODE2} IS DOWN"
		echo ""
		cd ${DOMAIN}/servers
		rm -r ${CACHE_FOLDER2}
		
	else
		echo ""
		echo "${NODE2} IS ALREADY DOWN"
		echo ""
	fi
	
	ssh ${MACHINE3_IP} /data/iflyres/4.0_XQ_FunctionalCluster_Server/shell_scripts/shutdown.sh
	
	ssh ${MACHINE4_IP} /data/iflyres/4.0_XQ_FunctionalCluster_Server/shell_scripts/shutdown.sh
	
	ssh ${MACHINE5_IP} /data/iflyres/4.0_XQ_FunctionalCluster_Server/shell_scripts/shutdown.sh
}

#Server restart funtion
restart() {
	cd ${IRES_HOME}/Domain_3.8BV/server_startup/managedservers
	nohup ./startManagedWebLogic1.sh > stdout.log 2> stderr.log &
	echo ""
	echo "SERVER RESTARTED"
	echo ""
}

#Funtion to deploy iRes_App.ear and download folder 
deploy() {

#echo "Enter the release label to be deployed:"
#read release

download_changeset

#Keeping backup of important config files
cp ${IRES_HOME}/config/global/availability/availability_cache_config.xml ${IRES_HOME}/backup
cp ${IRES_HOME}/config/global/booking/app-params.xml ${IRES_HOME}/backup
cp ${IRES_HOME}/config/global/booking/charter-mail-config.xml ${IRES_HOME}/backup
cp ${IRES_HOME}/config/global/booking/itinerary/templates.xml ${IRES_HOME}/backup
cp ${IRES_HOME}/config/global/common/webEncrypterCertificates.xml ${IRES_HOME}/backup
cp ${IRES_HOME}/config/global/messageswitch/codeset-mapper.xml ${IRES_HOME}/backup
cp ${IRES_HOME}/config/global/messageswitch/ftpservices.xml ${IRES_HOME}/backup
cp ${IRES_HOME}/config/global/messageswitch/edifact-message-config.xml ${IRES_HOME}/backup
cp ${IRES_HOME}/config/global/messageswitch/edifact-routing-config.xml ${IRES_HOME}/backup
cp ${IRES_HOME}/config/global/messageswitch/xml-message-config.xml ${IRES_HOME}/backup
cp ${IRES_HOME}/config/global/messageswitch/xml-routing-config.xml ${IRES_HOME}/backup
cp ${IRES_HOME}/config/global/ticketing/error_code_mapper.xml ${IRES_HOME}/backup
cp ${IRES_HOME}/config/global/webservice/webuser.properties ${IRES_HOME}/backup
cp -r ${IRES_HOME}/config/local ${IRES_HOME}/backup

#Copying applicationversion.xml and environment.properties
cd ${IRES_HOME}/config/global/common
ftp -n -v $HOST << EOL
	user $USER $PASSWD
	ascii
	cd "${FTP_HOME}/${release}/Server Files/config/global/common"
	mget applicationversion.xml environment.properties
	bye
EOL

echo ""
echo "applicationversion.xml"
echo "environment.properties"
echo ""

while read line; do
file=`basename "$line"`
dir=`dirname "$line"`

#Copying and replacing airline entry of edifact-message-config.xml, edifact-routing-config.xml, xml-message-config.xml, xml-routing-config.xml, hosttohostconfig.xml, codeset-mapper.xml, whycode-mapper.xml, mq-server-details.xml, smsgatewayconfig.xml, ftpservices.xml, keyconfig.xml, ws-message-config.xml, castor.xml, entity-template-mapping.xml, webEncrypterCertificates.xml
if [ "$line" = "config/global/messageswitch/edifact-message-config.xml" ] || [ "$line" = "config/global/messageswitch/edifact-routing-config.xml" ] || [ "$line" = "config/global/messageswitch/xml-message-config.xml" ] || [ "$line" = "config/global/messageswitch/xml-routing-config.xml" ] || [ "$line" = "config/global/messageswitch/codeset-mapper.xml" ] || [ "$line" = "config/global/messageswitch/whycode-mapper.xml" ] || [ "$line" = "config/global/messageswitch/smsgatewayconfig.xml" ] || [ "$line" = "config/global/messageswitch/ftpservices.xml" ] || [ "$line" = "config/global/common/keyconfig.xml" ] || [ "$line" = "config/global/messageswitch/webservice/ws-message-config.xml" ] || [ "$line" = "config/global/xml/impls/castor/castor.xml" ] || [ "$line" = "config/global/dcs/velocity/entity-template-mapping.xml" ] || [ "$line" = "config/global/common/webEncrypterCertificates.xml" ];then

	if [ ! -d ${IRES_HOME}/${dir} ]; then
		mkdir -p ${IRES_HOME}/${dir}
	fi

cd ${CHANGESET}

ftp -n -v $HOST << EOL
user $USER $PASSWD
binary
cd "${FTP_HOME}/${release}/Server Files/${dir}"
get "${file}"
EOL

(cat ${CHANGESET}/${file}; echo) | sed "s/V1/${CLIENT}/g" > ${IRES_HOME}/${dir}/${file}
rm ${CHANGESET}/${file}
chmod 777 ${IRES_HOME}/${dir}/${file}
echo ""
echo "${file}"
echo ""

elif [ "$line" = "config/local/messageswitch/hosttohostconfig.xml" ] || [ "$line" = "config/local/messageswitch/mq/mq-server-details.xml" ];then

	if [ "$line" = "config/local/messageswitch/hosttohostconfig.xml" ];then
		cd ${CHANGESET}

		ftp -n -v $HOST << EOL
		user $USER $PASSWD
		binary
		cd "${FTP_HOME}/${release}/Server Files/${dir}"
		get "${file}"
EOL

		(cat ${CHANGESET}/${file}; echo) | sed "s/V1/${CLIENT}/g" > ${IRES_HOME}/config/local/${MACHINE1}/messageswitch/${file}
		rm ${CHANGESET}/${file}

		chmod 777 ${IRES_HOME}/config/local/${MACHINE1}/messageswitch/${file}

		cp ${IRES_HOME}/config/local/${MACHINE1}/messageswitch/${file} ${IRES_HOME}/config/local/${MACHINE2}/messageswitch
		cp ${IRES_HOME}/config/local/${MACHINE1}/messageswitch/${file} ${IRES_HOME}/config/local/${MACHINE3}/messageswitch
		cp ${IRES_HOME}/config/local/${MACHINE1}/messageswitch/${file} ${IRES_HOME}/config/local/${MACHINE4}/messageswitch
		cp ${IRES_HOME}/config/local/${MACHINE1}/messageswitch/${file} ${IRES_HOME}/config/local/${MACHINE5}/messageswitch
		echo ""
		echo "${file}"
		echo ""

	elif [ "$line" = "config/local/messageswitch/mq/mq-server-details.xml" ];then
		mkdir -p ${IRES_HOME}/config/local/${MACHINE1}/messageswitch/mq
		cd ${CHANGESET}
	
		ftp -n -v $HOST << EOL
		user $USER $PASSWD
		binary
		cd "${FTP_HOME}/${release}/Server Files/${dir}"
		get "${file}"
EOL

		(cat ${CHANGESET}/${file}; echo) | sed "s/V1/${CLIENT}/g" > ${IRES_HOME}/config/local/${MACHINE1}/messageswitch/mq/${file}
		rm ${CHANGESET}/${file}
	
		chmod 777 ${IRES_HOME}/config/local/${MACHINE1}/messageswitch/mq/${file}
	
		cp ${IRES_HOME}/config/local/${MACHINE1}/messageswitch/mq/${file} ${IRES_HOME}/config/local/${MACHINE2}/messageswitch/mq
		cp ${IRES_HOME}/config/local/${MACHINE1}/messageswitch/mq/${file} ${IRES_HOME}/config/local/${MACHINE3}/messageswitch/mq
		cp ${IRES_HOME}/config/local/${MACHINE1}/messageswitch/mq/${file} ${IRES_HOME}/config/local/${MACHINE4}/messageswitch/mq
		cp ${IRES_HOME}/config/local/${MACHINE1}/messageswitch/mq/${file} ${IRES_HOME}/config/local/${MACHINE5}/messageswitch/mq
		echo ""
		echo "${file}"
		echo ""

	fi

elif [ -d ${IRES_HOME}/${dir} ];then
	deploy_config_files

elif [ -f ${IRES_HOME}/config/local/${MACHINE1}/common/${file} ]; then
	if [ "${file}" != "environment.properties" ] && [ "${file}" != "logger.xml" ] && [ "${file}" != "managed_servers.xml" ] && [ "${file}" != "serverproperties.xml" ]; then
		cd ${IRES_HOME}/config/local/${MACHINE1}/common
		ftp -n -v $HOST << EOL
		user $USER $PASSWD
		binary
		cd "${FTP_HOME}/${release}/Server Files/${dir}"
		get ${file}
EOL
	
		chmod 777 ${file}

		cp ${file} ${IRES_HOME}/config/local/${MACHINE2}/common
		cp ${file} ${IRES_HOME}/config/local/${MACHINE3}/common
		cp ${file} ${IRES_HOME}/config/local/${MACHINE4}/common
		cp ${file} ${IRES_HOME}/config/local/${MACHINE5}/common

		echo ""
		echo "${file}"
		echo ""
	fi 
	
elif [ -f ${IRES_HOME}/config/local/${MACHINE1}/messageswitch/${file} ]; then 
	cd ${IRES_HOME}/config/local/${MACHINE1}/messageswitch
	ftp -n -v $HOST << EOL
	user $USER $PASSWD
	binary
	cd "${FTP_HOME}/${release}/Server Files/${dir}"
	get ${file}
EOL
	
	chmod 777 ${file}

	cp ${file} ${IRES_HOME}/config/local/${MACHINE2}/messageswitch
	cp ${file} ${IRES_HOME}/config/local/${MACHINE3}/messageswitch
	cp ${file} ${IRES_HOME}/config/local/${MACHINE4}/messageswitch
	cp ${file} ${IRES_HOME}/config/local/${MACHINE5}/messageswitch

	echo ""
	echo "${file}"
	echo ""	
	
#Copying new config files if any	
elif [ ! -d ${IRES_HOME}/${dir} ]; then

	mkdir -p ${IRES_HOME}/${dir}
	cd ${IRES_HOME}/${dir}
	
	ftp -n -v $HOST << EOL
	user $USER $PASSWD
	binary
	cd "${FTP_HOME}/${release}/Server Files/${dir}"
	get ${file}
EOL

	chmod 777 ${file}

	echo ""
	echo "${file}"
	echo ""
fi

done < ${CHANGESET}/configlist.txt

#Replacing cluster related entries in localenvironment.properties
grep "localenvironment.properties" ${CHANGESET}/ChangeSet.txt 

if [ $? -eq 0 ];then
cd ${CHANGESET}
ftp -n -v $HOST << EOL
user $USER $PASSWD
binary
cd "${FTP_HOME}/${release}/Server Files/config/local/common"
get localenvironment.properties
EOL

echo ""
echo "localenvironment.properties"
echo ""

(cat ${CHANGESET}/localenvironment.properties; echo) | sed "s/environment=Staging/environment=${MACHINE1}/g; s/clusterMode=No/clusterMode=Yes/g" >  ${IRES_HOME}/config/local/${MACHINE1}/common/localenvironment.properties
(cat ${CHANGESET}/localenvironment.properties; echo) | sed "s/environment=Staging/environment=${MACHINE2}/g; s/clusterMode=No/clusterMode=Yes/g" >  ${IRES_HOME}/config/local/${MACHINE2}/common/localenvironment.properties
(cat ${CHANGESET}/localenvironment.properties; echo) | sed "s/environment=Staging/environment=${MACHINE3}/g; s/clusterMode=No/clusterMode=Yes/g" >  ${IRES_HOME}/config/local/${MACHINE3}/common/localenvironment.properties
(cat ${CHANGESET}/localenvironment.properties; echo) | sed "s/environment=Staging/environment=${MACHINE4}/g; s/clusterMode=No/clusterMode=Yes/g" >  ${IRES_HOME}/config/local/${MACHINE4}/common/localenvironment.properties
(cat ${CHANGESET}/localenvironment.properties; echo) | sed "s/environment=Staging/environment=${MACHINE5}/g; s/clusterMode=No/clusterMode=Yes/g" >  ${IRES_HOME}/config/local/${MACHINE5}/common/localenvironment.properties

rm ${CHANGESET}/localenvironment.properties
fi

#Copying lib files if any
while read line; do
file=`basename "$line"`
dir=`dirname "$line"`

cd ${IRES_HOME}/lib
	
ftp -n -v $HOST << EOT
user $USER $PASSWD
binary
cd "${FTP_HOME}/${release}/Server Files/lib"
get ${file}
EOT
echo ""
echo "${file}"
echo ""
done < ${CHANGESET}/lib_files.txt

#Copying images files if any
while read line; do
file=`basename "$line"`
dir=`dirname "$line"`

if [ -d ${IRES_HOME}/${dir} ]; then

cd ${IRES_HOME}/${dir}
	
ftp -n -v $HOST << EOL
user $USER $PASSWD
binary
cd "${FTP_HOME}/${release}/Server Files/${dir}"
get ${file}
EOL
echo ""
echo "${file}"
echo ""

elif [ ! -d ${IRES_HOME}/${dir} ]; then

mkdir -p ${IRES_HOME}/${dir}
cd ${IRES_HOME}/${dir}

ftp -n -v $HOST << EOL
user $USER $PASSWD
binary
cd "${FTP_HOME}/${release}/Server Files/${dir}"
get ${file}
EOL
echo ""
echo "${file}"
echo ""

fi

done < ${CHANGESET}/images_files.txt

#Copying startup_jar files if framework is present in changeset
grep "framework" ${CHANGESET}/ChangeSet.txt 

if [ $? -eq 0 ];then
cd ${IRES_HOME}/startup_jar
ftp -n -v $HOST << EOL
user $USER $PASSWD
binary
cd "${FTP_HOME}/${release}/Server Files/startup_jar"
mget *.*
EOL
cp ${IRES_HOME}/startup_jar/*.* ${WEBLOGIC}

scp ${IRES_HOME}/startup_jar/*.* ${MACHINE3_IP}:${WEBLOGIC}
scp ${IRES_HOME}/startup_jar/*.* ${MACHINE4_IP}:${WEBLOGIC}
scp ${IRES_HOME}/startup_jar/*.* ${MACHINE5_IP}:${WEBLOGIC}

echo ""
echo "FRAMEWORK"
echo ""
fi

#Copying resources/reports files if "resources/reports" is present in changeset
grep "resources/reports" ${CHANGESET}/ChangeSet.txt

if [ $? -eq 0 ];then
cd ${IRES_HOME}/resources/reports
ftp -n -v $HOST << EOL
user $USER $PASSWD
binary
cd "${FTP_HOME}/${release}/Server Files/resources/reports"
mget *.*
EOL
echo ""
echo "RESOURCES/REPORTS"
echo ""
fi

#Copying iRes_App.ear file
cd ${DEPLOYABLE}
ftp -n -v $HOST << EOL
user $USER $PASSWD
binary
cd "${FTP_HOME}/${release}/Server Files/deployable"
get iRes_App.ear
EOL
echo ""
echo "iRes_App.ear"
echo ""

#Copying files in download folder
cd ${DEPLOYABLE}/download/jars
ftp -n -v $HOST << EOL
user $USER $PASSWD
binary
cd "${FTP_HOME}/${release}/Server Files/deployable/${DOWNLOAD_CLT}/jars"
mget *.xml *.dll *.properties *.jar *.exe *.config *.pec *.txt *.wav *.cer *.tpl *.ttf *.manifest *.prn
EOL
echo ""
echo "DOWNLOAD/JARS"
echo ""

cd ${DEPLOYABLE}/download/WEB-INF
ftp -n -v $HOST << EOL
user $USER $PASSWD
binary
cd "${FTP_HOME}/${release}/Server Files/deployable/${DOWNLOAD_CLT}/WEB-INF"
mget *.*
EOL
}

shutdown
deploy