#!/usr/bin/env bash
# Minimal macOS defaults. Start small; add entries as you notice "oh, I always change this".
# Re-runnable — every `defaults write` is idempotent.
set -euo pipefail

say() { printf "\n\033[1;34m==> %s\033[0m\n" "$*"; }

say "Keyboard: fastest key repeat"
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

say "Finder: show hidden files, show all extensions, show path bar"
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"   # search current folder

say "Dock: always visible, smaller tiles"
defaults write com.apple.dock autohide -bool false
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock show-recents -bool false

say "Screenshots: save to ~/Pictures/Screenshots as PNG, no shadow"
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

say "Appearance: dark mode"
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

say "Trackpad: max speed, tap-to-click, three-finger drag"
# Tracking speed (float 0–3, 3 is max)
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 3
# Tap to click — both Bluetooth external and built-in
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
# Three-finger drag. On macOS 14+ this needs all three keys per device:
# TrackpadThreeFingerDrag=true selects the gesture; Dragging=false and
# DragLock=false ensure we're in three-finger mode rather than tap-to-drag.
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Dragging -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad DragLock -bool false
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.AppleMultitouchTrackpad Dragging -bool false
defaults write com.apple.AppleMultitouchTrackpad DragLock -bool false
# Two-finger secondary (right) click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 0

say "Mouse: natural scroll direction"
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true

say "Misc: expand save/print panels, disable auto-correct, disable smart quotes"
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

say "Restart affected apps"
killall Finder Dock SystemUIServer cfprefsd 2>/dev/null || true

cat <<'EOF'

Done. A few caveats:
  - Dark mode + tap-to-click may need a logout/login to take full effect.
  - Trackpad settings need to be re-seated by System Settings once before
    some features (like three-finger drag on Sonoma+) become visible in
    the UI — open System Settings → Trackpad → Point & Click, toggle anything.
  - If a setting doesn't stick, re-run this script after an initial login.
EOF
