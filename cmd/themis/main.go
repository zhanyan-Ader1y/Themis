package main

import (
	"context"
	"os"

	"github.com/zhanyan-Ader1y/Themis/internal/themis/cli"
)

func main() {
	os.Exit(cli.Run(context.Background(), os.Args[1:], os.Stdout, os.Stderr))
}
