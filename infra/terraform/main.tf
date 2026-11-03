# User story: US-05 Backend foundation (technical enabler) (Sprint 1, MVP)
# Requirements: NFR-MAINT-001, NFR-MAINT-004, NFR-MAINT-006, NFR-TEST-003
# Implemented here: root module. Fill after TBD-06 picks the provider; keep secrets out of state files and code

terraform {
  required_version = ">= 1.9"
}

# TODO (Sprint 1): provider block, network, managed database, object storage for bundles and submissions.
# Rules: private storage by default, least-privilege roles, no secrets in variables files.
