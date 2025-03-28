TAG ?= latest
PAK_NAME := $(shell jq -r .label config.json)

ARCHITECTURES := arm arm64
PLATFORMS := miyoomini my282 rg35xxplus tg5040

MINUI_LIST_VERSION := 0.7.0
MINUI_PRESENTER_VERSION := 0.4.0
RCLONE_VERSION := 1.69.1
JQ_VERSION := 1.7.1
7ZZ_VERSION := 2409

clean:
	rm -f bin/*/minui-list* || true
	rm -f bin/*/minui-presenter* || true
	rm -f bin/*/rclone* || true
	rm -f bin/*/jq* || true
	rm -f bin/*/7zz* || true

build: $(foreach platform,$(PLATFORMS),bin/$(platform)/minui-list bin/$(platform)/minui-presenter) $(foreach arch,$(ARCHITECTURES),bin/$(arch)/rclone bin/$(arch)/jq bin/$(arch)/7zz)

bin/%/minui-list:
	mkdir -p bin/$*
	curl -f -o bin/$*/minui-list -sSL https://github.com/josegonzalez/minui-list/releases/download/$(MINUI_LIST_VERSION)/minui-list-$*
	chmod +x bin/$*/minui-list

bin/%/minui-presenter:
	mkdir -p bin/$*
	curl -f -o bin/$*/minui-presenter -sSL https://github.com/josegonzalez/minui-presenter/releases/download/$(MINUI_PRESENTER_VERSION)/minui-presenter-$*
	chmod +x bin/$*/minui-presenter

bin/arm/jq:
	mkdir -p bin/arm
	curl -f -o bin/arm/jq -sSL https://github.com/jqlang/jq/releases/download/jq-$(JQ_VERSION)/jq-linux-armhf
	chmod +x bin/arm/jq
	curl -sSL -o bin/arm/jq.LICENSE "https://github.com/jqlang/jq/raw/refs/heads/master/COPYING"

bin/arm64/jq:
	mkdir -p bin/arm64
	curl -f -o bin/arm64/jq -sSL https://github.com/jqlang/jq/releases/download/jq-$(JQ_VERSION)/jq-linux-arm64
	chmod +x bin/arm64/jq
	curl -sSL -o bin/arm64/jq.LICENSE "https://github.com/jqlang/jq/raw/refs/heads/master/COPYING"

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
	curl -f -o bin/$*/7zip.tar.xz -sSL https://www.7-zip.org/a/7z$(7ZZ_VERSION)-linux-$*.tar.xz
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
