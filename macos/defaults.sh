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

say "Dock: autohide, no delay, smaller tiles"
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.2
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock show-recents -bool false

say "Screenshots: save to ~/Pictures/Screenshots as PNG, no shadow"
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

say "Misc: expand save/print panels, disable auto-correct, disable smart quotes"
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

say "Restart affected apps"
killall Finder Dock SystemUIServer 2>/dev/null || true

echo "Done. Some settings only take effect after logout/login."
