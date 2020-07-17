#!/bin/bash

# Stuff to make this work in cron
PATH="/bin:/usr/bin:/usr/local/bin:$PATH"  #Provide the path
cd "${0%/*}"       #Set working directory to location of this script

set -e  # stop script if error

# Sync all source packages from CRAN
rsync -tzm -i --no-links --dirs --delete --include="*.tar.gz" --exclude="*" cran.r-project.org::CRAN/src/contrib/ tarballs > logs/cransync_latest.log

# Sync tarballs only for Archive packages:
rsync -tzm -i --no-links --recursive --delete --include="*.tar.gz" --include="*/" --exclude="*" cran.r-project.org::CRAN/src/contrib/Archive tarballs > logs/cransync_archive.log
# Delete directories of removed packages
find tarballs/Archive/ -empty -type d -delete

# Unzip newly updated packages
echo "New/updated packages"
cat logs/cransync_latest.log | grep ">" | grep -o "\S*$" 
cat logs/cransync_latest.log | grep ">" | grep -o "\S*$" | xargs -i tar xfm tarballs/{} -C packages/


# Delete removed packages
ls -1 tarballs | grep -E -o "^[^_]+" | sort > tarballs.txt.tmp
ls -1 packages | sort > pkgs.txt.tmp
echo "Deleting packages\n" >> cransync_latest.log
comm tarballs.txt.tmp pkgs.txt.tmp -13 >> logs/cransync_latest.log
comm tarballs.txt.tmp pkgs.txt.tmp -13 | xargs -i rm -rf packages/{}
rm tarballs.txt.tmp pkgs.txt.tmp

cp logs/cransync_latest.log logs/cransync_`date "+%Y_%m_%d__%H_%M_%S"`.log
cp logs/cransync_archive.log logs/cransync_archive`date "+%Y_%m_%d__%H_%M_%S"`.log
