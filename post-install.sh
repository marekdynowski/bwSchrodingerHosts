#!/bin/bash

###############################################################
#                                                             #
# MOAB Post-Installer                                         #
#                                                             #
#                                                             #
# Please report issues at                                     #
# https://github.com/marekdynowski/bwSchrodingerHosts/issues  #
#                                                             #
###############################################################

set -o nounset
set -o errexit

MOAB_TAR_URL="https://api.github.com/repos/marekdynowski/MOAB-Schroedinger-Submitter/tarball/master"
SCHRODHOST_TAR_URL="https://api.github.com/repos/marekdynowski/bwSchrodingerHosts/tarball/master"
SCHRODINGER_PATH=
#INSTALL_MOAB=false
TMPDIR=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`

#HAS_GIT=true
#command -v git >/dev/null 2>&1 || { HAS_GIT=false; }

# functions

cleanup_exit () {
	rm -r $TMPDIR
}

trap cleanup_exit EXIT	# execute on EXIT

test_schrod_dir () {
	if [[ -d $1 ]]; then
		if [[ -w $1 ]]; then
			if [[ -e $1/schrodinger.hosts ]]; then
				return 0
			else
				>&2 echo "The schrodinger directory must contain the file schrodinger.hosts"
				return 1
			fi
		else
			>&2 echo "You must be the owner of the schrodinger directory. Run as root?"
			return 1
		fi
	else
		>&2 echo "The specified path does not exist!"
		return 2
	fi
}

# script start

echo
echo "===== Schrodinger Post-Install ====="
echo
echo

echo "TMP dir: $TMPDIR"

echo
echo

while true; do
	read -e -p "Please specify your Schrodinger path: " u_schrod_path
	u_schrod_path=$(echo $u_schrod_path | tr -s /)	# remove repeating '/'
	u_schrod_path=${u_schrod_path%/}		# remove trailing '/'
	if test_schrod_dir $u_schrod_path; then
		SCHRODINGER_PATH=$u_schrod_path
		break;
	fi
done

echo
echo
echo
echo
echo "Schrodinger path: $SCHRODINGER_PATH"
echo "This script will generate a new schrodinger.hosts"
echo "The current schrodinger.hosts will be renamed to schrodinger.hosts.BAK"
echo

if [[ -e $SCHRODINGER_PATH/schrodinger.hosts.BAK ]]; then
	echo "The file schrodinger.hosts.BAK does exist already"
	echo "It will be overwritten"
	echo
fi

echo
echo "Please specify the license server, Schrodinger version and your username on following clusters. Type nothing if you don't have an account."
read -e -p "License server: " u_license_server
read -e -p "Schrodinger version (e.g. 2015u4): " u_schrod_version
echo "=== Usernames for: ==="
read -e -p "bwGRiD - Uni Tübingen: " u_user_bwgrid
read -e -p "bwUni - Uni Karlsruhe: " u_user_bwuni
read -e -p "Justus - Uni Ulm: " u_user_justus

echo
echo

# check MOAB
#if ! [[ -d $SCHRODINGER_PATH/queues/MOAB ]]; then
#	echo "The directory \$SCHRODINGER/queues/MOAB does not exist"
#	echo "You need the MOAB submitter to submit jobs to the cluster"
#	while true; do
#	    read -p "Do you wish to install the MOAB submitter? (y/n) " yn
#	    case $yn in
#		[Yy]* ) INSTALL_MOAB=true; echo "The MOAB submitter will be installed"; break;;
#		[Nn]* ) break;;
#		* ) echo "Please answer yes or no.";;
#	    esac
#	done
#else
#	echo "The MOAB submitter was detected"
#	while true; do
#	    read -p "Do you wish to reinstall the MOAB submitter? (y/n) " yn
#	    case $yn in
#		[Yy]* ) INSTALL_MOAB=true; echo "The MOAB submitter will be reinstalled"; break;;
#		[Nn]* ) break;;
#		* ) echo "Please answer yes or no.";;
#	    esac
#	done
#fi

echo
echo
echo
echo
echo
echo "############"
echo "# OVERVIEW #"
echo "############"
echo "Schrodinger path: $SCHRODINGER_PATH"
echo "License server: $u_license_server"
echo "Schrodinger version: $u_schrod_version"
printf "Username - bwGRiD Tübingen: "
if [[ -n $u_user_bwgrid ]]; then
	echo "$u_user_bwgrid"
else
	echo "<no login>"
fi
printf "Username - bwUni Karlsruhe: "
if [[ -n $u_user_bwuni ]]; then
	echo "$u_user_bwuni"
else
	echo "<no login>"
fi
printf "Username - Justus Ulm: "
if [[ -n $u_user_justus ]]; then
	echo "$u_user_justus"
else
	echo "<no login>"
fi
#echo "Install MOAB submitter: $INSTALL_MOAB"
echo
echo "Please leave maestro closed while running this script. All current jobs will be killed!"
echo

while true; do
    read -p "Do you wish to execute this script? (y/n) " yn
    case $yn in
        [Yy]* ) echo "ok"; break;;
        [Nn]* ) echo "Exiting..."; exit 0; break;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo
echo "Download and extracting the schrodinger.hosts packet"
echo

curl -Lo $TMPDIR/SchrodingerHost.tar.gz $SCHRODHOST_TAR_URL
tar -xf $TMPDIR/SchrodingerHost.tar.gz -C $TMPDIR

echo
echo "Backup schrodinger.hosts to schrodinger.hosts.BAK and generating new schrodinger.hosts"
mv $SCHRODINGER_PATH/schrodinger.hosts $SCHRODINGER_PATH/schrodinger.hosts.BAK
sed "s/%LICENSE_SERVER%/$u_license_server/" $TMPDIR/marekdynowski-bwSchrodingerHosts-*/schrodinger.hosts_head \
| sed "s/%SCHROD_VERSION%/$u_schrod_version/" \
> $SCHRODINGER_PATH/schrodinger.hosts

# bwGRiD
if [[ -n $u_user_bwgrid ]]; then
	sed "s/%USER_BWGRID%/$u_user_bwgrid/" $TMPDIR/marekdynowski-bwSchrodingerHosts-*/schrodinger.hosts_bwgrid \
	| sed "s/%SCHROD_VERSION%/$u_schrod_version/" \
	>> $SCHRODINGER_PATH/schrodinger.hosts
fi

# bwUni
if [[ -n $u_user_bwuni ]]; then
	sed "s/%USER_BWUNI%/$u_user_bwuni/" $TMPDIR/marekdynowski-bwSchrodingerHosts-*/schrodinger.hosts_bwuni \
	| sed "s/%SCHROD_VERSION%/$u_schrod_version/" \
	>> $SCHRODINGER_PATH/schrodinger.hosts
fi

# Justus
if [[ -n $u_user_justus ]]; then
	sed "s/%USER_JUSTUS%/$u_user_justus/" $TMPDIR/marekdynowski-bwSchrodingerHosts-*/schrodinger.hosts_justus \
	| sed "s/%SCHROD_VERSION%/$u_schrod_version/" \
	>> $SCHRODINGER_PATH/schrodinger.hosts
fi

#if $INSTALL_MOAB; then
echo
echo "Installing MOAB submitter"
echo "Downloading and extracting the MOAB submitter packet"
echo

curl -Lo $TMPDIR/MOAB.tar.gz $MOAB_TAR_URL
tar -xf $TMPDIR/MOAB.tar.gz -C $TMPDIR
# remove if exists
if [[ -d $SCHRODINGER_PATH/queues/MOAB ]]; then
	rm -r $SCHRODINGER_PATH/queues/MOAB
fi
cp -r $TMPDIR/marekdynowski-MOAB-Schroedinger-Submitter-*/MOAB $SCHRODINGER_PATH/queues/.
#fi

echo "Disable JSERVER_GO"

$SCHRODINGER_PATH/utilities/feature_flags -d JOBCON_JSERVER_GO || true
$SCHRODINGER_PATH/utilities/jserver -cleanall || true
$SCHRODINGER_PATH/utilities/jserver -shutdown || true

echo
echo "Done."

exit 0
