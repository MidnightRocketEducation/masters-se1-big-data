# ------------------------------------------------------------------
#  Detect the host OS
# ------------------------------------------------------------------
OS := $(shell uname -s)
CONFIGURATION := release

# ------------------------------------------------------------------
#  Build command – different flags for macOS vs Linux
# ------------------------------------------------------------------
ifeq ($(OS),Darwin)                 # macOS
	SWIFT_BUILD_CMD := swift build -c $(CONFIGURATION)
else ifeq ($(OS),Linux)             # Linux
	ARCH := $(shell uname -m)
	ifneq ($(filter $(ARCH), aarch64 x86_64),)
	SWIFT_BUILD_CMD := swift build -c $(CONFIGURATION) # --swift-sdk $(ARCH)-swift-linux-musl
else
	SWIFT_BUILD_CMD := $(error Unsupported architecture: $(ARCH))
endif
else
	SWIFT_BUILD_CMD := $(error Unsupported OS: $(OS))
endif

# ------------------------------------------------------------------
#  Default target – just build the project
# ------------------------------------------------------------------
.PHONY: build getpath
build:
	$(SWIFT_BUILD_CMD)


getpath:
	@test -n "$(APP_NAME)" || { echo "Please provide the APP_NAME variable with the name of the executable to get the path for."; exit 1; }
	$(eval BIN_PATH="$(shell $(SWIFT_BUILD_CMD) --show-bin-path)/$(APP_NAME)")
	@test -e "$(BIN_PATH)" || { printf "Not an executable: %s\n" "$(shell realpath --relative-to . "$(BIN_PATH)")"; exit 1; }
	@printf "%s\n" $(BIN_PATH)
