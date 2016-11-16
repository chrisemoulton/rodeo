#!/bin/bash
#
# useful links: http://xn.pinkhamster.net/blog/tech/host-a-debian-repository-on-s3.html
# https://www.digitalocean.com/community/tutorials/how-to-use-reprepro-for-a-secure-package-repository-on-ubuntu-14-04


## BUILDING FOR DEBIAN / UBUNTU

# install packaging dependencies
sudo apt-get install -y reprepro s3cmd jq

TARGET_DIR=/rodeo-deb-repo

mkdir $TARGET_DIR && cd $TARGET_DIR

DEB_DOWNLOAD=$(curl -s https://api.github.com/repos/yhat/rodeo/releases/latest | jq -r '.assets[].browser_download_url | select(endswith(".deb"))')
VERSION=$(curl -s https://api.github.com/repos/yhat/rodeo/releases/latest | jq -r '.tag_name')

# download the latest build and put it in tmp
sudo wget $DEB_DOWNLOAD -O /tmp/rodeo_"$VERSION"_amd64.deb

# THIS SECTION IS ONLY IF THERE ISNT AN EXISTING DEB REPO
# create the packaging structure
# cd $TARGET_DIR
# mkdir -p conf

# create the distribution file with info, need to read more about this
#printf 'Origin: Rodeo\nLabel: Rodeo\nCodename: rodeo\nComponents: main\nArchitectures: amd64\nDescription: An IDE for doing data science\nSignWith:33D40BC6\n' > ./conf/distributions


# you need the yhat-dev secret gpg key listed in your keychain:
# first import the env var that is the signing key and save it in the tmp dir
echo "$SIGNING_KEY" >> /tmp/signingkey.key
gpg --import /tmp/signingkey.key
gpg --export-secret-keys | gpg2 --import -


# NOW, we must pull the current repo from AWS
s3cmd --access_key=$ACCESS_KEY --secret_key=$SECRET_KEY get s3://rodeo-deb.yhat.com/ -r

reprepro -b . includedeb rodeo /tmp/rodeo_*.deb

s3cmd rm -r --force s3://rodeo-deb.yhat.com/ --access_key=$ACCESS_KEY --secret_key=$SECRET_KEY
s3cmd sync -r . s3://rodeo-deb.yhat.com/ --acl-public --access_key=$ACCESS_KEY --secret_key=$SECRET_KEY
