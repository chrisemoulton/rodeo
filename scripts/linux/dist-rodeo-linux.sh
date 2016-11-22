#!/bin/bash
#
# useful links: http://xn.pinkhamster.net/blog/tech/host-a-debian-repository-on-s3.html
# https://www.digitalocean.com/community/tutorials/how-to-use-reprepro-for-a-secure-package-repository-on-ubuntu-14-04

# install packaging dependencies
# Note: added to circle.yml file
# sudo apt-get install -y reprepro s3cmd jq
#
## BUILD TRIGGER: git push && git push --tags
#
## BUILDING FOR DEBIAN / UBUNTU

TARGET_DIR=/rodeo-deb-repo
REPO_URL='https://api.github.com/repos/yhat/rodeo/releases/latest'
PKG_EXT='.deb'
DEB_DOWNLOAD=$(curl -s $REPO_URL | jq -r '.assets[].browser_download_url | select(endswith("'${PKG_EXT}'"))')
VERSION=$(curl -s $REPO_URL | jq -r '.tag_name')
DEB_FILE="/tmp/rodeo_${VERSION}_amd64${PKG_EXT}"

sudo mkdir $TARGET_DIR
cd $TARGET_DIR
pwd

echo '==========BEGIN DOWNLOAD=============='
# download the latest build and put it in tmp
sudo wget $DEB_DOWNLOAD -O $DEB_FILE

echo "downloaded file from: " ${DEB_DOWNLOAD} "VERSION: " ${VERSION}

# THIS SECTION IS ONLY IF THERE IS NOT AN EXISTING DEB REPO
# create the packaging structure
# cd $TARGET_DIR
# mkdir -p conf

# create the distribution file with info, need to read more about this
#printf 'Origin: Rodeo\nLabel: Rodeo\nCodename: rodeo\nComponents: main\nArchitectures: amd64\nDescription: An IDE for doing data science\nSignWith:33D40BC6\n' > ./conf/distributions

# you need the yhat-dev secret gpg key listed in your keychain:
echo '==========BEGIN KEY STUFF=============='
sudo echo $SIGNING_KEY | base64 --decode | gpg --import -
echo 'imported key'
# sudo gpg --export-secret-keys | gpg2 --import -
echo 'finished key stuff'

echo '===============S3 STUFF==============='
# NOW, we must pull the current repo from AWS
echo 'pulling s3 repo'
sudo s3cmd get -r s3://${BUCKET}/

sudo rm -rf ./{db,dists,lists,pool}

echo 'updating repo with reprepro'
sudo reprepro -b . includedeb rodeo $DEB_FILE

tree . -D

# check the repo:
sudo s3cmd del -r --force s3://${BUCKET}/
sudo s3cmd sync -r . s3://${BUCKET}/ -P

echo 'removing keys'
sudo gpg --with-colons --fingerprint | grep "^fpr" | cut -d: -f10 | gpg --batch --delete-secret-keys
