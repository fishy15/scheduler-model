package main

import (
    "io/ioutil"
    "fmt"
    "log"
    "os"
    "os/exec"
    "path/filepath"
    "strings"
    "sync"
)

var topologies = [...]string{
    "2",
    "8",
    "16",
    "16-tiered",
    "32",
    "64",
}

var invariants = [...]string{
    // skipping first two
    "moves-from-busiest",
    "moves-from-busiest-swb",
    "overloaded-to-idle",
    "overloaded-to-idle-swb",
    "overloaded-to-idle-cfs",
    "overloaded-to-idle-cfs-swb",
}

func runCase(inv string, top string, result chan string, done chan bool) {
    defer func() { done <- true }()

    dir, err := os.Getwd()
    if err != nil {
        log.Println(err)
        return
    }

    exe := filepath.Join(dir, "src/runner")

    files, err := ioutil.ReadDir("data")
    if err != nil {
        log.Fatal(err)
    }

    topPlusTiered := top + "-tiered"

    output := ""
    for _, file := range files {
        fileName := file.Name()
        if strings.HasPrefix(fileName, top) && !strings.HasPrefix(fileName, topPlusTiered) {
            absoluteFile := filepath.Join(dir, "data", fileName)
            cmd := exec.Command(exe, absoluteFile, inv, "bench")
            fmt.Println("cmd", cmd)
            out, err := cmd.Output()
            if err != nil {
                log.Print(err)
                continue
            }

            resultStr := inv + " --- " + fileName + "\n" + string(out)
            output += resultStr
        }
    }

    result <- output
}

func processInvariant(inv string, wg *sync.WaitGroup) {
    defer wg.Done()

    results := make(chan string)
    done := make(chan bool)

    for _, top := range topologies {
        go runCase(inv, top, results, done)
    }

    output := ""
    doneCount := 0
    for doneCount < len(topologies) {
        select {
        case <-done:
            fmt.Println("adding one to done")
            doneCount++
        case res := <-results:
            output += res + "\n"
        }
    }

    outputFile := inv + ".txt"
    err := os.WriteFile(outputFile, []byte(output), 0666)
    if err != nil {
        log.Println(err)
    }
}

func main() {
    wg := new(sync.WaitGroup)
    for _, inv := range invariants {
        wg.Add(1)
        go processInvariant(inv, wg)
    }

    wg.Wait()
}
