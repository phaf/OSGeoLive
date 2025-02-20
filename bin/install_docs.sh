#!/bin/sh
# Copyright (c) 2009-2013 The Open Source Geospatial Foundation.
# Copyright (c) 2009 LISAsoft
# Copyright (c) 2009 Cameron Shorter
# Licensed under the GNU LGPL version >= 2.1.
# 
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation, either version 2.1 of the License,
# or any later version.  This library is distributed in the hope that
# it will be useful, but WITHOUT ANY WARRANTY, without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU Lesser General Public License for more details, either
# in the "LICENSE.LGPL.txt" file distributed with this software or at
# web page "http://www.fsf.org/licenses/lgpl.html".

# About:
# =====
# This script will install documentation

./diskspace_probe.sh "`basename $0`" begin
BUILD_DIR=`pwd`
####


if [ -z "$USER_NAME" ] ; then
   USER_NAME="user"
fi
USER_HOME="/home/$USER_NAME"
DEST="/var/www/html"
DATA_FOLDER="/usr/local/share/data"


apt-get --assume-yes install python-sphinx

# Use sphynx to build the OSGeo-Live documentation
cd "$BUILD_DIR"/../doc
make clean
make html

# Create target directory if it doesn't exist
mkdir -p "$DEST"

# Remove then replace target documentation, leaving other files
cd "$BUILD_DIR"/../doc/_build/html
for FILE in `ls` ; do
  rm -fr "$DEST/$FILE"
done
mv * "$DEST"

# post-install cleanup build dir
cd "$BUILD_DIR"/../doc
make clean


#### work around sphinx bug #704: clear out duplicate images
#  (osgeo trac #952)
replace_w_symlink()
{
# only act if base is a regular file
if [ -f "$NONUM.$ext" ] ; then
   # only act if files are identical
   diff "$NONUM.$ext" "$file" > /dev/null
   if [ $? -eq 0 ] ; then
      #echo "[$file] -> [$NONUM.$ext]"
      rm -f "$file"
      ln -s "$NONUM.$ext" "$file"
      # avoid the need for symlinks
      #HITS=`grep -rl "../../_images/$file.$ext" ../[a-z][a-z]/*`
      #if [ -n "$HITS" ] ; then
      #   sed -i -e "s|../../_images/$file.$ext|../../_images/$NONUM.$ext|" $HITS
      #fi
   fi
fi
}

cd "$DEST/_images/"
SPHX_VER=`dpkg -l python-sphinx | grep sphinx | awk '{print $3}' | cut -f1 -d'+'`
if [ "$SPHX_VER" = "1.2.2" ] ; then
   for ext in png jpg gif ; do
      for file in *.$ext ; do
	 if [ -h "$file" ] ; then
	    # already a symlink
	    continue
	 fi

	 NONUM=`echo "$file" | sed -e "s/[0-9]\+\.$ext//"`

	 if [ -h "$NONUM.$ext" ] ; then
	    # replace anyway?? base is already a symlink
	    continue
	 fi

	 if [ "$NONUM" = "$file" ] ; then
	    continue
	 fi

	 if [ -f "$NONUM.$ext" ] ; then
	    replace_w_symlink
	    continue
	 fi

	   # try with a number after it
	 if [ `ls "$NONUM"[0-9]."$ext" 2> /dev/null | wc -l` -gt 0 ] ; then
	    NONUM=`echo "$file" | sed -e "s/[0-9]\.$ext//"`
	    if [ -f "$NONUM.$ext" ] ; then
	       replace_w_symlink
	       continue
            fi
	 fi

	   # or two
	 if [ `ls "$NONUM"[0-9][0-9]."$ext" 2> /dev/null | wc -l` -gt 0 ] ; then
	    NONUM=`echo "$file" | sed -e "s/[0-9]\.$ext//"`
	    if [ -f "$NONUM.$ext" ] ; then
	       replace_w_symlink
	       continue
            fi
	 fi

	   # or three
	 if [ `ls "$NONUM"[0-9][0-9][0-9]."$ext" 2> /dev/null | wc -l` -gt 0 ] ; then
	    NONUM=`echo "$file" | sed -e "s/[0-9]\.$ext//"`
	    if [ -f "$NONUM.$ext" ] ; then
	       replace_w_symlink
	       continue
            fi
	 fi

	   # or four
	 if [ `ls "$NONUM"[0-9][0-9][0-9][0-9]."$ext" 2> /dev/null | wc -l` -gt 0 ] ; then
	    NONUM=`echo "$file" | sed -e "s/[0-9]\.$ext//"`
	    if [ -f "$NONUM.$ext" ] ; then
	       replace_w_symlink
	       continue
            fi
	 fi
	 # ... still more?
      done
   done
fi

# Create symbolic links to project specific documentation
cd "$DEST"

# PDF
ln -s /usr/local/share/udig/udig-docs .
if [ -d /usr/local/mbsystem ] ; then
   ln -s /usr/local/mbsystem .
fi

ln -s /usr/local/share/qgis .
ln -s /usr/local/share/qgis_mapserver/mapviewer.html \
      /usr/local/share/qgis_mapserver/index.html
ln -s /usr/local/share/qgis_mapserver qgis_server
#ln -s /usr/share/doc/geopublishing-doc geopublishing
ln -s /usr/local/share/saga .

# HTML
mkdir -p gmt
ln -s /usr/share/doc/gmt/html gmt/html
ln -s /usr/share/doc/gmt/pdf gmt/pdf
ln -s /usr/share/doc/gmt-examples gmt/examples
ln -s /usr/share/doc/gmt-tutorial gmt/tutorial
ln -s /usr/share/doc/grass-doc/html grass
ln -s /usr/local/share/mapnik/demo mapnik
ln -s /usr/local/share/mapserver/doc mapserver
#ln -s /usr/share/doc/opencpn-doc/doc opencpn  # <-- correct & future home
ln -s /usr/share/opencpn/doc opencpn
ln -s /usr/local/share/otb .
ln -s /usr/local/share/ossim .

# Data
ln -s /usr/local/share/data .


####
# Installer dirs (maybe they work, maybe they don't...
#   We add the installer dirs after building the image, so we
#   have to decide to link or not link to them at boot time.
if [ `grep -c 'WindowsInstallers' /etc/rc.local` -eq 0 ] ; then
    sed -i -e 's|exit 0||' /etc/rc.local
    cat << EOF >> /etc/rc.local

# Detect full iso, adjust symlinks/placeholders as needed
if [ -d /cdrom/WindowsInstallers ] && \
   [ -f "$DEST"/WindowsInstallers/index.html ] ; then
    ln -s /cdrom/WindowsInstallers /etc/skel/
    ln -s /cdrom/MacInstallers /etc/skel/
    if [ -d "/home/$USER_NAME" ] ; then
        ln -s /cdrom/WindowsInstallers "/home/$USER_NAME"/
        ln -s /cdrom/MacInstallers "/home/$USER_NAME"/
        chown "$USER_NAME.$USER_NAME" "/home/$USER_NAME"/[WM]*Installers
    fi

    rm -f "$DEST"/WindowsInstallers/index.html
    rm -f "$DEST"/MacInstallers/index.html
    rmdir "$DEST"/WindowsInstallers
    rmdir "$DEST"/MacInstallers
    ln -s /cdrom/WindowsInstallers "$DEST"
    ln -s /cdrom/MacInstallers "$DEST"
fi

exit 0
EOF
fi


####
# Link to the extra data dir:
#   We add the extra data dir after building the image, so we
#   have to decide to link or not link to them at boot time.
if [ `grep -c 'extra_data' /etc/rc.local` -eq 0 ] ; then
    sed -i -e 's|exit 0||' /etc/rc.local
    cat << EOF >> /etc/rc.local

# Detect big-data iso, adjust symlinks/placeholders as needed
if [ -d /cdrom/extra_data ] ; then
    ln -s /cdrom/extra_data /usr/local/share/data/extra
    ln -s /cdrom/extra_data "$DEST"/
else
   mkdir -p /usr/local/share/data/extra
# TODO:
#   cp extra_data.html /usr/local/share/data/extra/index.html
   echo "Please visit  http://download.osgeo.org/livedvd/data/" \
      > /usr/local/share/data/extra/readme.txt
fi

exit 0
EOF
fi


cd "$BUILD_DIR"

echo "install_docs.sh: Double-check that the Firefox \
home page is now set to file://$DEST/index.html"
# ~user/.mozilla/ has to exist first, so firefox would have need
#   to been started at least once to set it up

# edit ~user/.mozilla/firefox/$RANDOM.default/prefs.js:
#   user_pref("browser.startup.homepage", "http://localhost");

PREFS_FILE=`find "$USER_HOME/.mozilla/firefox/" | grep -w default/prefs.js | head -n 1`
if [ -n "$PREFS_FILE" ] ; then
   sed -i -e 's+\(homepage", "\)[^"]*+\1http://localhost+' \
      "$PREFS_FILE"

   # firefox snafu: needed for web apps to work if network is not there
   echo 'user_pref("toolkit.networkmanager.disable", true);' >> "$PREFS_FILE"
   # maybe being online won't stick, but we may as well try:
   echo 'user_pref("network.online", true);' >> "$PREFS_FILE"
fi

# reset the homepage for the main ubuntu-firefox theme too (if present)
# see also http://bazaar.launchpad.net/~mozillateam/ubufox/trunk/view/head:/defaults/preferences/ubuntu-mods.js
if [ -e /etc/xul-ext/ubufox.js  ] ; then
   sed -i -e 's+^//pref("browser.startup.homepage".*+pref("browser.startup.homepage", "http://localhost");+' \
       /etc/xul-ext/ubufox.js
   echo 'pref("startup.homepage_override_url","http://localhost");' >> /etc/xul-ext/ubufox.js
   echo 'pref("startup.homepage_welcome_url","http://localhost");' >> /etc/xul-ext/ubufox.js
fi     

# how about this one?
if [ `grep -c 'localhost' /etc/firefox/syspref.js` -eq 0 ] ; then
   echo 'pref("browser.startup.homepage", "http://localhost";' \
      >> /etc/firefox/syspref.js
   echo 'pref("startup.homepage_override_url","http://localhost");' \
      >> /etc/firefox/syspref.js
   echo 'pref("startup.homepage_welcome_url","http://localhost");' \
      >> /etc/firefox/syspref.js
fi

#TODO for next time to make things less congested for netbook users:
#    pref("browser.tabs.autoHide", true);
#    pref("browser.rights.3.shown", true);
#  and which config to make the toolbar use small icons? (rt click on toolbar configure)

#Alternative, just put an icon on the desktop that launched firefox and points to index.html
mkdir -p /usr/local/share/icons
cp -f ../desktop-conf/arramagong-wombat-small.png  /usr/local/share/icons/


# Terminal toolbar off by default, and let's brighten the font
echo "hidemenubar=true" >> /usr/share/lxterminal/lxterminal.conf
echo "fgcolor=#adadadadadad" >> /usr/share/lxterminal/lxterminal.conf
#sed -i -e 's/\(fgcolor=\).*/\1#adadadadadad/' \
#   /etc/xdg/lubuntu/lxterminal/lxterminal.conf


#What logo to use for launching the help?
# HB: IMO wombat roadsign is good- it says "look here" and is friendly
ICON_FILE="live_GIS_help.desktop"
# perhaps: Icon=/usr/share/icons/oxygen/32x32/categories/system-help.png

cat << EOF > "/usr/local/share/applications/$ICON_FILE"
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=Help
Comment=Live Demo Help
Categories=Application;Education;Geography;
Exec=firefox http://localhost
Icon=/usr/local/share/icons/arramagong-wombat-small.png
Terminal=false
StartupNotify=false
EOF

cp -a "/usr/local/share/applications/$ICON_FILE" "$USER_HOME/Desktop/"
chown $USER_NAME.$USER_NAME "$USER_HOME/Desktop/$ICON_FILE"
# executable bit needed for Ubuntu 9.10's GNOME. Also make the first line
#   of the *.desktop files read "#!/usr/bin/env xdg-open"
#chmod u+x "$USER_HOME/Desktop/$ICON_FILE"

#data dir
ICON_FILE="live_GIS_data.desktop"
cat << EOF > "/usr/local/share/applications/$ICON_FILE"
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=Sample data
Comment=Sample Geo Data
Categories=Application;Education;Geography;
Exec=pcmanfm /usr/local/share/data
Icon=twf
Terminal=false
StartupNotify=false
EOF

cp -a "/usr/local/share/applications/$ICON_FILE" "$USER_HOME/Desktop/"
chown $USER_NAME.$USER_NAME "$USER_HOME/Desktop/$ICON_FILE"


#Should we embed the password file in the help somehow too?
# =note that it needs to be installed first! move here from install_desktop.sh if needed=


# Download the Ubuntu users' manual PDF (CC By SA 3.0)
mkdir -p /usr/local/share/doc

wget -c --progress=dot:mega \
  "http://files.ubuntu-manual.org/manuals/getting-started-with-ubuntu/14.04e2/en_US/screen/Getting%20Started%20with%20Ubuntu%2014.04%20-%20Second%20edition.pdf" \
  -O "/usr/local/share/doc/Getting Started with Ubuntu 14.04 - Second edition.pdf"

if [ $? -ne 0 ] ; then
   # try try again
   wget -c --progress=dot:mega \
     "http://files.ubuntu-manual.org/manuals/getting-started-with-ubuntu/14.04e2/en_US/screen/Getting%20Started%20with%20Ubuntu%2014.04%20-%20Second%20edition.pdf" \
     -O "/usr/local/share/doc/Getting Started with Ubuntu 14.04 - Second edition.pdf"
fi

ln -s /usr/local/share/doc/Getting_Started_with_Ubuntu_13.10.pdf \
  "$USER_HOME/Desktop/Getting Started with Ubuntu 14.04 - Second edition.pdf"


####
"$BUILD_DIR"/diskspace_probe.sh "`basename $0`" end
