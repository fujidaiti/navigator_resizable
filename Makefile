.PHONY: help setup get upgrade clean cleanup doctor run test format analyze fix tidyup validate addpkg addpkg-dev generate generate-clean build-android build-ios build-web release-android release-ios apk ipa web aab

# Default target
help:
	@echo "Available targets:"
	@echo "  help          - Show this help message"
	@echo ""
	@echo "Setup & Dependencies:"
	@echo "  get           - Get dependencies"
	@echo "  upgrade       - Upgrade dependencies"
	@echo "  clean         - Clean build artifacts"
	@echo "  cleanup       - Clean, get dependencies, and generate code"
	@echo "  doctor        - Run flutter doctor"
	@echo ""
	@echo "Development:"
	@echo "  run           - Run app in debug mode"
	@echo "  test          - Run tests"
	@echo "  format        - Format code"
	@echo "  analyze       - Analyze code"
	@echo "  fix           - Auto-fix lint errors"
	@echo "  tidyup        - Fix, format, and analyze code"
	@echo "  validate      - Full validation (cleanup + analyze)"
	@echo ""
	@echo "Package Management:"
	@echo "  addpkg        - Add packages (usage: make addpkg PACKAGES='pkg1 pkg2')"
	@echo "  addpkg-dev    - Add dev packages (usage: make addpkg-dev PACKAGES='pkg1 pkg2')"
	@echo ""
	@echo "Code Generation:"
	@echo "  generate      - Generate code using build_runner (use cache)"
	@echo "  generate-clean - Generate code and delete conflicting outputs"
	@echo ""
	@echo "Build:"
	@echo "  build-android - Build Android APK"
	@echo "  build-ios     - Build iOS app"
	@echo "  build-web     - Build web app"
	@echo "  apk           - Alias for build-android"
	@echo "  ipa           - Alias for build-ios"
	@echo "  web           - Alias for build-web"
	@echo ""
	@echo "Release:"
	@echo "  release-android - Build Android app bundle for release"
	@echo "  release-ios     - Build iOS app for release"
	@echo "  aab             - Alias for release-android"

# ==============================================================================
# Variables
# ==============================================================================

# Check if FVM is available and use it, otherwise use flutter/dart
FLUTTER_CMD := $(shell if command -v fvm >/dev/null 2>&1 && [ -f .fvmrc ]; then echo "fvm flutter"; else echo "flutter"; fi)
DART_CMD := $(shell if command -v fvm >/dev/null 2>&1 && [ -f .fvmrc ]; then echo "fvm dart"; else echo "dart"; fi)

# ==============================================================================
# Setup & Dependencies
# ==============================================================================

get:
	$(FLUTTER_CMD) pub get

upgrade:
	$(FLUTTER_CMD) pub upgrade

clean:
	$(FLUTTER_CMD) clean

cleanup:
	$(MAKE) clean
	$(MAKE) get
	$(MAKE) generate

doctor:
	$(FLUTTER_CMD) doctor -v

# ==============================================================================
# Package Management
# ==============================================================================

addpkg:
ifndef PACKAGES
	@echo "Usage: make addpkg PACKAGES='package1 package2 ...'"
	@echo "Example: make addpkg PACKAGES='http provider'"
	@exit 1
endif
	$(FLUTTER_CMD) pub add $(PACKAGES)

addpkg-dev:
ifndef PACKAGES
	@echo "Usage: make addpkg-dev PACKAGES='package1 package2 ...'"
	@echo "Example: make addpkg-dev PACKAGES='mockito build_runner'"
	@exit 1
endif
	$(FLUTTER_CMD) pub add $(addprefix dev:,$(PACKAGES))

# ==============================================================================
# Code Generation
# ==============================================================================

generate:
	$(DART_CMD) run build_runner build

generate-clean:
	$(DART_CMD) run build_runner build --delete-conflicting-outputs

# ==============================================================================
# Development
# ==============================================================================

run:
	$(FLUTTER_CMD) run

test:
	$(FLUTTER_CMD) test

format:
	$(DART_CMD) format .

analyze:
	$(DART_CMD) analyze

fix:
	$(DART_CMD) fix --apply

tidyup:
	$(MAKE) fix
	$(MAKE) format
	$(MAKE) analyze

validate:
	$(MAKE) cleanup
	$(MAKE) analyze

# ==============================================================================
# Build
# ==============================================================================

build-android:
	$(FLUTTER_CMD) build apk

build-ios:
	$(FLUTTER_CMD) build ios

build-web:
	$(FLUTTER_CMD) build web

# ==============================================================================
# Release
# ==============================================================================

release-android:
	$(FLUTTER_CMD) build appbundle

release-ios:
	$(FLUTTER_CMD) build ios --release

# ==============================================================================
# Convenience Aliases
# ==============================================================================

apk: build-android
ipa: build-ios
web: build-web
aab: release-android
