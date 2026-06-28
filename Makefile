# News Playlist Build Targets
# Requires .env file with keys (see .env.example)

ENV_FILE := .env

# Load env vars from file if it exists
ifneq (,$(wildcard $(ENV_FILE)))
include $(ENV_FILE)
export
endif

DART_DEFINES := --dart-define=SUPABASE_URL=$(SUPABASE_URL) \
	--dart-define=SUPABASE_ANON_KEY=$(SUPABASE_ANON_KEY) \
	--dart-define=CRAWL_API_KEY=$(CRAWL_API_KEY)

.PHONY: run build-apk build-ios analyze test clean

## Development
run:
	flutter run $(DART_DEFINES)

## Build
build-apk:
	flutter build apk --release $(DART_DEFINES)

build-apk-split:
	flutter build apk --release --split-per-abi $(DART_DEFINES)

build-ios:
	flutter build ios --release --no-codesign $(DART_DEFINES)

## Quality
analyze:
	flutter analyze

test:
	flutter test

test-coverage:
	flutter test --coverage

## Utility
clean:
	flutter clean

deps:
	flutter pub get

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "  run            Run app in debug mode with keys"
	@echo "  build-apk      Build release APK"
	@echo "  build-apk-split Build release APK split by ABI"
	@echo "  build-ios      Build release iOS (no codesign)"
	@echo "  analyze        Run dart analyzer"
	@echo "  test           Run all tests"
	@echo "  test-coverage  Run tests with coverage"
	@echo "  clean          Flutter clean"
	@echo "  deps           Get dependencies"
	@echo ""
	@echo "Requires .env file with keys. See .env.example"
