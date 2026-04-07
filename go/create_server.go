// Create a new VPS server and wait for provisioning.
//
// Usage:
//
//	export DM_API_KEY="dm_live_..."
//	go run create_server.go
package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	datamammoth "github.com/datamammoth/dm-go"
)

func main() {
	apiKey := os.Getenv("DM_API_KEY")
	if apiKey == "" {
		log.Fatal("Error: Set the DM_API_KEY environment variable")
	}

	client := datamammoth.NewClient(apiKey)
	ctx := context.Background()

	// Step 1: Browse products
	products, _, err := client.Products.List(ctx, &datamammoth.ListOptions{PerPage: 5})
	if err != nil {
		log.Fatalf("Failed to list products: %v", err)
	}
	fmt.Println("Available products:")
	for _, p := range products {
		fmt.Printf("  %s: %s (%s)\n", p.ID, p.Name, p.Type)
	}

	// Step 2: Get zones and images
	zones, _, err := client.Zones.List(ctx, nil)
	if err != nil {
		log.Fatalf("Failed to list zones: %v", err)
	}
	zone := zones[0]
	fmt.Printf("\nUsing zone: %s (%s)\n", zone.Name, zone.ID)

	images, _, err := client.Zones.ListImages(ctx, zone.ID, nil)
	if err != nil {
		log.Fatalf("Failed to list images: %v", err)
	}
	image := images[0]
	fmt.Printf("Using image: %s (%s)\n", image.Name, image.ID)

	// Step 3: Create the server
	fmt.Println("\nProvisioning server...")
	result, err := client.Servers.Create(ctx, &datamammoth.CreateServerRequest{
		ProductID: products[0].ID,
		ZoneID:    zone.ID,
		ImageID:   image.ID,
		Hostname:  "demo-server.example.com",
		Label:     "Demo Server",
	})
	if err != nil {
		log.Fatalf("Failed to create server: %v", err)
	}
	fmt.Printf("Task created: %s\n", result.TaskID)

	// Step 4: Poll until complete
	fmt.Println("Waiting for provisioning...")
	task, err := client.Tasks.Await(ctx, result.TaskID, 3*time.Second, 5*time.Minute)
	if err != nil {
		log.Fatalf("Task failed: %v", err)
	}

	if task.Status == "completed" {
		fmt.Printf("\nServer provisioned!\n")
		fmt.Printf("  Server ID: %s\n", task.Result["server_id"])
		fmt.Printf("  IP Address: %s\n", task.Result["ip_address"])
	} else {
		log.Fatalf("Provisioning failed: %s", task.Error)
	}
}
