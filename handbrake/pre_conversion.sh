#!/bin/sh
#
# This is an example of a post watch folder processing hook.  This script is
# always invoked with /bin/sh (shebang ignored).
#
# The argument of the script is the path to the watch folder.
#
# Location: /config/hooks/pre_conversion.sh
#

echo "[INFO(pre_conversion.sh)] => Running pre_conversion.sh"

mkdir -p '/storage/handbrake/Movies' '/storage/handbrake/Movies_NSFW' '/storage/handbrake/TV Shows' '/storage/handbrake/TV Shows_NSFW' '/storage/handbrake/Anime_Series' '/storage/handbrake/Anime_Movies'

WATCH_FOLDER_MOVIES=/storage/handbrake/Movies
WATCH_FOLDER_ANIME_MOVIES=/storage/handbrake/Anime_Movies
WATCH_FOLDER_NSFW=/storage/handbrake/Movies_NSFW

printf "[INFO(pre_conversion.sh)] => Initializing (dot folder removal) ... " && find /storage/media -type d -name '.*' -exec rm -rf {} + && printf "Done\n"

echo "[INFO(pre_conversion.sh)] => Running WATCH_FOLDER_MOVIES Section"

if [ "$(find "$WATCH_FOLDER_MOVIES" -type f -name "*.mp4" | wc -l)" -gt 0 ] || [ "$(find "$WATCH_FOLDER_ANIME_MOVIES" -type f -name "*.mp4" | wc -l)" -gt 0 ]; then
  find $WATCH_FOLDER_MOVIES -type f -name "*.mp4" | while read file; do
    # Get the absolute path of the file
    echo "[INFO(pre_conversion.sh)] => File: $file"
    name=$(basename "$file" .mp4)
    if [ "$file" == "*" ]; then
      continue
    elif [[ "$file" == *"imdb"* ]]; then
      continue
    fi
    echo "[INFO(pre_conversion.sh)] => Movie Name: $name"
    year=$(ffprobe -v quiet -print_format json -show_format -show_streams "$file" | jq -r '.format.tags.date' | cut -c 1-4)
    echo "[INFO(pre_conversion.sh)] => Movie Year: $year"
    format_name=${name// /+}

    # Check audio source/channel count
    audio_source_count=$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$file" | wc -l)
    audio_channel_count=$(ffprobe -v error -select_streams a:0 -show_entries stream=channels -of default=noprint_wrappers=1:nokey=1 "$file")

    query=$(curl -s "http://www.omdbapi.com/?apikey=$API_KEY&t=$format_name&y=$year")
    response=$(echo "$query" | jq -r '.Response')

    if [ "$response" == "False" ]; then
      query=$(curl -s "http://www.omdbapi.com/?apikey=$API_KEY&t=$format_name")
      echo "[INFO(pre_conversion.sh)] => API call: http://www.omdbapi.com/?apikey=$API_KEY&t=$format_name"
    else
      echo "[INFO(pre_conversion.sh)] => API call: http://www.omdbapi.com/?apikey=$API_KEY&t=$format_name&y=$year"
    fi
    imdb_id=$(echo "$query" | jq -r '.imdbID')
    year=$(echo "$query" | jq -r '.Year')
    # Rename the file with the new format
    echo "[INFO(pre_conversion.sh)] => Audio Count: $audio_count"
    if [[ "$audio_source_count" -eq 1 ]] && [[ "$audio_channel_count" -eq 2 ]]; then
        echo "[INFO(pre_conversion.sh)] => mv -f $file $WATCH_FOLDER_ANIME_MOVIES/$name ($year) [S] {imdb-$imdb_id}.mp4"
        mv -f "$file" "$WATCH_FOLDER_MOVIES/$name ($year) [S] {imdb-$imdb_id}.mp4"
    elif [[ "$audio_source_count" -eq 1 ]] && [[ "$audio_channel_count" -gt 2 ]]; then
        echo "[INFO(pre_conversion.sh)] => mv -f $file $WATCH_FOLDER_ANIME_MOVIES/$name ($year) [SR] {imdb-$imdb_id}.mp4"
        mv -f "$file" "$WATCH_FOLDER_MOVIES/$name ($year) [SR] {imdb-$imdb_id}.mp4"
    else
        echo "[INFO(pre_conversion.sh)] => mv -f $file $WATCH_FOLDER_ANIME_MOVIES/$name ($year) {imdb-$imdb_id}.mp4"
        mv -f "$file" "$WATCH_FOLDER_MOVIES/$name ($year) {imdb-$imdb_id}.mp4"
    fi
  done

  find $WATCH_FOLDER_ANIME_MOVIES -type f -name "*.mp4" | while read file; do
    # Get the absolute path of the file
    echo "[INFO(pre_conversion.sh)] => File: $file"
    name=$(basename "$file" .mp4)
    if [ "$file" == "*" ]; then
      continue
    elif [[ "$file" == *"imdb"* ]]; then
      continue
    fi
    echo "[INFO(pre_conversion.sh)] => Movie Name: $name"
    year=$(ffprobe -v quiet -print_format json -show_format -show_streams "$file" | jq -r '.format.tags.date' | cut -c 1-4)
    echo "[INFO(pre_conversion.sh)] => Movie Year: $year"
    format_name=${name// /+}

    query=$(curl -s "http://www.omdbapi.com/?apikey=$API_KEY&t=$format_name&y=$year")
    response=$(echo "$query" | jq -r '.Response')

    if [ "$response" == "False" ]; then
      query=$(curl -s "http://www.omdbapi.com/?apikey=$API_KEY&t=$format_name")
      echo "[INFO(pre_conversion.sh)] => API call: http://www.omdbapi.com/?apikey=$API_KEY&t=$format_name"
    else
      echo "[INFO(pre_conversion.sh)] => API call: http://www.omdbapi.com/?apikey=$API_KEY&t=$format_name&y=$year"
    fi
    imdb_id=$(echo "$query" | jq -r '.imdbID')
    year=$(echo "$query" | jq -r '.Year')
    # Rename the file with the new format
    echo "[INFO(pre_conversion.sh)] => mv -f $file $WATCH_FOLDER_ANIME_MOVIES/$name ($year) {imdb-$imdb_id}.mp4"
    mv -f "$file" "$WATCH_FOLDER_ANIME_MOVIES/$name ($year) {imdb-$imdb_id}.mp4"
  done
else
  echo "[INFO(pre_conversion.sh)] => $WATCH_FOLDER_MOVIES and $WATCH_FOLDER_ANIME_MOVIES has no mp4 files."
fi

contains_japanese_audio() {
    # Use ffprobe to analyze audio streams
    language=$(ffprobe -v error -select_streams a:0 -show_entries stream_tags=language -of default=noprint_wrappers=1:nokey=1 "$1")

    # Check if the language metadata contains "jpn" (Japanese)
    if [[ "$language" == *"jpn"* ]]; then
        return 0 # File contains Japanese audio
    else
        return 1 # File does not contain Japanese audio
    fi
}

echo "[INFO(pre_conversion.sh)] => Running WATCH_FOLDER_NSFW Section"

if [ -d "$WATCH_FOLDER_NSFW" ]; then
  # If it exists, cd into the directory
  cd "$WATCH_FOLDER_NSFW"
else
  # If it doesn't exist, exit with status code 1
  echo "[ERROR(pre_conversion.sh)] => Directory $WATCH_FOLDER_NSFW does not exist."
  exit 1
fi

mkdir -p output
for file in *.mp4; do
    name=$(basename "$file" .mp4)
    if [ "$name" == "*" ]; then
      continue
    fi
    echo "[INFO(pre_conversion.sh)] => File: $WATCH_FOLDER_NSFW/$file"
    if contains_japanese_audio "$file"; then
        continue
    fi

    echo "[INFO(pre_conversion.sh)] => Running ffmpeg ..." && ffmpeg -i "$file" -c copy -metadata:s:a:0 language=jpn -movflags +faststart "output/$file" > /dev/null 2>&1
    mv -f "output/$file" ./
done

rm -rf "output"

### PLEX REFRESH SECTION

printf "[INFO(pre_conversion.sh)] => Refreshing Plex Libraries ..."
curl -k -X POST -f -s "https://$PLEX_URL/library/sections/1/refresh?force=0&X-Plex-Token=$PLEX_TOKEN" || echo "[ERROR(pre_conversion.sh)] => Error Scanning Movies ..."
curl -k -X POST -f -s "https://$PLEX_URL/library/sections/29/refresh?force=0&X-Plex-Token=$PLEX_TOKEN" || echo "[ERROR(pre_conversion.sh)] => Error Scanning Movies_NSFW ..."
curl -k -X POST -f -s "https://$PLEX_URL/library/sections/2/refresh?force=0&X-Plex-Token=$PLEX_TOKEN" || echo "[ERROR(pre_conversion.sh)] => Error Scanning TV Shows ..."
printf " > DONE\n"
