#!/bin/bash
# This script upgrades from a debian based distribution to devuan beowulf
# grafted from the devuan migration webpage
# part 1 before reboot

set -x 

cat <<warning1 
There cannot be a guarantee on the function of this script.
Backup first all your data, and then use at your own risk
You may end with a non-bootable installation.
You may stop the execution of this scipt anytime by hitting Ctrl-C
You can exit this script before the actual reboot.
warning1

if [ ${UID} != 0 ] ; then
	echo "you are not root, please run as root"
	exit 126
fi

if [ "$( ps -p $$ -o ppid -o tname | /bin/grep tty[1-6] )" ] ; then
	echo "good boy, you are root and on the console."
else 
	cat <<warning2
	This is bad, because an xserver is still running which shall better be stopped first
	or you are on an virtual terminal.
	This script will kill any xsession during its execution
	and so it may also kill itself. Terminate all X processes.
	Logout properly from the x-session,
	go to a console with CTRL-ALT-F1 .. F6
	There you login as root or sudo to root.
warning2
	exit 126
fi

# could have done this as an one-liner
OLD_RELEASE=$(lsb_release -c | cut -f 2)
echo "${OLD_RELEASE}" > /etc/distname.old

NEW_RELEASE=beowulf
PACK_CACHE=/var/cache/apt/archives/

# update upgrade the actual distribution and store selection

apt-get update
apt-get upgrade
apt-mark minimize-manual
apt-mark showmanual > "etc/manual_selection_${HOST}.list"

# clean the local package cache completely of all packages of
# the previous distribution to avoid disk space exhaustion.
apt-get clean

# exchange sources lists
cd /etc/apt/sourceslist.d/ || exit 
mv ./* ./*.old
cd ..
mv sources.list sources.list.old

cat > sources.list <<EOF_sources.list
deb http://deb.devuan.org/merged ${NEW_RELEASE} main
deb http://deb.devuan.org/merged ${NEW_RELEASE}-updates main
deb http://deb.devuan.org/merged ${NEW_RELEASE}-security main
EOF_sources.list

# back to the roots
cd ~ || echo 2

# update the package lists
apt-get update --allow-insecure-repositories

# unsecure install devuan-keyring
apt-get install devuan-keyring --allow-unauthenticated

# Update the package lists again now secured
apt-get update

# if you want to use the wicd network manager, this needs to be installed now or the upgrade will fail.
apt-get install wicd-gtk

# Upgrade your packages so that you have the latest versions. 
# Note that this does not complete the migration.
apt-get upgrade

# eudev needs to be installed
# "apt-get install eudev"
# here the devuan webpage manual failed, because systemd refuses to be removed
# "apt-get -f install" refused also to work
 
# instead I do
# download all packages as selected
apt-get download

# install all downloaded packages at once 
[ -d ${PACK_CACHE} ] && cd ${PACK_CACHE} || exit 2 
dpkg -i ./*.deb

# check status
apt-get show init

# ask confirmation
#echo "Do you want to reboot now ?" 
#read
#case

# Are you done ? then 
reboot

exit 0
