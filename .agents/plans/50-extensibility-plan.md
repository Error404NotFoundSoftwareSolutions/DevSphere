# Plan: extensibility (Track X)

Status: **Active** (docs and registries only until code freeze lifts).

## Goal
Adding the next idea is a small, predictable change: a registry row, a module behind a port, tests, an ADR.

## Milestones
| ID | Milestone | Exit criteria |
|---|---|---|
| PL-EXT-01 | Fabric documented | `architecture/extension-fabric.md`, registries, ideas intake | Done 2026-11-04 |
| PL-EXT-02 | Contracts package design | RFC: `packages/contracts` layout, generators for Dart/TS/Python, how existing `ipc_contract`/`lab_schema` migrate |
| PL-EXT-03 | Registry validation | Script that checks registries against docs and code (capability owner exists, extension point has a contract) |
| PL-EXT-04 | Plugin manifest | `devsphere.plugin.json` schema + validator |
| PL-EXT-05 | First external idea integrated end to end | Proof that the pipeline works (candidate: a new lab kind) |

## Verification
For PL-EXT-05, count touched files outside the new module; target: zero core files changed.
