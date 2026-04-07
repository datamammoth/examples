// List all servers with the DataMammoth Go SDK.
//
// Usage:
//
//	export DM_API_KEY="dm_live_..."
//	go run list_servers.go
package main

import (
	"context"
	"fmt"
	"log"
	"os"

	datamammoth "github.com/datamammoth/dm-go"
)

func main() {
	apiKey := os.Getenv("DM_API_KEY")
	if apiKey == "" {
		log.Fatal("Error: Set the DM_API_KEY environment variable")
	}

	client := datamammoth.NewClient(apiKey)
	ctx := context.Background()

	// List servers with filters
	servers, meta, err := client.Servers.List(ctx, &datamammoth.ListOptions{
		Status:  "running",
		Sort:    "-created_at",
		PerPage: 20,
	})
	if err != nil {
		log.Fatalf("Failed to list servers: %v", err)
	}

	fmt.Printf("Servers (page %d/%d, total: %d):\n\n", meta.Page, meta.TotalPages, meta.Total)

	for _, s := range servers {
		icon := "[??]"
		switch s.Status {
		case "running":
			icon = "[OK]"
		case "stopped":
			icon = "[--]"
		case "provisioning":
			icon = "[..]"
		case "terminated":
			icon = "[XX]"
		}

		fmt.Printf("  %s %s\n", icon, s.ID)
		fmt.Printf("      Hostname: %s\n", s.Hostname)
		fmt.Printf("      IP:       %s\n", s.IPAddress)
		fmt.Printf("      Region:   %s\n", s.Region)
		fmt.Printf("      Plan:     %s\n\n", s.Plan)
	}
}
