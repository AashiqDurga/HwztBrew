#!/usr/bin/env bash
# =============================================================================
# macos.sh — sensible macOS system defaults.
# Each line is a `defaults write`. Comment out anything you disagree with.
# Reference: https://macos-defaults.com
# =============================================================================

set -euo pipefail
echo "Configuring macOS defaults…"

# Close System Settings so it doesn't clobber our changes on quit.
osascript -e 'tell application "System Settings" to quit' >/dev/null 2>&1 || true

# ----- Finder ----------------------------------------------------------------
defaults write com.apple.finder AppleShowAllFiles -bool true          # show hidden files
defaults write NSGlobalDomain AppleShowAllExtensions -bool true       # show file extensions
defaults write com.apple.finder ShowPathbar -bool true               # path bar
defaults write com.apple.finder ShowStatusBar -bool true             # status bar
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"  # list view by default
defaults write com.apple.finder _FXSortFoldersFirst -bool true       # folders on top
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"  # search current folder
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# Don't write .DS_Store files to network/USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ----- Dock ------------------------------------------------------------------
defaults write com.apple.dock autohide -bool true                    # auto-hide dock
defaults write com.apple.dock autohide-delay -float 0                # no hide delay
defaults write com.apple.dock tilesize -int 48                       # icon size
defaults write com.apple.dock show-recents -bool false              # no recent apps
defaults write com.apple.dock mru-spaces -bool false               # don't reorder spaces

# ----- Keyboard --------------------------------------------------------------
defaults write NSGlobalDomain KeyRepeat -int 2                       # fast key repeat
defaults write NSGlobalDomain InitialKeyRepeat -int 15               # short delay
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false   # repeat, not accents
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false  # no smart quotes (bad for code)

# ----- Screenshots -----------------------------------------------------------
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

# ----- Trackpad --------------------------------------------------------------
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true  # tap to click
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# ----- Misc ------------------------------------------------------------------
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false  # save to disk, not iCloud, by default
defaults write com.apple.LaunchServices LSQuarantine -bool false             # no "are you sure you want to open" for every download

# ----- Apply -----------------------------------------------------------------
for app in Finder Dock SystemUIServer; do
  killall "$app" >/dev/null 2>&1 || true
done

echo "macOS defaults applied. Some changes need a logout/restart."
