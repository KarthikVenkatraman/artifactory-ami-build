#!/bin/bash

artifactory_version="5.5.1"
# Set Logging Options
Log="/opt/artifactory-pro-$artifactory_version/etc/replacecontext.log"
touch "$Log"
chmod +x $Log

configure_context()
{
	echo "Staring configure" >> "$Log" 2>1&
	echo "Disabling artifactory service" >> "$Log" 2>1&
	systemctl stop artifactory.service
	systemctl disable artifactory.service
	echo "replacing hostname in context" >> "$Log" 2>1&
	host=`hostname -I` 
	echo $host
	trimmed=`echo $host` 
	echo \'$trimmed\'
	trimmed_ip=$trimmed 
	echo $trimmed_ip
	sed -i 's/context.url=/context.url=http:\/\/'$trimmed':8080\/artifactory/g' /opt/artifactory-pro-$artifactory_version/etc/ha-node.properties
	sed -i 's/node.id=/node.id=artifactory_'$trimmed'/g' /opt/artifactory-pro-$artifactory_version/etc/ha-node.properties
	sed -i 's/primary=/primary=false/g' /opt/artifactory-pro-$artifactory_version/etc/ha-node.properties
	
	echo "Removing the artifactory standalone files" >> "$Log" 2>1&
	rm -rf /opt/artifactory-pro-$artifactory_version/access >> "$Log" 2>1&
	rm -rf /opt/artifactory-pro-$artifactory_version/etc/security >> "$Log" 2>1&
	rm -rf /opt/artifactory-pro-$artifactory_version/etc/security.*.xml >> "$Log" 2>1&
	rm -rf /opt/artifactory-pro-$artifactory_version/etc/db.properties >> "$Log" 2>1&
    rm -rf /opt/artifactory-pro-$artifactory_version/etc/binarystore.xml >> "$Log" 2>1&
	rm -rf /opt/artifactory-pro-$artifactory_version/etc/artifactory.cluster.license >> "$Log" 2>1&
	rm -rf /opt/artifactory-pro-$artifactory_version/etc/replace_context_primary.sh >> "$Log" 2>1&
		
    echo "export JAVA_OPTIONS=-Djfrog.access.force.replace.existing.root.keys=true" >> /opt/artifactory-pro-$artifactory_version/etc/default
	echo "Configure function complete" >> "$Log" 2>1&
}

download_package_for_s3()
{
	echo "Started Download bootstrap package from S3 function" >> "$Log" 2>1&
		
	aws s3 --region eu-west-1 cp "s3://aviva-client-workload1-nonprod-technical-services-tools/artifactory_bootstrap/bootstrap.bundle.tar.gz" "/opt/artifactory-pro-$artifactory_version/etc/"
	chmod +x /opt/artifactory-pro-$artifactory_version/etc/bootstrap.bundle.tar.gz
	echo "Started Artifactory service" >> "$Log" 2>1&
	systemctl enable artifactory.service
	service artifactory start
	echo "Download bootstrap package from S3 function complete..." >> "$Log" 2>1&
}

configure_context
download_package_for_s3