#!/bin/bash

set -o pipefail

# Generate library file.
# $1 : device type
# $2 : distribution
# $3 : variants
function generate_library(){
	if [ $2 == 'debian' ]; then
		lib_name="$1-golang"
	else
		lib_name="$1-$2-golang"
	fi
	path="$1/$2"

	cd $path
	versions=( */ )
	versions=( "${versions[@]%/}" )
	cd -

	echo '# maintainer: InfoSiftr <github@infosiftr.com> (@infosiftr)' > $lib_name
	echo '# maintainer: Johan Euphrosine <proppy@google.com> (@proppy)' >> $lib_name
	echo '# maintainer: Trong Nghia Nguyen - resin.io <james@resin.io>' >> $lib_name
	url='git://github.com/resin-io-library/base-images'

	for version in "${versions[@]}"; do

		commit="$(git log -1 --format='format:%H' -- "$path/$version")"
		fullVersion="$(find "$path/$version" -name 'Dockerfile' -exec bash -c 'grep -m1 "ENV GO_VERSION " "$0" | cut -d" " -f3; kill "$PPID"' {} \;)"
		if [ $version == 'default' ]; then
			versionAliases=( $fullVersion )
		else
			if [ $version == $fullVersion ]; then
				versionAliases=( $version ${aliases[$fullVersion]} )
			else
				versionAliases=( $fullVersion $version ${aliases[$fullVersion]} )
			fi
		fi

		if [ -f "$path/$version/Dockerfile" ]; then
			echo >> $lib_name
			for va in "${versionAliases[@]}"; do
				echo "$va: ${url}@${commit} $repo/$path/$version" >> $lib_name
			done
		fi
	
		for variant in $3; do
			if [ -d "$path/$version/$variant" ]; then
				commit="$(git log -1 --format='format:%H' -- "$path/$version/$variant")"
				echo >> $lib_name
				for va in "${versionAliases[@]}"; do
					if [ "$va" = 'latest' ]; then
						va="$variant"
					else
						va="$va-$variant"
					fi
					echo "$va: ${url}@${commit} $repo/$path/$version/$variant" >> $lib_name
				done
			fi
		done
	done
}

declare -A aliases
aliases=(
	[1.8]='1 latest'
)

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

repo=${PWD##*/}

devices=( "$@" )
if [ ${#devices[@]} -eq 0 ]; then
	devices=( */ )
fi
devices=( "${devices[@]%/}" )

for device in "${devices[@]}"; do

	cd $device
	distros=( */ )
	distros=( "${distros[@]%/}" )
	cd ..
	
	for distro in "${distros[@]}"; do
		# Debian
		if [ $distro == 'debian' ]; then
			generate_library "$device" "$distro" "wheezy slim onbuild"
		fi
		# Alpine
		if [ $distro == 'alpine' ]; then
			generate_library "$device" "$distro" "3.5 slim onbuild"
		fi
		# Fedora
		if [ $distro == 'fedora' ]; then
			generate_library "$device" "$distro" "23 slim onbuild"
		fi
	done
done
