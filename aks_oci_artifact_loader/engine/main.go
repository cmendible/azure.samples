package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"path/filepath"
)

type Node struct {
	Name     string  `json:"name"`
	Path     string  `json:"path"`
	IsDir    bool    `json:"is_dir"`
	Children []*Node `json:"children,omitempty"`
}

func buildTree(root, current string) (*Node, error) {
	info, err := os.Stat(current)
	if err != nil {
		return nil, err
	}

	rel, err := filepath.Rel(root, current)
	if err != nil {
		return nil, err
	}

	node := &Node{
		Name:  info.Name(),
		Path:  "/" + filepath.ToSlash(rel),
		IsDir: info.IsDir(),
	}

	if !info.IsDir() {
		return node, nil
	}

	entries, err := os.ReadDir(current)
	if err != nil {
		return nil, err
	}

	for _, entry := range entries {
		child, err := buildTree(root, filepath.Join(current, entry.Name()))
		if err != nil {
			return nil, err
		}
		node.Children = append(node.Children, child)
	}

	return node, nil
}

func treeHandler(w http.ResponseWriter, r *http.Request) {
	contentPath := os.Getenv("CONTENT_PATH")
	if contentPath == "" {
		contentPath = "/content"
	}

	tree, err := buildTree(contentPath, contentPath)
	if err != nil {
		http.Error(w, "failed to read content path: "+err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(tree); err != nil {
		log.Printf("error encoding response: %v", err)
	}
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"status":"ok"}`))
}

func main() {
	http.HandleFunc("/tree", treeHandler)
	http.HandleFunc("/health", healthHandler)

	addr := ":8080"
	log.Printf("engine listening on %s", addr)
	log.Fatal(http.ListenAndServe(addr, nil))
}
