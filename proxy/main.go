package main

import "github.com/uber/kraken/proxy/cmd"

func main() {
	cmd.Run(cmd.ParseFlags())
}
