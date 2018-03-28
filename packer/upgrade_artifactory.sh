echo foo > /tmp/foo.txt

LogFile="upgrade_artifactory.log"
if [ ! -d "$LogFile" ]
then
touch "$LogFile"
fi

Log="/opt/$LogFile"
date >> "$Log" 2>&1

existing_version=5.4.6
new_version=5.5.1

proxy_set(){
echo "Setting Proxies"  >> "$Log" 2>&1
export HTTP_PROXY=http://uknp-obproxy.avivaaws.com:80 >> "$Log" 2>&1
export HTTPS_PROXY=http://uknp-obproxy.avivaaws.com:80 >> "$Log" 2>&1
echo "Proxies Set"  >> "$Log" 2>&1
}

upgrade_artifactory(){
service artifactory stop >> "$Log" 2>&1
sleep 10
service artifactory status
	if [ $? != 0 ];then
        echo "Artifactory is not up and running"  >> "$Log" 2>&1

        #Downloads the artifact artifactory pro version from Nexus
		#wget http://nxs-pp.avivaaws.com/nexus/service/local/repositories/windows-installers/content/com/jfrog/artifactory-pro/$new_version/artifactory-pro-$new_version.zip -P /opt >> "$Log" 2>&1
		
		/usr/bin/aws s3 --region eu-west-1 cp "s3://aviva-client-workload1-nonprod-technical-services-tools/artifactory/jfrog-artifactory-pro-$new_version.zip" "/opt/jfrog-artifactory-pro-$new_version.zip"

            if [ $? = 0 ];then
				
				unzip /opt/jfrog-artifactory-pro-$new_version.zip -d /opt >> "$Log" 2>&1
				
				sed -i 's/Connector port="8081"/Connector port="8080"/g' /opt/artifactory-pro-$new_version/tomcat/conf/server.xml >> "$Log" 2>&1
				
				mkdir -p /opt/artifactory_backup_files
				
				cp /opt/artifactory-pro-$existing_version/bin/artifactory.default /opt/artifactory_backup_files >> "$Log" 2>&1
				cp /opt/artifactory-pro-$existing_version/tomcat/conf/server.xml /opt/artifactory_backup_files >> "$Log" 2>&1
				cp /opt/artifactory-pro-$existing_version/tomcat/lib/postgresql-42.0.0.jre6.jar /opt/artifactory_backup_files >> "$Log" 2>&1
				
				rm -rf /opt/artifactory-pro-$existing_version/webapps/access.war >> "$Log" 2>&1
				rm -rf /opt/artifactory-pro-$existing_version/webapps/artifactory.war >> "$Log" 2>&1
				rm -rf /opt/artifactory-pro-$existing_version/tomcat >> "$Log" 2>&1
				rm -rf /opt/artifactory-pro-$existing_version/bin >> "$Log" 2>&1
				rm -rf /opt/artifactory-pro-$existing_version/misc >> "$Log" 2>&1
				
				cp /opt/artifactory-pro-$new_version/webapps/access.war /opt/artifactory-pro-$existing_version/webapps/ >> "$Log" 2>&1
				cp /opt/artifactory-pro-$new_version/webapps/artifactory.war /opt/artifactory-pro-$existing_version/webapps/ >> "$Log" 2>&1
				cp -R /opt/artifactory-pro-$new_version/tomcat /opt/artifactory-pro-$existing_version/ >> "$Log" 2>&1
				cp -R /opt/artifactory-pro-$new_version/bin /opt/artifactory-pro-$existing_version/ >> "$Log" 2>&1
				cp -R /opt/artifactory-pro-$new_version/misc /opt/artifactory-pro-$existing_version/ >> "$Log" 2>&1
				cp /opt/artifactory_backup_files/artifactory.default /opt/artifactory-pro-$existing_version/bin >> "$Log" 2>&1
				cp /opt/artifactory_backup_files/server.xml /opt/artifactory-pro-$existing_version/tomcat/conf/server.xml >> "$Log" 2>&1
				cp /opt/artifactory_backup_files/postgresql-42.0.0.jre6.jar /opt/artifactory-pro-$existing_version/tomcat/lib >> "$Log" 2>&1
				
				
				sh /opt/artifactory-pro-$existing_version/bin/installService.sh root
				
				service artifactory start
    		else
            	echo "artifactory download/wget failed" >> "$Log" 2>&1
    		fi
	fi
}

proxy_set
if [ $? = 0 ];then
	upgrade_artifactory $existing_version $new_version
	rm -rf /opt/jfrog-artifactory-pro-$new_version.zip >> "$Log" 2>&1
    rm -rf /opt/artifactory-pro-$new_version >> "$Log" 2>&1

fi


	
		
		