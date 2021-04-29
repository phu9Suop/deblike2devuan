#!/bin/bash 
# This script upgrades from a debian based distribution to devuan beowulf
# grafted from the devuan migration webpage
# part 2 after reboot
#
set -x -v
if [ ${UID} != 0 ] ; then 
	echo "you are not root"
	exit 126
fi
cat <<warning
You may stop the execution of this scipt anytime by hitting Ctrl-c
warning

OLD_RELEASE=$(cat /etc/distname.old)
NEW_RELEASE=$(grep "NEW_RELEASE="  deb2dev_before_reboot.bash | cut -f "=" 2)

# Now you can perform the migration proper.
apt-get dist-upgrade

# We have migrated to Devuan so systemd related packages are not needed now.
apt-get remove systemd libnss-systemd
cat <<remember_to
There are surely your own jobs to be migrated e.g. 
systemd jobs at boot to /etc/rc.local
systemd timer jobs to /etc/cron*,
may be others with dependency on runlevels
so do the purge only, when this is all done.
apt-get purge systemd libnss-systemd
remember_to

# You may need other packages from contrib and non-free
sed -i -e '%s/main$/main contrib non-free$/'/etc/apt/sources.list

# modify the grub if needed

# if you dont have a desktop at this point, now you install one.
DESKTOP_PACKAGE=""
PS3='Please enter your choice:' 
options=("cinnamon gnome lxde lyqt kde mate xfce Quit")
select opt in "${options[@]}"
do
	case $opt in
		"cinnamon")
			DESKTOP_PACKAGE=task-cinnamon-desktop
			;;
		"gnome")
			DESKTOP_PACKAGE=task-gnome-desktop
			;;
		"lxde")
			DESKTOP_PACKAGE=task-lxde-desktop
			;;
		"lxqt")
			DESKTOP_PACKAGE=task-lxqt-desktop
			;;
		"kde")
			DESKTOP_PACKAGE=task-lxqt-desktop
			;;
		"mate")
			DESKTOP_PACKAGE=task-mate-desktop
			;;
		"xfce")
			DESKTOP_PACKAGE=task-xfce-desktop
			;;
		"Quit")
			if [ -z "DESKTOP_PACKAGE" ] ; then
				echo "you choose no desktop"
			else
				echo "you choose ${DESKTOP_PACKAGE}"
			fi
			break
			;;
		"*")
			echo "invalid option $REPLY"
			;;
	esac
	echo "you choose ${DESKTOP_PACKAGE}"
done

if [ -n "DESKTOP_PACKAGE" ] ; then
	apt-get install ${DESKTOP_PACKAGE}
	# now modify inittab runlevel, as it is a graphical desktop
	# # from 2 to 5
	sed -i -e 's/id:2/id:5/' /etc/inittab
fi

# if you want backports then say yes
cd /etc/apt/sources.list.d
[ -f ${OLD_RELEASE}-backports.list ] && rm  ${OLD_RELEASE}-backports.list 
cat > ${NEW_RELEASE}-backports.list <<backportstext 
deb http://deb.devuan.org/merged ${NEW_RELEASE}-backports main contrib non-free
backportstext
apt-get update
apt-get upgrade

# you can now remove any packages orphaned by the migration process and 
# any unusable archives left over from your Debian install.
apt-get autoremove --purge
apt-get autoclean

# remove systemd users from /etc/passwd und /etc/shadow

# if you want reboot now, then say yes
init 6

exit 0
