package main

import (
	"log"
	"net/http"
	"os"

	"github.com/azure-samples/aks-nap-admission-webhook/internal/handler"
)

func main() {
	log.SetOutput(os.Stdout)
	log.SetFlags(log.LstdFlags | log.Lmicroseconds)

	log.Println("[startup] PV Zone Fix Webhook starting on :8443")

	http.HandleFunc("/mutate", handler.HandleMutate)
	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	if err := http.ListenAndServeTLS(":8443", "/tls/tls.crt", "/tls/tls.key", nil); err != nil {
		log.Fatalf("[fatal] Failed to start HTTPS server: %v", err)
	}
}
