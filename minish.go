package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
)

// A humble utility to ensure fatal errors do not go unnoticed.
func must(err error) {
	if err != nil {
		panic(err)
	}
}

func main() {
	// Step 1: Locate oneself. One must know from whence one came.
	exePath, err := os.Executable()
	must(err)
	root := filepath.Dir(exePath) // Henceforth, this shall be our faux-root.

	// Step 2: Select the appropriate busybox binary based on the operating gentleman.
	busyboxBinary := "busybox"
	if runtime.GOOS == "windows" {
		busyboxBinary = "busybox.exe"
	}

	// Step 3: Assemble the path to busybox and her loyal companion, init.sh.
	busybox := filepath.Join(root, "opt", "busybox", busyboxBinary)
	initScript := filepath.Join(root, "opt", "busybox", "init.sh")

	// Step 4: Change one's current abode to the root of our tiny empire.
	must(os.Chdir(root))

	// Step 5: With manners and grace, invoke busybox's shell and hand it init.sh, along with any honoured guest arguments.
	cmd := exec.Command(busybox, "sh", initScript)
	cmd.Args = append(cmd.Args, os.Args[1:]...) // Kindly forward any arguments from our caller.

	// Step 6: Extend to busybox the full hospitality of our input and output parlours.
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	// Step 7: Commence the affair.
	must(cmd.Run())
}