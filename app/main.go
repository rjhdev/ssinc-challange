package main

import (
    "encoding/json"
    "fmt"
    "log"
    "net"
    "net/http"
    "os"
)

// Define a struct to structure the JSON response
type HostInfo struct {
    Hostname  string `json:"hostname"`
    IPAddress string `json:"ip_address"`
}

func handler(w http.ResponseWriter, r *http.Request) {
    // Log a message every time a request is made
    log.Printf("Received request: %s %s", r.Method, r.URL.Path)

    hostname, err := os.Hostname()
    if err != nil {
        http.Error(w, fmt.Sprintf("Error getting hostname: %v", err), http.StatusInternalServerError)
        return
    }

    var ipAddr string
    ips, err := net.LookupIP(hostname)
    if err != nil {
        http.Error(w, fmt.Sprintf("Error looking up IP address: %v", err), http.StatusInternalServerError)
        return
    }

    for _, ip := range ips {
        if ipv4 := ip.To4(); ipv4 != nil {
            ipAddr = ipv4.String()
            break
        }
    }

    // Set response content-type to JSON
    w.Header().Set("Content-Type", "application/json")

    // Use the struct to store the hostname and IP, then encode to JSON
    response := HostInfo{
        Hostname:  hostname,
        IPAddress: ipAddr,
    }
    json.NewEncoder(w).Encode(response)
}

func main() {
    // Initialize the log package
    log.SetFlags(log.LstdFlags | log.Lshortfile)
    log.Println("Server starting on port 80...")

    http.HandleFunc("/", handler)
    if err := http.ListenAndServe(":80", nil); err != nil {
        log.Fatalf("Failed to start server: %v", err)
    }
}