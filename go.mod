module github.com/wk8/kraken-prefix-backend

go 1.15

require (
	github.com/daixiang0/gci v0.2.4 // indirect
	github.com/pkg/errors v0.8.0
	github.com/stretchr/testify v1.3.0
	github.com/uber/kraken v0.1.4
	golang.org/x/tools v0.0.0-20201019160706-0a3dcccdcf7a // indirect
	gopkg.in/yaml.v2 v2.2.2
)

replace github.com/uber/kraken => github.com/wk8/kraken v0.1.5-0.20201018191115-bc73e6312229
