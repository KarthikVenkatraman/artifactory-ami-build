echo foo > /tmp/foo.txt

LogDir="/tmp/log"
if [ ! -d "$LogDir" ]
then
mkdir "$LogDir"
fi

Log="$LogDir/clone-and-install.log"
date >> "$Log" 2>&1

echo "=====Artifactory Version======="
echo $1

install_open_jdk(){
	echo "Installing Open JDK"
	yum install -y java
}

mount_volume(){
	echo "Mounting the volumes"
	cp /etc/fstab /etc/fstab.orig >> "$Log" 2>&1

	#Creation of mount point
	mkdir -p /opt/artifactory-pro-$1 >> "$Log" 2>&1
	mkfs -t ext4 /dev/xvdk >> "$Log" 2>&1
	mount /dev/xvdk /opt/artifactory-pro-$1 >> "$Log" 2>&1
	echo "/dev/xvdk	/opt/artifactory-pro-$1	ext4	defaults,nofail	0	2" >> /etc/fstab

	mount -a >> "$Log" 2>&1
	echo "Mounted the volumes"
}

install_artifactory(){

service artifactory status  >> "$Log"
	if [ $? != 0 ];then
        echo "Artifactory is not up and running"  >> "$Log" 2>&1

		echo "=====Artifactory Version======="
		echo $1

        #Downloads the artifact artifactory pro version from Nexus
		#/usr/bin/aws s3 --region eu-west-1 cp "s3://aviva-client-workload1-nonprod-technical-services-tools/artifactory/jfrog-artifactory-pro-$1.zip" "/opt/jfrog-artifactory-pro-$1.zip"
		
		/usr/bin/aws s3 --region eu-west-1 cp "s3://aviva-tooling-nonprod-technical-services-tools/artifactory/jfrog-artifactory-pro-$1.zip" "/opt/jfrog-artifactory-pro-$1.zip"

            if [ $? = 0 ];then
				unzip /opt/jfrog-artifactory-pro-$1.zip -d /opt
				ls -l /opt
				sed -i 's/Connector port="8081"/Connector port="8080"/g' /opt/artifactory-pro-$1/tomcat/conf/server.xml >> "$Log" 2>&1
				sh /opt/artifactory-pro-$1/bin/installService.sh root
				systemctl disable artifactory.service >> "$Log" 2>1&
    		else
            	echo "artifactory download/wget failed" >> "$Log" 2>&1
    		fi
fi
}

copy_configuration_files(){

	#Downloads the artifact postgres sql from Nexus required for artifactory RDS
	echo "Downloading postgresql-42.0.0.jre6.jar"
	#/usr/bin/aws s3 --region eu-west-1 cp "s3://aviva-client-workload1-nonprod-technical-services-tools/artifactory/postgresql-42.0.0.jre6.jar" "/opt/artifactory-pro-$1/tomcat/lib/"
	
	/usr/bin/aws s3 --region eu-west-1 cp "s3://aviva-tooling-nonprod-technical-services-tools/artifactory/postgresql-42.0.0.jre6.jar" "/opt/artifactory-pro-$1/tomcat/lib/"

	chmod +x /opt/artifactory-pro-$1/tomcat/lib/postgresql-42.0.0.jre6.jar >> "$Log" 2>&1

	# Copy the configuration files from tmp location to artifactory etc location
	echo "Config files being copied artifactory version test"

	cp -f /tmp/binarystore.xml /opt/artifactory-pro-$1/etc >> "$Log" 2>&1
	cp -f /tmp/db.properties /opt/artifactory-pro-$1/etc >> "$Log" 2>&1
	cp -f /tmp/ha-node.properties /opt/artifactory-pro-$1/etc >> "$Log" 2>&1
	cp -f /tmp/artifactory.cluster.license /opt/artifactory-pro-$1/etc >> "$Log" 2>&1
	cp -f /tmp/replace_context_primary.sh /opt/artifactory-pro-$1/etc >> "$Log" 2>&1
	cp -f /tmp/replace_context_member.sh /opt/artifactory-pro-$1/etc >> "$Log" 2>&1

	echo "Config files permission being changed"
	chmod +x /opt/artifactory-pro-$1/etc/binarystore.xml >> "$Log" 2>&1
	chmod +x /opt/artifactory-pro-$1/etc/db.properties >> "$Log" 2>&1
	chmod +x /opt/artifactory-pro-$1/etc/ha-node.properties >> "$Log" 2>&1
	chmod +x /opt/artifactory-pro-$1/etc/artifactory.cluster.license >> "$Log" 2>&1
	chmod +x /opt/artifactory-pro-$1/etc/replace_context_primary.sh >> "$Log" 2>&1
	chmod +x /opt/artifactory-pro-$1/etc/replace_context_member.sh >> "$Log" 2>&1

	ls -l /opt/artifactory-pro-$1/etc
	ls -l /etc/opt/jfrog/artifactory
	ls -l /opt/artifactory-pro-$1/tomcat/lib/
	echo "Config files function complete"
}

open_firewall(){
	echo "Function IP Tables called"
	firewall-cmd --zone=public --add-port=8080/tcp --permanent
	firewall-cmd --reload
	iptables-save | grep 8080
	echo "Done with IP Tables"
	echo "Done with IP Tables" >> "$Log" 2>&1
}

echo "Starting ... `date`"

install_open_jdk
if [ $? = 0 ];then
	mount_volume $1
		if [ $? = 0 ];then
			install_artifactory $1
			copy_configuration_files $1
			open_firewall
		fi
fi

# For CIS-CAT report
sed -i 's/max_log_file_action = rotate/max_log_file_action = keep_logs/g' /etc/audit/auditd.conf
sed -i 's/SELINUX=permissive/SELINUX=enforcing/g' /etc/selinux/config
