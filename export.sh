#!/bin/sh

if [ ! $1 -o ! $2 ]; then
    echo "Usage: export.sh <OAuth Access Token> <Directory>"
    exit 1
fi

# Your Yammer OAuth 2 Access Token. This must be a token for a verified admin account.
AT=$1

# Download location for the export files.
DIR=$2
cd $DIR

# Find the last export if there is one. The start date and time of the previous export 
# is encoded in the filename in UNIX time (http://en.wikipedia.org/wiki/Unix_time).
LAST_EXPORT=`ls export-*.zip | sed -e 's/export-\(.*\)\.zip/\1/g' | sort -n | tail -1`

# Check to see if a previous export was done.
if [ ! $LAST_EXPORT ]; then
    # No previous export was done. Start at the beginning of time (or 1970, which is 
    # close enough given Yammer's age).
    LAST_EXPORT=0
fi

# Convert UNIX time to ISO-8601 time, which the API endpoint accepts.
DATE=`date -j -r $LAST_EXPORT "+%Y-%m-%dT%H:%M:%S%z"`

# Calculate the current date in UNIX time for the filename of the export.
NEXT_EXPORT=`date "+%s"`

# Perform the next export. Send the OAuth 2 access token and store the UNIX time of this 
# export in the filename.
wget -O export-$NEXT_EXPORT.zip \
     -t 1 \
     --header "Authorization: Bearer $AT" \
     "https://www.staging.yammer.com/api/v1/export?since=$DATE"

# Verify that the download completed successfully.
if [ $? != 0 ]; then
    echo "Download failed...cleaning up."
    rm export-$NEXT_EXPORT.zip
    exit 1
fi

# Verify the contents of the zip file.
unzip -t export-$NEXT_EXPORT.zip >/dev/null 2>&1
if [ $? != 0 ]; then
    echo "Invalid ZIP file detected, export failed...removing downloaded ZIP"
    rm export-$NEXT_EXPORT.zip
    exit 1
fi
