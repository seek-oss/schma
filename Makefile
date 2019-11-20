cmd       := schma
build_dir := target
bin_dir   := $(build_dir)/bin
binaries  := $(bin_dir)/$(cmd)-linux-amd64 $(bin_dir)/$(cmd)-darwin-amd64
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
	GOOS=$(os) GOARCH=$(arch) CGO_ENABLED=0 go build \
		-mod=vendor -a \
		-ldflags=all="-X main.Version=$(version)" \
		-o $@ *.go
	md5sum $@ > $@.md5
	sha256sum $@ > $@.sha256
