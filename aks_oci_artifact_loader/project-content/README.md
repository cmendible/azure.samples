# project-v1.0.0

This is a sample project content bundle used to demonstrate the OCI image-volume pattern on AKS 1.36.

## Contents

- `config/` — application settings
- `data/` — sample datasets (JSON, CSV)
- `rules/` — business rule definitions

This directory is packaged as a scratch-based OCI image and mounted read-only into pods via the Kubernetes image volumes feature.
