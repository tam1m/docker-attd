#!/usr/bin/with-contenv bash
Configuration () {
	processstartid="$(ps -A -o pid,cmd|grep "start.bash" | grep -v grep | head -n 1 | awk '{print $1}')"
	processdownloadid="$(ps -A -o pid,cmd|grep "download.bash" | grep -v grep | head -n 1 | awk '{print $1}')"
	echo "To kill script, use the following command:"
	echo "kill -9 $processstartid"
	echo "kill -9 $processdownloadid"
	echo ""
	echo ""
	sleep 2
	echo "############################################ $TITLE"
	echo "############################################ SCRIPT VERSION 1.2.5"
	echo "############################################ DOCKER VERSION $VERSION"
	echo "############################################ CONFIGURATION VERIFICATION"
	themoviedbapikey="3b7751e3179f796565d88fdb2fcdf426"
	error=0
	
	if [ "$AUTOSTART" == "true" ]; then
		echo "$TITLESHORT Script Autostart: ENABLED"
		if [ -z "$SCRIPTINTERVAL" ]; then
			echo "WARNING: $TITLESHORT Script Interval not set! Using default..."
			SCRIPTINTERVAL="15m"
		fi
		echo "$TITLESHORT Script Interval: $SCRIPTINTERVAL"
	else
		echo "$TITLESHORT Script Autostart: DISABLED"
	fi
	
	#Verify Sonarr Connectivity using v0.2 and v3 API url
	sonarrtestv02=$(curl -s "$SonarrUrl/api/system/status?apikey=${SonarrAPIkey}" | jq -r ".version")
	sonarrtestv3=$(curl -s "$SonarrUrl/api/v3/system/status?apikey=${SonarrAPIkey}" | jq -r ".version")
	if [ ! -z "$sonarrtestv02" ] || [ ! -z "$sonarrtestv3" ] ; then
		if [ "$sonarrtestv02" != "null" ]; then
			echo "Sonarr v0.2 API: Connection Valid, version: $sonarrtestv02"
		elif [ "$sonarrtestv3" != "null" ]; then
			echo "Sonarr v3 API: Connection Valid, version: $sonarrtestv3"
		else
			echo "ERROR: Cannot communicate with Sonarr, most likely a...."
			echo "ERROR: Invalid API Key: $SonarrAPIkey"
			error=1
		fi
	else
		echo "ERROR: Cannot communicate with Sonarr, no response"
		echo "ERROR: URL: $SonarrUrl"
		echo "ERROR: API Key: $SonarrAPIkey"
		error=1
	fi

	sonarrmovielist=$(curl -s --header "X-Api-Key:"${SonarrAPIkey} --request GET  "$SonarrUrl/api/v3/series")
	sonarrmovietotal=$(echo "${sonarrmovielist}"  | jq -r '.[] | select(.statistics.episodeFileCount>0) | .id' | wc -l)
	sonarrmovieids=($(echo "${sonarrmovielist}" | jq -r '.[] | select(.statistics.episodeFileCount>0) | .id'))
	
	echo "Sonarr: Verifying Movie Directory Access:"
	for id in ${!sonarrmovieids[@]}; do
		currentprocessid=$(( $id + 1 ))
		sonarrid="${sonarrmovieids[$id]}"
		sonarrmoviedata="$(echo "${sonarrmovielist}" | jq -r ".[] | select(.id==$sonarrid)")"
		sonarrmoviepath="$(echo "${sonarrmoviedata}" | jq -r ".path")"
		sonarrmovierootpath="$(dirname "$sonarrmoviepath")"
		if [ -d "$sonarrmovierootpath" ]; then
			echo "Sonarr: Root Media Folder Found: $sonarrmovierootpath"
			error=0
			break
		else
			echo "ERROR: Sonarr Root Media Folder not found, please verify you have the right volume configured, expecting path:"
			echo "ERROR: Expected volume path: $sonarrmovierootpath"
			error=1
			break
		fi
	done

	echo "youtube-dl: Checking for cookies.txt"
	if [ -f "/config/cookies/cookies.txt" ]; then
		echo "youtube-dl: /config/cookies/cookies.txt found!"
		cookies="--cookies /config/cookies/cookies.txt"
	else
		echo "WARNING: youtube-dl cookies.txt not found at the following location: /config/cookies/cookies.txt"
		echo "WARNING: not having cookies may result in failed downloads..."
		cookies=""
	fi

	# extrastype
	if [ ! -z "$extrastype" ]; then
		echo "Sonarr Extras Selection: $extrastype"
	else
		echo "WARNING: Sonarr Extras Selection not specified"
		echo "Sonarr Extras Selection: trailers"
		extrastype="trailers"
	fi
	
	# LANGUAGES
	if [ ! -z "$LANGUAGES" ]; then
		LANGUAGES="${LANGUAGES,,}"
		echo "Sonarr Extras Audio Languages: $LANGUAGES (first one found is used)"
	else
		LANGUAGES="en"
		echo "Sonarr Extras Audio Languages: $LANGUAGES (first one found is used)"
	fi
	
	# videoformat
	if [ ! -z "$videoformat" ]; then
		echo "Sonarr Extras Format Set To: $videoformat"
	else
		echo "Sonarr Extras Format Set To: --format bestvideo[vcodec*=avc1]+bestaudio"
		videoformat="--format bestvideo[vcodec*=avc1]+bestaudio"
	fi
	

	# subtitlelanguage
	if [ ! -z "$subtitlelanguage" ]; then
		subtitlelanguage="${subtitlelanguage,,}"
		echo "Sonarr Extras Subtitle Language: $subtitlelanguage"
	else
		subtitlelanguage="en"
		echo "Sonarr Extras Subtitle Language: $subtitlelanguage"
	fi

	if [ ! -z "$FilePermissions" ]; then
		echo "Sonarr Extras File Permissions: $FilePermissions"
	else
		echo "ERROR: FilePermissions not set, using default..."
		FilePermissions="666"
		echo "Sonarr Extras File Permissions: $FilePermissions"
	fi
	
	if [ ! -z "$FolderPermissions" ]; then
		echo "Sonarr Extras Foldder Permissions: $FolderPermissions"
	else
		echo "WARNING: FolderPermissions not set, using default..."
		FolderPermissions="766"
		echo "Sonarr Extras Foldder Permissions: $FolderPermissions"
	fi
	
	if [ ! -z "$SINGLETRAILER" ]; then
		if [ "$SINGLETRAILER" == "true" ]; then
			echo "Sonarr Single Trailer: ENABLED"
		else
			echo "Sonarr Single Trailer: DISABLED"
		fi
	else
		echo "WARNING: SINGLETRAILER not set, using default..."
		SINGLETRAILER="true"
		echo "Sonarr Single Trailer: ENABLED"
	fi
	
	if [ ! -z "$USEFOLDERS" ]; then
		if [ "$USEFOLDERS" == "true" ]; then
			echo "Sonarr Use Extras Folders: ENABLED"
		else
			echo "Sonarr Use Extras Folders: DISABLED"
		fi
	else
		echo "WARNING: USEFOLDERS not set, using default..."
		USEFOLDERS="true"
		echo "Sonarr Use Extras Folders: ENABLED"
	fi

	if [ ! -z "$PREFER_EXISTING" ]; then
		if [ "$PREFER_EXISTING" == "true" ]; then
			echo "Prefer Existing Trailer: ENABLED"
		else
			echo "Prefer Existing Trailer: DISABLED"
		fi
	else
		echo "WARNING: PREFER_EXISTING not set, using default..."
		PREFER_EXISTING="false"
		echo "Prefer Existing Trailer: DISABLED"
	fi

	if [ $error == 1 ]; then
		echo "ERROR :: Exiting..."
		exit 1
	fi
	sleep 2.5
}

DownloadTrailers () {
	echo "############################################ DOWNLOADING TRAILERS"
	for id in ${!sonarrmovieids[@]}; do
		currentprocessid=$(( $id + 1 ))
		sonarrid="${sonarrmovieids[$id]}"
		sonarrmoviedata="$(echo "${sonarrmovielist}" | jq -r ".[] | select(.id==$sonarrid)")"
		sonarrmovietitle="$(echo "${sonarrmoviedata}" | jq -r ".title")"
		themoviedbmovieimdbid="$(echo "${sonarrmoviedata}" | jq -r ".tvdbId")"

		themoviedbmovieidapicall=$(curl -s "https://api.themoviedb.org/3/find/${themoviedbmovieimdbid}?api_key=${themoviedbapikey}&language=en-US&external_source=tvdb_id")
		themoviedbmovieid=($(echo "$themoviedbmovieidapicall" | jq -r ".tv_results[0] | .id"))
		
		if [ -f "/config/cache/${themoviedbmovieid}-complete" ]; then
			if [[ $(find "/config/cache/${themoviedbmovieid}-complete" -mtime +7 -print) ]]; then
				echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle :: Checking for changes..."
				rm "/config/cache/${themoviedbmovieid}-complete"
			else
				echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle :: All videos already downloaded, skipping..."
				continue
			fi
		fi
		sonarrmoviepath="$(echo "${sonarrmoviedata}" | jq -r ".path")"
		if [ ! -d "$sonarrmoviepath" ]; then
			echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle :: ERROR: Movie Path does not exist, Skipping..."
			continue
		fi
		sonarrmovieyear="$(echo "${sonarrmoviedata}" | jq -r ".year")"
		sonarrmoviegenre="$(echo "${sonarrmoviedata}" | jq -r ".genres | .[]" | head -n 1)"
		sonarrmoviefolder="$(basename "${sonarrmoviepath}")"
		echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle"
		
		
		IFS=',' read -r -a filters <<< "$LANGUAGES"
		for filter in "${filters[@]}"
		do
			echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle :: Searching for \"$filter\" extras..."
			themoviedbvideoslistdata=$(curl -s "https://api.themoviedb.org/3/tv/${themoviedbmovieid}/videos?api_key=${themoviedbapikey}&language=$filter")
			echo $themoviedbvideoslistdata

			if [ "$extrastype" == "all" ]; then
				themoviedbvideoslistids=($(echo "$themoviedbvideoslistdata" | jq -r ".results[] |  select(.site==\"YouTube\" and .iso_639_1==\"$filter\") | .id"))
			else
				themoviedbvideoslistids=($(echo "$themoviedbvideoslistdata" | jq -r ".results[] |  select(.site==\"YouTube\" and .iso_639_1==\"$filter\" and .type==\"Trailer\") | .id"))
			fi
			themoviedbvideoslistidscount=$(echo "$themoviedbvideoslistdata" | jq -r ".results[] |  select(.site==\"YouTube\" and .iso_639_1==\"$filter\") | .id" | wc -l)
			if [ -z "$themoviedbvideoslistids" ]; then
				echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle :: None found..."
				continue
			else
				break
			fi
		done
		
		if [ -z "$themoviedbvideoslistids" ]; then
			echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle :: ERROR: No Extras in wanted languages found, Skipping..."
			if [ -f "/config/logs/NotFound.log" ]; then
				if cat "/config/logs/NotFound.log" | grep -i ":: $sonarrmovietitle ::" | read; then
					sleep 0.1
				else
					echo "No Trailer Found :: $sonarrmovietitle :: themoviedb missing Youtube Trailer ID"  >> "/config/logs/NotFound.log"
				fi
			else
				echo "No Trailer Found :: $sonarrmovietitle :: themoviedb Missing Youtube Trailer ID"  >> "/config/logs/NotFound.log"
			fi
			continue
		fi

		echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle :: $themoviedbvideoslistidscount Extras Found!"

		for id in ${!themoviedbvideoslistids[@]}; do

			currentsubprocessid=$(( $id + 1 ))
			themoviedbvideoid="${themoviedbvideoslistids[$id]}"
			themoviedbvideodata="$(echo "$themoviedbvideoslistdata" | jq -r ".results[] | select(.id==\"$themoviedbvideoid\") | .")"
			themoviedbvidelanguage="$(echo "$themoviedbvideodata" | jq -r ".iso_639_1")"
			themoviedbvidecountry="$(echo "$themoviedbvideodata" | jq -r ".iso_3166_1")"
			themoviedbvidekey="$(echo "$themoviedbvideodata" | jq -r ".key")"
			themoviedbvidename="$(echo "$themoviedbvideodata" | jq -r ".name")"
			themoviedbvidetype="$(echo "$themoviedbvideodata" | jq -r ".type")"
			youtubeurl="https://www.youtube.com/watch?v=$themoviedbvidekey"
			sanatizethemoviedbvidename="$(echo "${themoviedbvidename}" | sed -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g'  -e "s/  */ /g")"
								
			if [ "$themoviedbvidetype" == "Featurette" ]; then
				if [ "$USEFOLDERS" == "true" ]; then
					folder="Featurettes"
				else
					folder="Featurette"
				fi
			elif [ "$themoviedbvidetype" == "Trailer" ]; then
				if [ "$USEFOLDERS" == "true" ]; then
					folder="Trailers"
				else
					folder="Trailer"
				fi
			elif [ "$themoviedbvidetype" == "Behind the Scenes" ]; then
				folder="Behind The Scenes"
			elif [ "$themoviedbvidetype" == "Clip" ]; then
				if [ "$USEFOLDERS" == "true" ]; then
					folder="Scenes"
				else
					folder="Scene"
				fi
			elif [ "$themoviedbvidetype" == "Bloopers" ]; then
				if [ "$USEFOLDERS" == "true" ]; then
					folder="Shorts"
				else
					folder="Short"
				fi
			elif [ "$themoviedbvidetype" == "Teaser" ]; then
				folder="Other"
			fi				
			
			echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename"
			
			if [ "$USEFOLDERS" == "true" ]; then
				if [ "$SINGLETRAILER" == "true" ]; then
					if [ "$themoviedbvidetype" == "Trailer" ]; then
						if find "$sonarrmoviepath/$folder" -name "*.mkv" | read; then
							echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: Existing Trailer found, skipping..."
							continue
						fi
					fi
				fi
				if [ "$PREFER_EXISTING" == "true" ]; then
					# Check for existing manual trailer
					if [ "$themoviedbvidetype" == "Trailer" ]; then
						if find "$sonarrmoviepath/$folder" -name "*.*" | read; then
							echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: Existing Manual Trailer found, skipping..."
							continue
						fi
					fi
				fi
				outputfile="$sonarrmoviepath/$folder/$sanatizethemoviedbvidename.mkv"
			else
				if [[ -d "$sonarrmoviepath/${folder}s" || -d "$sonarrmoviepath/${folder}" ]]; then
					if [ "$themoviedbvidetype" == "Behind the Scenes" ]; then
						rm -rf "$sonarrmoviepath/${folder}"
					else
						rm -rf "$sonarrmoviepath/${folder}s"
					fi
				fi
				folder="$(echo "${folder,,}" | sed 's/ *//g')"
				if [ "$SINGLETRAILER" == "true" ]; then
					if [ "$themoviedbvidetype" == "Trailer" ]; then
						if find "$sonarrmoviepath" -name "*-trailer.mkv" | read; then
							echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: Existing Trailer found, skipping..."
							continue
						fi
					fi
				fi

				if [ "$PREFER_EXISTING" == "true" ]; then
					if [ "$themoviedbvidetype" == "Trailer" ]; then
						# Check for existing manual trailer
						if find "$sonarrmoviepath" -name "*-trailer.*" | read; then
							echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: Existing Manual Trailer found, skipping..."
							continue
						fi
					fi
				fi
				outputfile="$sonarrmoviepath/$sanatizethemoviedbvidename-$folder.mkv"
			fi			
			
			if [ -f "$outputfile" ]; then
				echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: Trailer already Downloaded..."
				continue
			fi
			
			if [ ! -d "/config/temp" ]; then
				mkdir -p /config/temp
			else
				rm -rf /config/temp
				mkdir -p /config/temp
			fi
			tempfile="/config/temp/download"

			echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: Sending Trailer link to youtube-dl..."
			echo "=======================START YOUTUBE-DL========================="
			youtube-dl ${cookies} -o "$tempfile" ${videoformat} --write-sub --sub-lang $subtitlelanguage --embed-subs --merge-output-format mkv --no-mtime --geo-bypass "$youtubeurl"
			echo "========================STOP YOUTUBE-DL========================="
			if [ -f "$tempfile.mkv" ]; then
				audiochannels="$(ffprobe -v quiet -print_format json -show_streams "$tempfile.mkv" | jq -r ".[] | .[] | select(.codec_type==\"audio\") | .channels")"
				width="$(ffprobe -v quiet -print_format json -show_streams "$tempfile.mkv" | jq -r ".[] | .[] | select(.codec_type==\"video\") | .width")"
				height="$(ffprobe -v quiet -print_format json -show_streams "$tempfile.mkv" | jq -r ".[] | .[] | select(.codec_type==\"video\") | .height")"
				if [[ "$width" -ge "3800" || "$height" -ge "2100" ]]; then
					videoquality=3
					qualitydescription="UHD"
				elif [[ "$width" -ge "1900" || "$height" -ge "1060" ]]; then
					videoquality=2
					qualitydescription="FHD"
				elif [[ "$width" -ge "1260" || "$height" -ge "700" ]]; then
					videoquality=1
					qualitydescription="HD"
				else
					videoquality=0
					qualitydescription="SD"
				fi

				if [ "$audiochannels" -ge "3" ]; then
					channelcount=$(( $audiochannels - 1 ))
					audiodescription="${audiochannels}.1 Channel"
				elif [ "$audiochannels" == "2" ]; then
					audiodescription="Stereo"
				elif [ "$audiochannels" == "1" ]; then
					audiodescription="Mono"
				fi

				echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: TRAILER DOWNLOAD :: Complete!"
				echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: TRAILER :: Extracting thumbnail with ffmpeg..."
				echo "========================START FFMPEG========================"
				ffmpeg -y \
					-ss 10 \
					-i "$tempfile.mkv" \
					-frames:v 1 \
					-vf "scale=640:-2" \
					"/config/temp/cover.jpg"
				echo "========================STOP FFMPEG========================="
				echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: Updating File Statistics via mkvtoolnix (mkvpropedit)..."
				echo "========================START MKVPROPEDIT========================"
				mkvpropedit "$tempfile.mkv" --add-track-statistics-tags
				echo "========================STOP MKVPROPEDIT========================="
				echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: TRAILER :: Embedding metadata with ffmpeg..."
				echo "========================START FFMPEG========================"
				mv "$tempfile.mkv" "$tempfile-temp.mkv"
				ffmpeg -y \
					-i "$tempfile-temp.mkv" \
					-c copy \
					-metadata TITLE="${themoviedbvidename}" \
					-metadata DATE_RELEASE="$sonarrmovieyear" \
					-metadata GENRE="$sonarrmoviegenre" \
					-metadata ENCODED_BY="AMTD" \
					-metadata CONTENT_TYPE="Movie $folder" \
					-metadata:s:v:0 title="$qualitydescription" \
					-metadata:s:a:0 title="$audiodescription" \
					-attach "/config/temp/cover.jpg" -metadata:s:t mimetype=image/jpeg \
					"$tempfile.mkv"
				echo "========================STOP FFMPEG========================="
				if [ -f "$tempfile.mkv" ]; then
					echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: TRAILER :: Metadata Embedding Complete!"
					if [ -f "$tempfile-temp.mkv" ]; then
						rm "$tempfile-temp.mkv"
					fi
				else
					echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: TRAILER :: ERROR: Metadata Embedding Failed!"
					mv "$tempfile-temp.mkv" "$tempfile.mkv"
				fi
				
				if [ -f "$tempfile.mkv" ]; then
					if [ "$USEFOLDERS" == "false" ]; then
						mv "$tempfile.mkv" "$outputfile"
						chmod $FilePermissions "$outputfile"
						chown abc:abc "$outputfile"
					else
						if [ ! -d "$sonarrmoviepath/$folder" ]; then
							mkdir -p "$sonarrmoviepath/$folder"
							chmod $FolderPermissions "$sonarrmoviepath/$folder"
							chown abc:abc "$sonarrmoviepath/$folder"
						fi
						if [ -d "$sonarrmoviepath/$folder" ]; then
							mv "$tempfile.mkv" "$outputfile"
							chmod $FilePermissions "$outputfile"
							chown abc:abc "$outputfile"
						fi
					fi
				fi
				echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: Complete!"
			else
				echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: TRAILER DOWNLOAD :: ERROR :: Skipping..."
			fi
			
			if [ -d "/config/temp" ]; then
				rm -rf /config/temp
			fi
		done
		if [ "$USEFOLDERS" == "true" ]; then
			trailercount="$(find "$sonarrmoviepath" -mindepth 2 -type f -iname "*.mkv" | wc -l)"
		else
			trailercount="$(find "$sonarrmoviepath" -mindepth 1 -type f -regex '.*\(-trailer.mkv\|-scene.mkv\|-short.mkv\|-featurette.mkv\|-other.mkv\|-behindthescenes.mkv\)' | wc -l)"
		fi
		
		echo "$currentprocessid of $sonarrmovietotal :: $sonarrmovietitle :: $trailercount Extras Downloaded!"
		if [ "$trailercount" -ne "0" ]; then
			touch "/config/cache/${themoviedbmovieid}-complete"
		fi

	done
	if [ "$USEFOLDERS" == "true" ]; then
		trailercount="$(find "$sonarrmovierootpath" -mindepth 3 -type f -iname "*.mkv" | wc -l)"
	else
		trailercount="$(find "$sonarrmovierootpath" -mindepth 2 -type f -regex '.*\(-trailer.mkv\|-scene.mkv\|-short.mkv\|-featurette.mkv\|-other.mkv\|-behindthescenes.mkv\)' | wc -l)"
	fi
	echo "############################################ $trailercount TRAILERS DOWNLOADED"
	echo "############################################ SCRIPT COMPLETE"
	if [ "$AUTOSTART" == "true" ]; then
		echo "############################################ SCRIPT SLEEPING FOR $SCRIPTINTERVAL"
	fi
}

Configuration
DownloadTrailers

exit 0
