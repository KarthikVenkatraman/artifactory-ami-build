#!/bin/bash

artifactory_version="5.5.1"
Log="/opt/artifactory-pro-$artifactory_version/etc/replacecontext.log"
touch $Log

configure_context()
{
	echo "Configure context function started...." >> "$Log" 2>1&
	host=`hostname -I` 
	echo $host
	trimmed=`echo $host` 
	echo \'$trimmed\'
	trimmed_ip=$trimmed 
	echo $trimmed_ip
	sed -i 's/context.url=/context.url=http:\/\/'$trimmed':8080\/artifactory/g' /opt/artifactory-pro-$artifactory_version/etc/ha-node.properties
	sed -i 's/node.id=/node.id=artifactory_'$trimmed'/g' /opt/artifactory-pro-$artifactory_version/etc/ha-node.properties
	sed -i 's/primary=/primary=true/g' /opt/artifactory-pro-$artifactory_version/etc/ha-node.properties
	
	echo "Hostname replaced...." >> "$Log" 2>1&
	rm -rf /opt/artifactory-pro-$artifactory_version/etc/security >> "$Log" 2>1& 
    rm -rf /opt/artifactory-pro-$artifactory_version/access >> "$Log" 2>1& 
	rm -rf /opt/artifactory-pro-$artifactory_version/etc/security.*.xml >> "$Log" 2>1&
	rm -rf /opt/artifactory-pro-$artifactory_version/etc/replace_context_member.sh >> "$Log" 2>1&

    echo "export JAVA_OPTIONS=-Djfrog.access.force.replace.existing.root.keys=true" >> /opt/artifactory-pro-$artifactory_version/etc/default

	echo "Starting Artifactory application...." >> "$Log" 2>1&
	systemctl enable artifactory.service
	service artifactory start
	sleep 40
	echo "Configure context function complete...." >> "$Log" 2>1&
}

create_bootstrap()
{
	echo "Create bootstrap bundle function started...." >> "$Log" 2>1&
	service artifactory status >> "$Log" 2>1&
	if [ $? = 0 ];then
		curl -X POST http://127.0.0.1:8080/artifactory/api/system/bootstrap_bundle -H 'authorization: Basic YWRtaW46cGFzc3dvcmQ=' -H 'cache-control: no-cache' -H 'content-type: application/json' -H 'postman-token: 751491c4-4c4e-3e4d-fdc5-00515d6ee6e4' -d '{ "file" : "/opt/artifactory-pro-$artifactory_version/etc/bootstrap.bundle.tar.gz" }'
	fi
	echo "Create bootstrap function complete...." >> "$Log" 2>1&	
}

upload_bootstrap_to_s3()
{
	echo "Upload bootstrap bundle to S3 function started...." >> "$Log" 2>1&
	chmod +x /opt/artifactory-pro-$artifactory_version/etc/bootstrap.bundle.tar.gz

	aws s3 --region eu-west-1 cp "/opt/artifactory-pro-$artifactory_version/etc/bootstrap.bundle.tar.gz" "s3://aviva-client-workload1-nonprod-technical-services-tools/artifactory_bootstrap/bootstrap.bundle.tar.gz"
	echo "Upload bootrstarp bundle to S3 complete...." >> "$Log" 2>1&
	#mv /opt/artifactory-pro-$artifactory_version/etc/bootstrap.bundle.tar.gz /opt/artifactory-pro-$artifactory_version/etc/original_bootstrap.bundle.tar.gz
}

configure_context
	if [ $? = 0 ];then
		create_bootstrap
		if [ $? = 0 ];then
			upload_bootstrap_to_s3
		fi
	fi



