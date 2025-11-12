# Music Stream iOS App - Makefile

.PHONY: help generate build clean install test simulator

help:
	@echo "Music Stream iOS App - Build Commands"
	@echo "======================================"
	@echo ""
	@echo "Available commands:"
	@echo "  make generate  - Generate Xcode project with XcodeGen"
	@echo "  make build     - Build IPA file for AltStore"
	@echo "  make clean     - Clean build artifacts"
	@echo "  make simulator - Run in iOS Simulator"
	@echo "  make test      - Run unit tests"
	@echo "  make install   - Install dependencies"
	@echo ""

generate:
	@echo "🔨 Generating Xcode project..."
	@xcodegen generate
	@echo "✅ Project generated successfully!"

build: generate
	@echo "🎵 Building Music Stream IPA..."
	@./build.sh

clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf build
	@rm -rf DerivedData
	@rm -rf *.xcodeproj
	@rm -rf *.xcworkspace
	@echo "✅ Clean complete!"

simulator: generate
	@echo "📱 Running in iOS Simulator..."
	@xcodebuild build \
		-project MusicStream.xcodeproj \
		-scheme MusicStream \
		-destination 'platform=iOS Simulator,name=iPhone 14'
	@xcrun simctl boot "iPhone 14" || true
	@xcrun simctl install booted build/Debug-iphonesimulator/MusicStream.app
	@xcrun simctl launch booted com.musicstream.app

test: generate
	@echo "🧪 Running tests..."
	@xcodebuild test \
		-project MusicStream.xcodeproj \
		-scheme MusicStream \
		-destination 'platform=iOS Simulator,name=iPhone 14'

install:
	@echo "📦 Installing dependencies..."
	@if ! command -v xcodegen &> /dev/null; then \
		echo "Installing XcodeGen..."; \
		brew install xcodegen; \
	fi
	@echo "✅ Dependencies installed!"

.DEFAULT_GOAL := help

