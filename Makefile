PAK_NAME := $(shell jq -r .name pak.json)

ARCHITECTURES := arm arm64
PLATFORMS := h700 m17 magicmini miyoomini my282 my355 rg35xx rg35xxplus rgb30 tg5040 tg5050 trimuismart zero28

MINUI_LIST_VERSION := 0.15.0
MINUI_PRESENTER_VERSION := 0.13.0
RCLONE_VERSION := 1.75.0
JQ_VERSION := 1.8.2
7ZZ_VERSION := 2602

clean:
	rm -f bin/*/minui-list* || true
	rm -f bin/*/minui-presenter* || true
	rm -f bin/*/rclone* || true
	rm -f bin/*/jq* || true
	rm -f bin/*/7zz* || true

bump-version:
	jq '.version = "$(RELEASE_VERSION)"' pak.json > pak.json.tmp
	mv pak.json.tmp pak.json

build: $(foreach platform,$(PLATFORMS),bin/$(platform)/minui-list bin/$(platform)/minui-presenter) $(foreach arch,$(ARCHITECTURES),bin/$(arch)/rclone bin/$(arch)/jq bin/$(arch)/7zz)
	@echo "Build complete"

bin/%/minui-list:
	mkdir -p bin/$*
	curl -f -o bin/$*/minui-list -sSL https://github.com/josegonzalez/minui-list/releases/download/$(MINUI_LIST_VERSION)/minui-list-$*
	chmod +x bin/$*/minui-list

bin/%/minui-presenter:
	mkdir -p bin/$*
	curl -f -o bin/$*/minui-presenter -sSL https://github.com/josegonzalez/minui-presenter/releases/download/$(MINUI_PRESENTER_VERSION)/minui-presenter-$*
	chmod +x bin/$*/minui-presenter

bin/h700/minui-list:
	mkdir -p bin/h700
	curl -f -o bin/h700/minui-list -sSL https://github.com/josegonzalez/minui-list/releases/download/$(MINUI_LIST_VERSION)/minui-list-h700-nextui
	chmod +x bin/h700/minui-list

bin/h700/minui-presenter:
	mkdir -p bin/h700
	curl -f -o bin/h700/minui-presenter -sSL https://github.com/josegonzalez/minui-presenter/releases/download/$(MINUI_PRESENTER_VERSION)/minui-presenter-h700-nextui
	chmod +x bin/h700/minui-presenter

bin/tg5050/minui-list:
	mkdir -p bin/tg5050
	curl -f -o bin/tg5050/minui-list -sSL https://github.com/josegonzalez/minui-list/releases/download/$(MINUI_LIST_VERSION)/minui-list-tg5050-nextui
	chmod +x bin/tg5050/minui-list

bin/tg5050/minui-presenter:
	mkdir -p bin/tg5050
	curl -f -o bin/tg5050/minui-presenter -sSL https://github.com/josegonzalez/minui-presenter/releases/download/$(MINUI_PRESENTER_VERSION)/minui-presenter-tg5050-nextui
	chmod +x bin/tg5050/minui-presenter

bin/arm/jq:
	mkdir -p bin/arm
	curl -f -o bin/arm/jq -sSL https://github.com/jqlang/jq/releases/download/jq-$(JQ_VERSION)/jq-linux-armhf
	chmod +x bin/arm/jq
	curl -sSL -o bin/arm/jq.LICENSE "https://raw.githubusercontent.com/jqlang/jq/refs/tags/jq-$(JQ_VERSION)/COPYING"

bin/arm64/jq:
	mkdir -p bin/arm64
	curl -f -o bin/arm64/jq -sSL https://github.com/jqlang/jq/releases/download/jq-$(JQ_VERSION)/jq-linux-arm64
	chmod +x bin/arm64/jq
	curl -sSL -o bin/arm64/jq.LICENSE "https://raw.githubusercontent.com/jqlang/jq/refs/tags/jq-$(JQ_VERSION)/COPYING"

bin/arm/rclone:
	mkdir -p bin/arm
	curl -f -o bin/arm/rclone.zip -sSL https://downloads.rclone.org/v$(RCLONE_VERSION)/rclone-v$(RCLONE_VERSION)-linux-arm-v7.zip
	unzip -d bin/arm bin/arm/rclone.zip
	mv bin/arm/rclone-v$(RCLONE_VERSION)-linux-arm-v7/rclone bin/arm/rclone
	rm -rf bin/arm/rclone-v$(RCLONE_VERSION)-linux-arm-v7
	rm -f bin/arm/rclone.zip
	chmod +x bin/arm/rclone
	curl -sSL -o bin/arm/rclone.LICENSE "https://raw.githubusercontent.com/rclone/rclone/v$(RCLONE_VERSION)/COPYING"

bin/arm64/rclone:
	mkdir -p bin/arm64
	curl -f -o bin/arm64/rclone.zip -sSL https://downloads.rclone.org/v$(RCLONE_VERSION)/rclone-v$(RCLONE_VERSION)-linux-arm64.zip
	unzip -d bin/arm64 bin/arm64/rclone.zip
	mv bin/arm64/rclone-v$(RCLONE_VERSION)-linux-arm64/rclone bin/arm64/rclone
	rm -rf bin/arm64/rclone-v$(RCLONE_VERSION)-linux-arm64
	rm -f bin/arm64/rclone.zip
	chmod +x bin/arm64/rclone
	curl -sSL -o bin/arm64/rclone.LICENSE "https://raw.githubusercontent.com/rclone/rclone/v$(RCLONE_VERSION)/COPYING"

bin/%/7zz:
	mkdir -p bin/$*
	curl -f -o bin/$*/7zip.tar.xz -sSL https://github.com/ip7z/7zip/releases/download/$(shell echo $(7ZZ_VERSION) | sed 's/../&./')/7z$(7ZZ_VERSION)-linux-$*.tar.xz
	mkdir -p bin/$*/7zz_temp
	tar -xf bin/$*/7zip.tar.xz -C bin/$*/7zz_temp
	mv bin/$*/7zz_temp/7zz bin/$*/7zz
	mv bin/$*/7zz_temp/License.txt bin/$*/7zz.LICENSE
	rm -rf bin/$*/7zz_temp
	rm -f bin/$*/7zip.tar.xz
	chmod +x bin/$*/7zz

release: build
	mkdir -p dist
	git archive --format=zip --output "dist/$(PAK_NAME).pak.zip" HEAD
	while IFS= read -r file; do zip -r "dist/$(PAK_NAME).pak.zip" "$$file"; done < .gitarchiveinclude
	ls -lah dist
