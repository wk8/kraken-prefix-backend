package main

import "github.com/uber/kraken/agent/cmd"

func main() {
	cmd.Run(cmd.ParseFlags())
}
