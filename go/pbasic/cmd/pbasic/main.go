package main

import (
	"bufio"
	"fmt"
	"os"

	"pbasic/pbasic/internal/repl"
)

func main() {
	repl.SetupSignalHandling()

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
	r := repl.NewREPL(bufio.NewReader(os.Stdin), os.Stdout)
	r.Start()
}
