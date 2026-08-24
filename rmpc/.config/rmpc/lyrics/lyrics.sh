#!/usr/bin/env sh

LRCLIB_INSTANCE="https://lrclib.net"

if [ "$HAS_LRC" = "false" ]; then
    # Convert M:SS -> seconds
DURATION_SECONDS=$(
    printf '%s\n' "$DURATION" |
    awk -F: '{ print ($1 * 60) + $2 }'
)

echo "DURATION=$DURATION ($DURATION_SECONDS sec)" >> /tmp/rmpc-lyrics-debug
    
    mkdir -p "$(dirname "$LRC_FILE")"

    # Primary: exact track signature
RESPONSE="$(curl -sG \
    -H "Lrclib-Client: rmpc-$VERSION" \
    --data-urlencode "artist_name=$ARTIST" \
    --data-urlencode "track_name=$TITLE" \
    --data-urlencode "album_name=$ALBUM" \
    --data-urlencode "duration=$DURATION_SECONDS" \
    "$LRCLIB_INSTANCE/api/get")"

LYRICS="$(printf '%s' "$RESPONSE" | jq -r '
    select(.instrumental != true)
    | .syncedLyrics // empty
')"

# Fallback: search by title + match duration
# Fallback: search by track + artist, then title only
if [ -z "$LYRICS" ]; then

    echo "=== FALLBACK ===" >> /tmp/rmpc-lyrics-debug
    echo "TITLE=$TITLE" >> /tmp/rmpc-lyrics-debug
    echo "ARTIST=$ARTIST" >> /tmp/rmpc-lyrics-debug
    echo "DURATION=$DURATION ($DURATION_SECONDS sec)" >> /tmp/rmpc-lyrics-debug

    # 1. Search using track name + artist
    SEARCH_RESPONSE="$(curl -sG \
        -H "Lrclib-Client: rmpc-$VERSION" \
        --data-urlencode "track_name=$TITLE" \
        --data-urlencode "artist_name=$ARTIST" \
        "$LRCLIB_INSTANCE/api/search")"

    # 2. If that gives nothing useful, search by title only
    if ! printf '%s' "$SEARCH_RESPONSE" | jq -e \
        'any(.[]; .syncedLyrics != null and .syncedLyrics != "")' \
        >/dev/null 2>&1; then

        echo "--- TITLE SEARCH ---" >> /tmp/rmpc-lyrics-debug

        SEARCH_RESPONSE="$(curl -sG \
            -H "Lrclib-Client: rmpc-$VERSION" \
            --data-urlencode "q=$TITLE" \
            "$LRCLIB_INSTANCE/api/search")"
    fi

    # Debug results
    printf '%s' "$SEARCH_RESPONSE" |
        jq '.[] | {
            trackName,
            artistName,
            albumName,
            duration,
            instrumental,
            hasSyncedLyrics: (.syncedLyrics != null and .syncedLyrics != "")
        }' >> /tmp/rmpc-lyrics-debug

    # Pick the best match
    LYRICS="$(printf '%s' "$SEARCH_RESPONSE" |
    jq -r \
        --arg title "$TITLE" \
        --arg artist "$ARTIST" \
        --argjson duration "$DURATION_SECONDS" '
        [
            .[]
            | select(
                (.syncedLyrics != null)
                and
                (.syncedLyrics != "")
                and
                (.instrumental != true)
            )
            | . + {
                title_match: (
                    (.trackName | ascii_downcase)
                    == ($title | ascii_downcase)
                ),
                artist_match: (
                    (.artistName | ascii_downcase)
                    == ($artist | ascii_downcase)
                ),
                duration_diff: (
                    ((.duration // 999999) - $duration) | fabs
                )
            }
            | select(.title_match)
            | select(.duration_diff <= 2)
        ]
        | sort_by(
            (if .artist_match then 0 else 1 end),
            .duration_diff
        )
        | .[0].syncedLyrics // empty
    ')"
fi

    if [ -z "$LYRICS" ]; then
        rmpc remote --pid "$PID" status \
            "Lyrics for $ARTIST - $TITLE not found" \
            --level warn
        exit
    fi

    echo "[ar:$ARTIST]" > "$LRC_FILE"
    {
        echo "[al:$ALBUM]"
        echo "[ti:$TITLE]"
    } >> "$LRC_FILE"

    echo "$LYRICS" | sed -E '/^\[(ar|al|ti):/d' >> "$LRC_FILE"

    rmpc remote --pid "$PID" indexlrc --path "$LRC_FILE"

    rmpc remote --pid "$PID" status \
        "Downloaded lyrics for $ARTIST - $TITLE" \
        --level info
fi