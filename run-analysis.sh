#!/bin/bash

images="ubi8/ubi ubi8/ubi-minimal fedora centos:7 debian:bullseye-slim debian:bullseye ubuntu:latest alpine:latest"

get_version() {
	echo Version: `podman run -it $1 cat /etc/os-release | grep PRETTY`
}

get_c_library() {
	echo C Library: `podman run -it $1 ldd /bin/sh | grep libc`
	}

get_package_manager() {
	echo Packager: `podman run -it $1 sh -c "ls /usr/bin /sbin | egrep '^rpm$|^apk$|^apt$'"`
	}

get_size() {
	mkdir -p cache
	cd cache
	name=`echo $1 | md5sum | cut -f1 -d" "`
	if [ ! -f $name ]
	then
		podman save -o $name $1 2>/dev/null
	fi
	if [ ! -f "$name.gz" ]
	then
		gzip --keep $name
	fi
	compressed_size=`du -sh $name.gz | cut -f1`
	echo Compressed Size: $1: $compressed_size
	size=`du -sh $name | cut -f1`
	echo Size: $1: $size

	# Clean up
	# rm $name
	# rm $name.gz
}

get_core_utils() {
	if j=`podman run -it -rm $1 rpm -qa 2>&1 | egrep '^coreutils-single.*$|^coreutils-[0-9].*$'`
	then
		echo "Core Utils: $j"
	elif j=`podman run -it -rm $1 apt list 2>&1 | grep coreutils`
	then
		echo "Core Utils: $j"
	elif j=`podman run -it --rm $1 apk list 2>&1 | grep ^busybox.*$`
	then
		echo "Core Utils: $j"
	fi
}

cache_images() {
	for i in $images
	do
		podman pull -q $i
	done
}

#cache_images

for i in $images
do 
	get_version $i
	get_c_library $i
	get_package_manager $i
	get_size $i
	get_core_utils $i
	echo ""
done




