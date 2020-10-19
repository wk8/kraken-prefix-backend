package main

import (
	"github.com/uber/kraken/origin/cmd"

	// Import all backend client packages to register them with backend manager.
	_ "github.com/uber/kraken/lib/backend/gcsbackend"
	_ "github.com/uber/kraken/lib/backend/hdfsbackend"
	_ "github.com/uber/kraken/lib/backend/httpbackend"
	_ "github.com/uber/kraken/lib/backend/registrybackend"
	_ "github.com/uber/kraken/lib/backend/s3backend"
	_ "github.com/uber/kraken/lib/backend/testfs"

	_ "github.com/wk8/kraken-prefix-backend/lib/backend/prefixbackend"
)

func main() {
	cmd.Run(cmd.ParseFlags())
}
