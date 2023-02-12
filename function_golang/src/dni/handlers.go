package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
)

type InvokeRequest struct {
	Data     map[string]json.RawMessage
	Metadata map[string]interface{}
}

type InvokeResponse struct {
	Outputs     map[string]interface{}
	Logs        []string
	ReturnValue interface{}
}

func dniHandler(w http.ResponseWriter, r *http.Request) {
	ua := r.Header.Get("User-Agent")
	fmt.Printf("user agent is: %s \n", ua)
	invocationid := r.Header.Get("X-Azure-Functions-InvocationId")
	fmt.Printf("invocationid is: %s \n", invocationid)

	queryParams := r.URL.Query()

	if dni := queryParams["dni"]; dni != nil {
		valid := validateDNI(dni[0])
		js, err := json.Marshal(valid)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.Write(js)
	} else {
		http.Error(w, "dni query parameter not present", http.StatusInternalServerError)
	}
}

func validateDNI(dni string) bool {
	table := "TRWAGMYFPDXBNJZSQVHLCKE"
	foreignerDigits := map[string]string{
		"X": "0",
		"Y": "1",
		"Z": "2",
	}
	parsedDNI := strings.ToUpper(dni)
	if len(parsedDNI) == 9 {
		checkDigit := parsedDNI[8]
		parsedDNI = parsedDNI[:8]
		if foreignerDigits[strings.ToUpper(string(parsedDNI[0]))] != "" {
			parsedDNI = strings.Replace(parsedDNI, string(parsedDNI[0]), foreignerDigits[string(parsedDNI[0])], 1)
		}
		dniNumbers, err := strconv.Atoi(parsedDNI)
		if err != nil {
			fmt.Println("Error during conversion")
		}

		return table[dniNumbers%23] == checkDigit
	}
	return false
}

func main() {
	customHandlerPort, exists := os.LookupEnv("FUNCTIONS_CUSTOMHANDLER_PORT")
	if !exists {
		customHandlerPort = "8080"
	}
	mux := http.NewServeMux()
	mux.HandleFunc("/api/dni", dniHandler)
	fmt.Println("Go server Listening on: ", customHandlerPort)
	log.Fatal(http.ListenAndServe(":"+customHandlerPort, mux))
}
