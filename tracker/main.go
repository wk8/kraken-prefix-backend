package main

import "github.com/uber/kraken/tracker/cmd"

func main() {
	cmd.Run(cmd.ParseFlags())
}
