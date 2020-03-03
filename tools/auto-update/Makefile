default: build

build: ## Build static
	CGO_ENABLED=0 go build  -ldflags "-extldflags '-static'" -o auto-update main.go
