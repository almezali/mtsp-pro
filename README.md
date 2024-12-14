                                                  
     ███╗   ███╗████████╗███████╗██████╗"     
     ████╗ ████║╚══██╔══╝██╔════╝██╔══██╗"     
     ██╔████╔██║   ██║   ███████╗██████╔╝"     
     ██║╚██╔╝██║   ██║   ╚════██║██╔═══╝"     
     ██║ ╚═╝ ██║   ██║   ███████║██║"          
     ╚═╝     ╚═╝   ╚═╝   ╚══════╝╚═╝"          
                       

# 🎵 MTSP - Music Terminal Shell Player

MTSP is a powerful, feature-rich terminal-based music player for Linux systems, designed to provide a seamless and interactive music listening experience directly from the command line.

## 🌟 Features

- 📂 Music Library Management
  - Automatic music library scanning
  - Support for multiple audio formats (MP3, FLAC, OGG, M4A)
  - Metadata extraction and storage

- 🎶 Playback Controls
  - Play/Pause
  - Next/Previous track
  - Volume control
  - Multimedia key support

- 🔍 Library Navigation
  - Browse music files
  - Search library by artist, album, or track
  - Play history tracking

- 📋 Playlist Management (Coming Soon)
  - Create and manage custom playlists
  - Save and load playlists

## 🖥️ Screenshots

[Note: Replace these with actual screenshots of your application]
![MTSP Main Menu](https://github.com/almezali/mtsp-pro/raw/main/Screenshot_p1.png)
![MTSP File Browser](https://github.com/almezali/mtsp-pro/raw/main/Screenshot_p1.png)

## 🔧 System Requirements

### Dependencies
- mpv
- socat
- jq
- dialog
- xdotool
- sqlite3
- Python 3
- python3-mutagen library

### Supported Linux Distributions
- Ubuntu (20.04 LTS and newer)
- Debian (10 and newer)
- Fedora (32 and newer)
- Arch Linux
- Linux Mint
- Elementary OS
- PopOS!
- Manjaro Linux

## 🚀 Installation

### Ubuntu/Debian
```bash
# Install dependencies
sudo apt-get update
sudo apt-get install mpv socat jq dialog xdotool sqlite3 python3-mutagen

# Clone the repository
git clone https://github.com/almezali/mtsp.git
cd mtsp

# Make the script executable
chmod +x mtsp-pro.sh

# Run the application
./mtsp-pro.sh
```

### Fedora
```bash
# Install dependencies
sudo dnf install mpv socat jq dialog xdotool sqlite python3-mutagen

# Clone the repository
git clone https://github.com/almezali/mtsp.git
cd mtsp

# Make the script executable
chmod +x mtsp-pro.sh

# Run the application
./mtsp-pro.sh
```

### Arch Linux
```bash
# Install dependencies
sudo pacman -S mpv socat jq dialog xdotool sqlite python-mutagen

# Clone the repository
git clone https://github.com/almezali/mtsp.git
cd mtsp

# Make the script executable
chmod +x mtsp-pro.sh

# Run the application
./mtsp-pro.sh
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

[FREE]

## 🐛 Issues

Report issues on the GitHub Issues page.
