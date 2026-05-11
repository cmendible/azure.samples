package handler

import (
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"
	"sort"
	"strings"
	"time"

	admissionv1 "k8s.io/api/admission/v1"
	corev1 "k8s.io/api/core/v1"
)

// The Azure Disk CSI driver sets nodeAffinity using its own topology key,
// not the standard Kubernetes topology key.
const topologyZoneKey = "topology.disk.csi.azure.com/zone"

// HandleMutate is the HTTP handler for the /mutate admission webhook endpoint.
func HandleMutate(w http.ResponseWriter, r *http.Request) {
	start := time.Now()
	log.Println("[request] Incoming admission review")

	body, err := io.ReadAll(r.Body)
	if err != nil {
		log.Printf("[error] Failed reading request body: %v", err)
		http.Error(w, "cannot read body", http.StatusBadRequest)
		return
	}

	var review admissionv1.AdmissionReview
	if err := json.Unmarshal(body, &review); err != nil {
		log.Printf("[error] Failed to unmarshal AdmissionReview: %v", err)
		http.Error(w, "bad request", http.StatusBadRequest)
		return
	}

	// Extract PV using the official k8s.io/api SDK type.
	var pv corev1.PersistentVolume
	if err := json.Unmarshal(review.Request.Object.Raw, &pv); err != nil {
		log.Printf("[error] Failed to unmarshal PV: %v", err)
		http.Error(w, "bad PV object", http.StatusBadRequest)
		return
	}

	log.Printf("[pv] Name=%s", pv.Name)

	// ---------------------------------------------------------
	// 1. Detect if PV is a ZRS Azure Disk (CSI driver)
	//    The Azure Disk CSI driver sets skuName in VolumeAttributes.
	// ---------------------------------------------------------
	isZRS := false
	if pv.Spec.CSI != nil {
		sku := pv.Spec.CSI.VolumeAttributes["skuName"]
		log.Printf("[pv] CSI driver=%s skuName=%s", pv.Spec.CSI.Driver, sku)
		if strings.Contains(sku, "ZRS") {
			isZRS = true
		}
	}

	if !isZRS {
		log.Println("[skip] PV is not ZRS → no mutation applied")
		review.Response = &admissionv1.AdmissionResponse{
			UID:     review.Request.UID,
			Allowed: true,
		}
		writeResponse(w, review, start)
		return
	}

	log.Println("[zrs] ZRS disk detected → evaluating node affinity topology")

	// ---------------------------------------------------------
	// 2. Extract all zone values from NodeAffinity
	//    The Azure Disk CSI driver creates one NodeSelectorTerm per zone
	//    for ZRS PVs. We collect all zone values to merge them.
	// ---------------------------------------------------------
	if pv.Spec.NodeAffinity == nil || pv.Spec.NodeAffinity.Required == nil {
		log.Println("[skip] No nodeAffinity found → nothing to merge")
		review.Response = &admissionv1.AdmissionResponse{
			UID:     review.Request.UID,
			Allowed: true,
		}
		writeResponse(w, review, start)
		return
	}

	zones := map[string]struct{}{}
	for _, term := range pv.Spec.NodeAffinity.Required.NodeSelectorTerms {
		for _, expr := range term.MatchExpressions {
			if expr.Key == topologyZoneKey {
				for _, v := range expr.Values {
					if v == "" {
						continue // skip empty zone values emitted by the CSI driver
					}
					log.Printf("[zone] Found zone=%s", v)
					zones[v] = struct{}{}
				}
			}
		}
	}

	if len(zones) == 0 {
		log.Println("[skip] No zones found in nodeAffinity → nothing to merge")
		review.Response = &admissionv1.AdmissionResponse{
			UID:     review.Request.UID,
			Allowed: true,
		}
		writeResponse(w, review, start)
		return
	}

	// ---------------------------------------------------------
	// 3. Merge zones into a single NodeSelectorTerm
	// ---------------------------------------------------------
	merged := make([]string, 0, len(zones))
	for z := range zones {
		merged = append(merged, z)
	}
	sort.Strings(merged) // deterministic ordering

	log.Printf("[merge] Merged zones: %v", merged)

	mergedTerms := []corev1.NodeSelectorTerm{
		{
			MatchExpressions: []corev1.NodeSelectorRequirement{
				{
					Key:      topologyZoneKey,
					Operator: corev1.NodeSelectorOpIn,
					Values:   merged,
				},
			},
		},
	}

	// ---------------------------------------------------------
	// 4. Build JSONPatch
	//    Replace nodeSelectorTerms so any zone can schedule the PV.
	// ---------------------------------------------------------
	patch := []map[string]interface{}{
		{
			"op":    "replace",
			"path":  "/spec/nodeAffinity/required/nodeSelectorTerms",
			"value": mergedTerms,
		},
	}

	patchBytes, _ := json.Marshal(patch)
	log.Printf("[patch] JSONPatch=%s", string(patchBytes))

	// ---------------------------------------------------------
	// 5. DRY RUN MODE
	// ---------------------------------------------------------
	if os.Getenv("DRY_RUN") == "true" {
		log.Println("[dry-run] DRY_RUN=true → patch NOT applied, only simulated")
		review.Response = &admissionv1.AdmissionResponse{
			UID:     review.Request.UID,
			Allowed: true,
		}
		writeResponse(w, review, start)
		return
	}

	// ---------------------------------------------------------
	// 6. Return the patch (normal mode)
	// ---------------------------------------------------------
	log.Println("[apply] Applying patch to PV")

	pt := admissionv1.PatchTypeJSONPatch
	review.Response = &admissionv1.AdmissionResponse{
		UID:       review.Request.UID,
		Allowed:   true,
		Patch:     patchBytes,
		PatchType: &pt,
	}

	writeResponse(w, review, start)
}

func writeResponse(w http.ResponseWriter, review admissionv1.AdmissionReview, start time.Time) {
	resp, err := json.Marshal(review)
	if err != nil {
		log.Printf("[error] Failed to marshal response: %v", err)
		http.Error(w, "cannot marshal response", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write(resp) //nolint:errcheck
	log.Printf("[response] Completed in %s", time.Since(start))
}
