# AMTD - Automated TV Show Trailer Downloader 
[![Docker Build](https://img.shields.io/docker/cloud/automated/huteri/attd?style=flat-square)](https://hub.docker.com/r/huteri/attd)
[![Docker Pulls](https://img.shields.io/docker/pulls/huteri/attd?style=flat-square)](https://hub.docker.com/r/huteri/attd)
[![Docker Stars](https://img.shields.io/docker/stars/huteri/attd?style=flat-square)](https://hub.docker.com/r/huteri/attd)
[![Docker Hub](https://img.shields.io/badge/Open%20On-DockerHub-blue?style=flat-square)](https://hub.docker.com/r/huteri/attd)

Modified version of AMTD to make it work with sonarr. Tested only on plex.

## Features
* Downloading **TV Shows Trailers** and **Extras** using online sources for use in popular applications (Plex/Kodi/Emby/Jellyfin): 
  * Connects to Sonarr to automatically download trailers for Movies in your existing library
  * Downloads videos using youtube-dl automatically
  * Names videos correctly to match Plex/Emby naming convention (Emby not tested)
  * Embeds relevant metadata into each video
  

### Plex Example
![](https://raw.githubusercontent.com/RandomNinjaAtk/docker-amtd/master/.github/amvtd-plex-example.jpg)


## Supported Architectures

The architectures supported by this image are:

| Architecture | Tag |
| :----: | --- |
| x86-64 | master |

## Version Tags

| Tag | Description |
| :----: | --- |
| master | Newest release code |


## Parameters

Container images are configured using parameters passed at runtime (such as those above). These parameters are separated by a colon and indicate `<external>:<internal>` respectively. For example, `-p 8080:80` would expose port `80` from inside the container to be accessible from the host's IP on port `8080` outside the container.

| Parameter | Function |
| --- | --- |
| `-e PUID=1000` | for UserID - see below for explanation |
| `-e PGID=1000` | for GroupID - see below for explanation |
| `-v /config` | Configuration files for AMTD. |
| `-v /change/me/to/match/sonarr` | Configure this volume to match your Sonarr Sonarr's volume mappings associated with Sonarr's Library Root Folder settings |
| `-e AUTOSTART=true` | true = Enabled :: Runs script automatically on startup |
| `-e SCRIPTINTERVAL=1h` | #s or #m or #h or #d :: s = seconds, m = minutes, h = hours, d = days :: Amount of time between each script run, when AUTOSTART is enabled|
| `-e SonarrUrl=http://x.x.x.x:8989` | Set domain or IP to your Sonarr instance including port. If using reverse proxy, do not use a trailing slash. Ensure you specify http/s. |
| `-e SonarrAPIkey=08d108d108d108d108d108d108d108d1` | Sonarr API key. |
| `-e extrastype=all` | all or trailers :: all downloads all available videos (trailers, clips, featurette, etc...) :: trailers only downloads trailers |
| `-e LANGUAGES=en,de` | Set the primary desired language, if not found, fallback to next langauge in the list... (this is a "," separated list of ISO 639-1 language codes) |
| `-e videoformat="--format bestvideo[vcodec*=avc1]+bestaudio"` | For guidence, please see youtube-dl documentation |
| `-e subtitlelanguage=en` | Desired Language Code :: For guidence, please see youtube-dl documentation. |
| `-e USEFOLDERS=true` | true = enabled :: Creates subfolders within the movie folder for extras | DEFAULT is true

| `-e PREFER_EXISTING=false` | true = enabled :: Checks for existing "trailer" file, and skips it if found |
| `-e SINGLETRAILER=true` | true = enabled :: Only downloads the first available trailer, does not apply to other extras type |
| `-e FilePermissions=644` | Based on chmod linux permissions |
| `-e FolderPermissions=755` | Based on chmod linux permissions |

### docker

```
docker create \
  --name=attd \
  -v /path/to/config/files:/config \
  -v /change/me/to/match/sonarr:/change/me/to/match/sonarr \
  -e PUID=1000 \
  -e PGID=1000 \
  -e AUTOSTART=true \
  -e SCRIPTINTERVAL=1h \
  -e extrastype=all \
  -e LANGUAGES=en,de \
  -e videoformat="--format bestvideo[vcodec*=avc1]+bestaudio" \
  -e subtitlelanguage=en \
  -e USEFOLDERS=false \
  -e PREFER_EXISTING=false \
  -e SINGLETRAILER=true \
  -e FilePermissions=644 \
  -e FolderPermissions=755 \
  -e SonarrUrl=http://x.x.x.x:8989 \
  -e SonarrAPIkey=SONARRAPIKEY \
  --restart unless-stopped \
  huteri/attd 
```


### docker-compose

Compatible with docker-compose v2 schemas.

```
version: "2.1"
services:
  amd:
    image: huteri/attd
    container_name: attd
    volumes:
      - /path/to/config/files:/config
      - /change/me/to/match/sonarr:/change/me/to/match/sonarr
    environment:
      - PUID=1000
      - PGID=1000
      - AUTOSTART=true
      - SCRIPTINTERVAL=1h
      - extrastype=all
      - LANGUAGES=en,de
      - videoformat=--format bestvideo[vcodec*=avc1]+bestaudio
      - subtitlelanguage=en
      - USEFOLDERS=false
      - SINGLETRAILER=true
      - PREFER_EXISTING=false
      - FilePermissions=644
      - FolderPermissions=755
      - SonarrUrl=http://x.x.x.x:8989
      - SonarrAPIkey=SONARRAPIKEY
    restart: unless-stopped
```

# Script Information
* Script will automatically run when enabled, if disabled, you will need to manually execute with the following command:
  * From Host CLI: `docker exec -it attd /bin/bash -c 'bash /config/scripts/download.bash'`
  * From Docker CLI: `bash /config/scripts/download.bash`
  
## Directories:
* <strong>/config/scripts</strong>
  * Contains the scripts that are run
* <strong>/config/logs</strong>
  * Contains the log output from the script
* <strong>/config/cache</strong>
  * Contains the artist data cache to speed up processes
* <strong>/config/coookies</strong>
  * Store your cookies.txt file in this location, may be required for youtube-dl to work properly
  
  
<br />
<br />
<br />
  
 
# Credits
- [ffmpeg](https://ffmpeg.org/)
- [youtube-dl](https://ytdl-org.github.io/youtube-dl/index.html)
- [Sonarr](https://sonarr.video/)
- [The Movie Database](https://www.themoviedb.org/)
- Icons made by <a href="http://www.freepik.com/" title="Freepik">Freepik</a> from <a href="https://www.flaticon.com/" title="Flaticon"> www.flaticon.com</a>
