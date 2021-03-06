#! /bin/sh
set -e
# Copyright (c) 2016 Peter Piwowarski
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# A simple event loop to watch an RSS feed with rsstail and download any
# enclosures. Meant to be launched by podcatchd, but can work standalone.
# $1 should be the URL of the podcast RSS feed, $2 should be the podcast name.

. "$PODCATCHD_PATH/log.subr"

NAME="$2"
PODCAST_DIR="${PODCAST_DIR:-.}"

if [ ! -d "$PODCAST_DIR/$2" ]
then
	mkdir -p "$PODCAST_DIR/$NAME"
fi

download_loop()
{
	pid=$1
	feed=$2
	url=
	date=
	while read -r line
	do
		log "rsstail[$pid] for <$feed> said: $line"

		if [ "$(echo "$line" | grep "Pub\\.date")" ]
		then
			date="${line##Pub.date: }"
		fi

		if [ "$(echo "$line" | grep -o 'https\{0,1\}://.*$')" ]
		then
			url="${line##Enclosure URL: }"
		fi

		if [ "$url" ] && [ "$date" ]
		then
			# Stupidly strip all URL parameters for extension-sensing purposes
			url_noparams="${url%%\?*}"
			ext="$(echo "$url_noparams" | grep -o '\.[[:alnum:]]*$')" || true

			# Transform date to ISO format
			date="$(date -d "$date" "+%Y-%m-%d")"

			if [ ! -e "$PODCAST_DIR/$NAME/$NAME.$date$ext" ]
			then
				log "downloading $url to $PODCAST_DIR/$NAME/$NAME.$date$ext"
				curl -sSL "$url" -o "$PODCAST_DIR/$NAME/$NAME.$date$ext" 2>&1 | plog
			fi
			url=
			date=
		fi
	done
}

mkdir -m 700 "/tmp/podcatch.sh.$$"
mkfifo /tmp/podcatch.sh.$$/rss.fifo

rsstail -n 30 -Ppeu "$1" > /tmp/podcatch.sh.$$/rss.fifo 2>&1 & pids="$! $pids"
download_loop $! $1 < /tmp/podcatch.sh.$$/rss.fifo & pids="$! $pids"

trap 'kill $pids; rm -rf /tmp/podcatch.sh.$$' EXIT

wait
