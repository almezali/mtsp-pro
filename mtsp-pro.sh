#!/bin/bash

# MTSP - Music Terminal Shell Player
# Enhanced Version with Library Scanning and Metadata Management
# Dependencies: mpv, socat, jq, dialog, sqlite3, python3-mutagen, xdotool

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# General variables
MUSIC_DIR="$HOME/Music"
CURRENT_TRACK=""
IS_PLAYING=0
REPEAT_MODE=0
SHUFFLE_MODE=0
PLAYLIST=()
HISTORY=()
PLAYLISTS_DIR="$HOME/.mtsp/playlists"
CONFIG_DIR="$HOME/.mtsp"
DATABASE="$CONFIG_DIR/music_library.db"
CURRENT_PLAYLIST=""
VOLUME=100
PLAYER_PID=""

# Metadata Extraction Python Script
METADATA_SCRIPT="$CONFIG_DIR/extract_metadata.py"

# Show banner
show_banner() {
    clear
    echo -e "${BLUE}${BOLD}MTSP - Music Terminal Shell Player${NC}"
    echo -e "${GREEN}Welcome to your terminal music player!${NC}"
}

# Set up necessary directories and database
setup_environment() {
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$PLAYLISTS_DIR"
    touch "$CONFIG_DIR/history.txt"
    
    # Create metadata extraction script
    cat > "$METADATA_SCRIPT" << EOL
#!/usr/bin/env python3
import sys
import json
from mutagen.easyid3 import EasyID3
from mutagen.flac import FLAC
from mutagen.mp4 import MP4
from mutagen.oggvorbis import OggVorbis
import os

def extract_metadata(filepath):
    try:
        filename = os.path.basename(filepath)
        extension = os.path.splitext(filepath)[1].lower()
        
        metadata = {
            'filepath': filepath,
            'filename': filename,
            'artist': 'Unknown Artist',
            'album': 'Unknown Album',
            'title': filename,
            'duration': 0
        }
        
        if extension == '.mp3':
            audio = EasyID3(filepath)
            metadata['artist'] = audio.get('artist', ['Unknown Artist'])[0]
            metadata['album'] = audio.get('album', ['Unknown Album'])[0]
            metadata['title'] = audio.get('title', [filename])[0]
        
        elif extension == '.flac':
            audio = FLAC(filepath)
            metadata['artist'] = audio.get('artist', ['Unknown Artist'])[0]
            metadata['album'] = audio.get('album', ['Unknown Album'])[0]
            metadata['title'] = audio.get('title', [filename])[0]
        
        elif extension in ['.m4a', '.mp4']:
            audio = MP4(filepath)
            metadata['artist'] = audio.get('\xa9ART', ['Unknown Artist'])[0]
            metadata['album'] = audio.get('\xa9alb', ['Unknown Album'])[0]
            metadata['title'] = audio.get('\xa9nam', [filename])[0]
        
        elif extension == '.ogg':
            audio = OggVorbis(filepath)
            metadata['artist'] = audio.get('artist', ['Unknown Artist'])[0]
            metadata['album'] = audio.get('album', ['Unknown Album'])[0]
            metadata['title'] = audio.get('title', [filename])[0]
        
        # Get duration
        import mutagen
        track = mutagen.File(filepath)
        metadata['duration'] = int(track.info.length)
        
        return json.dumps(metadata)
    except Exception as e:
        return json.dumps({'error': str(e)})

if __name__ == '__main__':
    print(extract_metadata(sys.argv[1]))
EOL
    chmod +x "$METADATA_SCRIPT"

    # Initialize SQLite Database
    sqlite3 "$DATABASE" << EOL
CREATE TABLE IF NOT EXISTS tracks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    filepath TEXT UNIQUE,
    filename TEXT,
    artist TEXT,
    album TEXT,
    title TEXT,
    duration INTEGER,
    last_played DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS playlists (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS playlist_tracks (
    playlist_id INTEGER,
    track_id INTEGER,
    FOREIGN KEY(playlist_id) REFERENCES playlists(id),
    FOREIGN KEY(track_id) REFERENCES tracks(id),
    UNIQUE(playlist_id, track_id)
);
EOL
}

# Check for dependencies
check_dependencies() {
    local missing_deps=0
    local deps=("mpv" "socat" "jq" "dialog" "xdotool" "sqlite3" "python3")
    local python_libs=("mutagen")

    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${RED}Error: $cmd is not installed${NC}"
            missing_deps=1
        fi
    done
    
    # Check Python library
    for lib in "${python_libs[@]}"; do
        if ! python3 -c "import $lib" &> /dev/null; then
            echo -e "${RED}Error: Python $lib library is not installed${NC}"
            missing_deps=1
        fi
    done
    
    if [ $missing_deps -eq 1 ]; then
        echo -e "${YELLOW}Please install the missing dependencies:${NC}"
        echo "sudo apt-get install mpv socat jq dialog xdotool sqlite3 python3-mutagen"
        exit 1
    fi
}

# Play music using mpv
play_music() {
    local track="$1"
    
    # Stop any existing player
    if [ -n "$PLAYER_PID" ]; then
        kill "$PLAYER_PID" 2>/dev/null
    fi
    
    # Start new player
    mpv --no-video "$track" &
    PLAYER_PID=$!
    
    # Update current track and playing status
    CURRENT_TRACK="$track"
    IS_PLAYING=1
    
    # Update play history
    echo "$track" >> "$CONFIG_DIR/history.txt"
    
    # Update last played in database
    sqlite3 "$DATABASE" "UPDATE tracks SET last_played = CURRENT_TIMESTAMP WHERE filepath = '$track';"
    
    # Show now playing information
    local metadata=$(python3 "$METADATA_SCRIPT" "$track")
    local artist=$(echo "$metadata" | jq -r '.artist')
    local title=$(echo "$metadata" | jq -r '.title')
    
    dialog --title "Now Playing" --msgbox "Artist: $artist\nTitle: $title" 8 40
}

# Toggle playback (play/pause)
toggle_playback() {
    if [ $IS_PLAYING -eq 0 ]; then
        if [ -n "$CURRENT_TRACK" ]; then
            play_music "$CURRENT_TRACK"
        else
            dialog --msgbox "No track selected. Browse and play a track first." 6 40
        fi
    else
        # Pause/resume
        pkill -SIGSTOP mpv
        IS_PLAYING=0
    fi
}

# Next track functionality
next_track() {
    if [ -z "$CURRENT_PLAYLIST" ]; then
        # If no playlist, get random track
        local track=$(sqlite3 "$DATABASE" "SELECT filepath FROM tracks ORDER BY RANDOM() LIMIT 1;")
        play_music "$track"
    else
        dialog --msgbox "Playlist navigation not implemented yet." 6 40
    fi
}

# Previous track functionality
previous_track() {
    # Check history file for previous track
    if [ -s "$CONFIG_DIR/history.txt" ]; then
        local prev_track=$(tail -n 2 "$CONFIG_DIR/history.txt" | head -n 1)
        play_music "$prev_track"
    else
        dialog --msgbox "No previous track found." 6 40
    fi
}

# Browse files
browse_files() {
    local files=$(find "$MUSIC_DIR" -type f \( -name "*.mp3" -o -name "*.flac" -o -name "*.ogg" -o -name "*.m4a" \))
    local options=()
    local counter=1
    
    while IFS= read -r file; do
        options+=("$counter" "$file")
        ((counter++))
    done <<< "$files"
    
    local selected
    selected=$(dialog --title "Browse Music Files" \
                      --menu "Select a track:" \
                      20 70 15 \
                      "${options[@]}" \
                      2>&1 >/dev/tty)
    
    if [ $? -eq 0 ]; then
        local selected_file=$(echo "$files" | sed -n "${selected}p")
        play_music "$selected_file"
    fi
}

# Manage playlists (stub function)
manage_playlists() {
    dialog --msgbox "Playlist management not implemented yet." 6 40
}

# Show play history
show_history() {
    if [ -s "$CONFIG_DIR/history.txt" ]; then
        dialog --title "Play History" --textbox "$CONFIG_DIR/history.txt" 20 70
    else
        dialog --msgbox "No play history found." 6 40
    fi
}

# Change volume
change_volume() {
    local direction="$1"
    
    if [ "$direction" = "+" ] && [ $VOLUME -lt 200 ]; then
        VOLUME=$((VOLUME + 10))
    elif [ "$direction" = "-" ] && [ $VOLUME -gt 0 ]; then
        VOLUME=$((VOLUME - 10))
    fi
    
    # Send volume command to mpv
    if [ -n "$PLAYER_PID" ]; then
        kill -CONT "$PLAYER_PID"  # Ensure player is running
        socat - /tmp/mpv.sock <<< "{ \"command\": [\"set_property\", \"volume\", $VOLUME] }"
    fi
    
    dialog --msgbox "Volume: $VOLUME%" 6 20
}

# Scan music library
scan_library() {
    local supported_formats=("mp3" "wav" "flac" "ogg" "m4a")
    local files=()
    
    # Find supported audio files
    for format in "${supported_formats[@]}"; do
        while IFS= read -r -d '' file; do
            files+=("$file")
        done < <(find "$MUSIC_DIR" -type f -iname "*.$format" -print0)
    done
    
    # Clear existing tracks
    sqlite3 "$DATABASE" "DELETE FROM tracks;"
    
    # Extract and insert metadata
    for file in "${files[@]}"; do
        local metadata=$(python3 "$METADATA_SCRIPT" "$file")
        local filepath=$(echo "$metadata" | jq -r '.filepath')
        local artist=$(echo "$metadata" | jq -r '.artist' | sed "s/'/''/g")
        local album=$(echo "$metadata" | jq -r '.album' | sed "s/'/''/g")
        local title=$(echo "$metadata" | jq -r '.title' | sed "s/'/''/g")
        local duration=$(echo "$metadata" | jq -r '.duration')
        
        sqlite3 "$DATABASE" \
            "INSERT OR REPLACE INTO tracks (filepath, filename, artist, album, title, duration) VALUES ('$filepath', '$(basename "$filepath")', '$artist', '$album', '$title', $duration);"
    done
    
    dialog --msgbox "Library scan complete. Found ${#files[@]} tracks." 6 40
}

# Search library
search_library() {
    local search_term
    search_term=$(dialog --title "Search Library" \
                         --inputbox "Enter artist, album, or track name:" \
                         8 40 \
                         2>&1 >/dev/tty)
    
    if [ $? -eq 0 ]; then
        local results=$(sqlite3 "$DATABASE" \
            "SELECT filepath, artist, album, title FROM tracks 
             WHERE artist LIKE '%$search_term%' 
             OR album LIKE '%$search_term%' 
             OR title LIKE '%$search_term%';" | tr '|' '\n')
        
        if [ -z "$results" ]; then
            dialog --msgbox "No results found." 6 40
            return
        fi
        
        local options=()
        local counter=1
        while IFS=$'\n' read -r line; do
            options+=("$counter" "$line")
            ((counter++))
        done <<< "$results"
        
        local selected
        selected=$(dialog --title "Search Results" \
                          --menu "Select a track:" \
                          20 70 10 \
                          "${options[@]}" \
                          2>&1 >/dev/tty)
        
        if [ $? -eq 0 ]; then
            local selected_track=$(echo "$results" | sed -n "${selected}p" | cut -d$'\n' -f1)
            play_music "$selected_track"
        fi
    fi
}

# Handle multimedia key events
handle_multimedia_keys() {
    local key="$1"
    case "$key" in
        XF86AudioPlay) toggle_playback ;;
        XF86AudioNext) next_track ;;
        XF86AudioPrev) previous_track ;;
        XF86AudioRaiseVolume) change_volume "+" ;;
        XF86AudioLowerVolume) change_volume "-" ;;
    esac
}

# Main menu
show_main_menu() {
    local options=(
        "1" "Play/Pause"
        "2" "Next track"
        "3" "Previous track"
        "4" "Browse files"
        "5" "Manage playlists"
        "6" "Show history"
        "7" "Increase volume"
        "8" "Decrease volume"
        "9" "Scan Library"
        "10" "Search Library"
        "11" "Exit"
    )
    
    local choice
    choice=$(dialog --title "MTSP - Main Menu" \
                   --menu "Choose an operation:" \
                   15 60 11 \
                   "${options[@]}" \
                   2>&1 >/dev/tty)
    
    case $choice in
        1) toggle_playback ;;
        2) next_track ;;
        3) previous_track ;;
        4) browse_files ;;
        5) manage_playlists ;;
        6) show_history ;;
        7) change_volume "+" ;;
        8) change_volume "-" ;;
        9) scan_library ;;
        10) search_library ;;
        11) cleanup_and_exit ;;
    esac
}

# Cleanup before exit
cleanup_and_exit() {
    # Kill mpv if running
    if [ -n "$PLAYER_PID" ]; then
        kill "$PLAYER_PID" 2>/dev/null
    fi
    
    # Optional: Remove temporary files
    rm -f /tmp/mpv.sock
    
    # Exit the script
    exit 0
}

# Trap signals for cleanup
trap cleanup_and_exit SIGINT SIGTERM

# Main function
main() {
    check_dependencies
    setup_environment
    show_banner
     scan_library  # Automatically scan library on first run
    
    # Main loop
    while true; do
        # Show main menu and process user choice
        show_main_menu
        
        # Small delay to prevent tight looping
        sleep 0.1
    done
}

# Run the main function
main
