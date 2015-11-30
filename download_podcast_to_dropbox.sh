#!/bin/bash
# Dropbox Uploader

SAVE_DIR=/home/user/some-dir/
UPLOAD_DIR=/some-dir-in-your-dropbox/
DROPBOX_UPLOADER=/path/to/your/dropbox_uploader.sh
DROPBOX_UPLOADER_CONFIG=/path/to/your/dropbox_uploader.conf

# Urls to monitor
urls="feed-url1,feed-url2,..."

# Split urls to monitor into an array
IFS=',' read -r -a urlArr <<< "$urls"

# Retrieve list of currently downloaded files with dropbox_uploader.sh
listStr=$($DROPBOX_UPLOADER -f $DROPBOX_UPLOADER_CONFIG list $UPLOAD_DIR)

# Check if new podcasts are availiable and download them to local pi storage
# Will need to split that up at some point since files could potentially be too big for the pis storage
for url in "${urlArr[@]}"
do
  str=$(wget -P $SAVE_DIR -q -O- $url | grep -o '<enclosure [^>]*url="[^"]*' | grep -o '[^"]*$' | head -n 1)
  str=${str##*/}
  
  # Replace url encoding spaces with real ones
  str=${str//%20/ }
  if [[ "$listStr" != *"$str"* ]]
  then
	# File isnt in dropbox yet, so download
	wget -P $SAVE_DIR -q -O- $url | grep -o '<enclosure [^>]*url="[^"]*' | grep -o '[^"]*$' | head -n 1 | xargs wget -c -P $SAVE_DIR > /dev/null
  fi
done

# Upload the downloaded files to dropbox using dropbox_uploader.sh
for file in $SAVE_DIR*
do
  $DROPBOX_UPLOADER -f $DROPBOX_UPLOADER_CONFIG -s upload "${file}" "${UPLOAD_DIR}"
done

# Clean tmp folder
rm -rf $SAVE_DIR*
