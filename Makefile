cmd       := schma
build_dir := target
bin_dir   := $(build_dir)/bin
binaries  := $(cmd)-linux-arm64 $(cmd)-linux-amd64 $(cmd)-darwin-arm64 $(cmd)-darwin-amd64
version   := $(shell cat VERSION)

go_src := $(shell find . -type f -name '*.go' -not -path "./vendor/*")

no_color   := \033[0m
ok_color   := \033[32;01m
err_color  := \033[31;01m
warn_color := \033[33;01m

export GO111MODULE=on

all:        $(binaries)
linux-all:  $(bin_dir)/linux/amd64/$(cmd)
darwin-all: $(bin_dir)/darwin/amd64/$(cmd)

gobuild: $(binaries)

.PHONY: test
test:
	@echo "\n$(ok_color)====> Running tests$(no_color)"
	go test -mod=vendor ./...

.PHONY: clean
clean:
	@echo "\n$(ok_color)====> Cleaning$(no_color)"
	go clean ./... && rm -rf ./$(build_dir)

$(binaries): splitted=$(subst -, ,$@)
$(binaries): os=$(word 2, $(splitted))
$(binaries): arch=$(word 3, $(splitted))
$(binaries): $(go_src)
	@echo "\n$(ok_color)====> Building $@$(no_color)"
	GOOS=$(os) GOARCH=$(arch) CGO_ENABLED=0 \
		go build \
			-mod=vendor -a \
			-ldflags=all="-X main.Version=$(version)" \
			-o $(bin_dir)/$@ *.go
	md5sum $(bin_dir)/$@ > $(bin_dir)/$@.md5
	sha256sum $(bin_dir)/$@ > $(bin_dir)/$@.sha256
