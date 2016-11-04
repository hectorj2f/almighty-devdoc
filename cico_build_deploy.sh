#!/bin/bash

# Show command before executing
set -x

# We need to disable selinux for now, XXX
/usr/sbin/setenforce 0

# Get all the deps in
yum -y install \
  docker \
  make \
  git 
service docker start

# remove previous generated site
rm -rf _site

# Build builder image
docker build -t almighty-devdoc-builder -f Dockerfile .

# Build site
docker run --name=almighty-devdoc-builder -t -v $(pwd):/almighty-devdoc:Z almighty-devdoc-builder "jekyll build"

# TODO: Test ?

if [ $? -eq 0 ]; then
  echo 'CICO: unit tests OK'
else
  echo 'CICO: unit tests FAIL'
  exit 1
fi

# deploy to github pages
echo 'CICO: Deploying to github pages'
git checkout -b gh-pages origin/gh-pages

# delete everyting but _site and .git
# this is to ensure deleted files also
# gets removed.
find . -not -path "*/_site*" -not -path "*/.git*" -exec rm -rf {} \;

# Move over generated content to git 
cp -rfv _site/* .

echo "Dump ls"
pwd
ls -l

# Update new repo with generated code
git config user.name "ci.centos.org"
git config user.email "almighty-public@redhat.com"
git add --ignore-removal --all .

#TODO add more context to msg
git commit -m "Generated by ci.centos.org" 

# This seem to cause terminal to malfunction
# thus keeping it out for now
#git log -n1

echo "doing git push"
git push origin gh-pages

if [ $? -eq 0 ]; then
  echo 'CICO: deploy OK'
else
  echo 'CICO: deploy FAIL'
  exit 1
fi
