#!/bin/bash

# Remote server access info
read -p "Username: "  user
read -p "Server: "  server
# Where to extractor to. (dont append a slash)
read -p "Local Distention: "  dest
# dest="/root/extractor"
# extractor folder at remote server (dont append a slash)
read -p "Remote files / folders: "  files
#files="/home/remote-user"
# Exclude pattern(s), see man rsync --exclude
exclude="**sites/default/files**"
# Oldest extractor to keep (as a power of 2 in days)
max="10"

# Create folder extractor
cd /root
mkdir extractor

# Create archive filename
date=$(date +%F)
file_archive="$server-$date";
# Print start status message.

echo $(date)
echo "Backing up locations: $server:$files to $dest/$file_archive"
echo

# extractor files. Full extractor. With compression
rsync -az --update --delete $user@$server:$files $dest/$file_archive --exclude $exclude 

# Print end status message.
echo "extractor $dest/$file_archive complete"
date
echo

# Calculate the previous move in the cycle
((day=$(date +%s)/86400))
for (( i=1; i<=$max/2; i=2*i ))
    do
    (( rotation=$day & i ))
    if [ "$rotation" -eq "0" ]
    then
        (( expired=$i*2 ))
        break
    else
        expired="4"
    fi
done


# Remove the expired extractors

expired_file=$server-$(date -d "$expired days ago" +%F)
echo "Attempting to remove expired extractor: $dest/$expired_file"
if [ -d $dest/$expired_file ]
then
    rm "$dest/$expired_file" -R
    #find $dest -name "$expired_file" -type d -delete
fi

# Finished
echo Complete!
