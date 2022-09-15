FROM lsiobase/ubuntu:focal
LABEL maintainer="huteri"

ENV TITLE="Automated Tv Show Trailer Downloader (ATTD)"
ENV TITLESHORT="ATTD"
ENV VERSION="0.1.0"

RUN \
	echo "************ install dependencies ************" && \
	echo "************ install & upgrade packages ************" && \
	apt-get update -y && \
	apt-get upgrade -y && \
	apt-get install -y --no-install-recommends \
	curl \
	jq \
	python3 \
	python3-pip \
	ffmpeg \
	mkvtoolnix && \
	rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/* && \
	echo "************ install python packages ************" && \
	python3 -m pip install --no-cache-dir -U \
	mutagen \
	yt-dlp

# copy local files
COPY root/ /

# set work directory
WORKDIR /config

# ports and volumes
VOLUME /config
