# Release Checklist

## Pre-Release Testing
- [ ] Test keyboard shortcut functionality
- [ ] Verify Ollama connection with multiple models
- [ ] Test proofreading with different text formats
- [ ] Check menu bar icon states (connected/error/processing)
- [ ] Verify settings persistence
- [ ] Test clipboard restoration

## Build Preparation
- [ ] Update version number in Info.plist
- [ ] Ensure latest icon is included
- [ ] Run `./build-app.sh` to create fresh bundle
- [ ] Test the built .app on clean system

## GitHub Release
- [ ] Create new release tag (v1.0.0)
- [ ] Upload Proofreader.app.zip
- [ ] Write release notes with changes
- [ ] Include system requirements
- [ ] Add screenshots if available

## Distribution
- [ ] Verify Gatekeeper compatibility
- [ ] Test on different macOS versions
- [ ] Update README with latest features
- [ ] Notify users of update if applicable