#!/bin/bash

declare -A images
images+=( \
	["ubi8"]=ubi8/ubi \
	["ubi8-minimal"]=ubi8/ubi-minimal \
	["ubi8-micro"]=ubi8-micro \
	["fedora"]=fedora \
	["centos"]=centos:7 \
	["debian-bullseye-slim"]=debian:bullseye-slim \
	["debian-bullseye"]=debian:bullseye \
	["ubuntu"]=ubuntu:latest \
	["alpine"]=alpine:latest \
	)
LOGFILE=".run-analysis.log"

get_version() {
	echo Version: `podman run -it ${images[${1}]} cat /etc/os-release | grep PRETTY`
}

get_c_library() {
	echo C Library: `podman run -it ${images[${1}]} ldd /bin/sh | grep libc`
	}

get_package_manager() {
	echo Packager: `podman run -it ${images[${1}]} sh -c "ls /usr/bin /sbin | egrep '^rpm$|^apk$|^apt$'"`
	}

get_size() {
	mkdir -p cache
	name=`echo $1 | md5sum | cut -f1 -d" "`
	if [ ! -f $name ]
	then
		podman save -o ./cache/$name $1 2>/dev/null
	fi
	if [ ! -f "./cache/$name.gz" ]
	then
		gzip --keep ./cache/$name
	fi
	compressed_size=`du -sh ./cache/$name.gz | cut -f1`
	echo Compressed Size: $1: $compressed_size
	size=`du -sh ./cache/$name | cut -f1`
	echo Size: $1: $size

	# Clean up
	# rm ./cache/$name
	# rm ./cache/$name.gz
}

get_core_utils() {
	if j=`podman run -it --rm ${images[${1}]} rpm -qa 2>&1 | egrep '^coreutils-single.*$|^coreutils-[0-9].*$'`
	then
		echo "Core Utils: $j"
	elif j=`podman run -it --rm ${images[${1}]} apt list 2>&1 | grep coreutils`
	then
		echo "Core Utils: $j"
	elif j=`podman run -it --rm ${images[${1}]} apk list 2>&1 | grep ^busybox.*$`
	then
		echo "Core Utils: $j"
	fi
}

get_java_size() {
	podman build -t java-$1 -f build/Containerfile.java.$1 >> $LOGFILE
	get_size java-$1
}

cache_images() {
	for i in $images
	do
		podman pull -q $i
	done
}

cache_software() {
	TOMCAT_DOWNLOAD_URL="http://mirrors.ocf.berkeley.edu/apache/tomcat/tomcat-9/v9.0.35/bin/apache-tomcat-9.0.35.tar.gz"
	JSPWIKI_DOWNLOAD_URL="http://mirrors.ocf.berkeley.edu/apache/jspwiki/2.11.0.M6/binaries/webapp/JSPWiki.war"
	mkdir -p ./build/tomcat
	wget -qO- $TOMCAT_DOWNLOAD_URL | tar xvfz - --strip-components=1 -C ./build/tomcat
	mkdir -p ./build/jsp-wiki
	cd ./build/jsp-wiki; wget $JSPWIKI_DOWNLOAD_URL
}

#cache_images
#cache_software

for i in ${!images[@]}
do 
	get_version $i
	get_c_library $i
	get_package_manager $i
	get_size ${images[${i}]}
	get_core_utils $i
	get_java_size $i
	echo ""
done




