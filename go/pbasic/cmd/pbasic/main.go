package main

import (
	"fmt"
	"os"
)

func main() {
	if len(os.Args) >= 2 {
		path := os.Args[1]
		file, err := os.Open(path)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Cannot open file: %s\n", path)
			os.Exit(1)
		}
		_ = file.Close()
		os.Exit(0)
	}

	fmt.Println("PBasic")
}
