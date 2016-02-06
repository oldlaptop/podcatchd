#! /bin/sh

# $1 should be the URL of the podcast RSS feed, $2 should be the podcast name.

# envvar PODCAST_DIR
#
# Directory in which the podcast should be deposited (will go in
# $PODCAST_DIR/$2/$2.$DATE.mp3)
export PODCAST_DIR="."

# envvar DATE
#
# Date to use in the podcast filename
export DATE=`date --iso-8601`

if [ ! -d $PODCAST_DIR/$2 ]
then
	mkdir -p $PODCAST_DIR/$2
fi

download_loop()
{
	while read url
	do
		line=$(echo "$url" | grep -o 'https\{0,1\}://.*$')
		if [ "$line" ]
		then
			echo "$line"
		fi
	done
}

rsstail -n 1 -eu "$1" | download_loop