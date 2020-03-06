package main

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/jasonlvhit/gocron"
)

func update() {
	envIotexHome := os.Getenv("IOTEX_HOME")
	envNetwork := os.Getenv("_GREP_STRING_")
	envENV := os.Getenv("_ENV_")

	if envIotexHome == "" || envNetwork == "" || envENV == "" {
		fmt.Printf("ENV $IOTEX_HOME=%s $_GREP_STRING_=%s $_ENV_%s must be set.",
			envIotexHome, envNetwork, envENV)
		return
	}

	cmdStr := envIotexHome + "/bin/update_silence.sh"
	cmd := exec.Command("/bin/sh", "-c", cmdStr)
	cmd.Env = append(os.Environ())

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Run()
}

func main() {
	fmt.Println("Auto-update is running...")
	// start scheduler
	gocron.Every(3).Days().Do(update)

	<-gocron.Start()
	// block main func
	select {}
}
