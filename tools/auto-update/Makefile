default: build

build: ## Build static
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build  -ldflags "-extldflags '-static'" -o auto-update_linux-amd64 main.go
	GOOS=darwin GOARCH=amd64 CGO_ENABLED=0 go build  -ldflags "-extldflags '-static'" -o auto-update_darwin-amd64 main.go
	CGO_ENABLED=0 go build  -ldflags "-extldflags '-static'" -o auto-update main.go
