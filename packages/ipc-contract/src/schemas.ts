// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: request and response shapes. Strict objects reject unknown fields (NFR-SEC-002)

import { z } from "zod";
import type { Channel } from "./channels";

const none = z.strictObject({});
const id = z.string().min(1).max(64);

// Note: no schema accepts a raw command string. Tasks are referenced by id from the lab manifest.
export const contract = {
  "auth:signIn": {
    request: none,
    response: z.strictObject({ userId: id, displayName: z.string() }),
  },
  "auth:signOut": { request: none, response: none },
  "auth:getSession": { request: none, response: z.strictObject({ userId: id.nullable() }) },
  "catalogue:list": {
    request: z.strictObject({ page: z.number().int().min(1).default(1) }),
    response: z.strictObject({
      labs: z.array(z.strictObject({ id, title: z.string(), version: z.string() })),
    }),
  },
  "bundle:download": {
    request: z.strictObject({ labId: id, version: z.string() }),
    response: z.strictObject({ ok: z.boolean() }),
  },
  "env:detect": {
    request: none,
    response: z.strictObject({
      items: z.array(
        z.strictObject({
          tool: z.string(),
          status: z.enum(["ready", "missing", "incompatible"]),
          version: z.string().optional(),
        }),
      ),
    }),
  },
  "env:plan": {
    request: z.strictObject({ labId: id }),
    response: z.strictObject({ planId: id, steps: z.array(z.string()) }),
  },
  "env:apply": {
    request: z.strictObject({ planId: id, approvalId: id }),
    response: z.strictObject({ ok: z.boolean() }),
  },
  "workspace:open": {
    request: z.strictObject({ attemptId: id }),
    response: z.strictObject({ ok: z.boolean() }),
  },
  "task:run": {
    request: z.strictObject({ attemptId: id, taskId: id }),
    response: z.strictObject({ runId: id }),
  },
  "task:stop": { request: z.strictObject({ runId: id }), response: none },
  "approval:respond": {
    request: z.strictObject({ approvalId: id, approved: z.boolean() }),
    response: none,
  },
  "progress:record": {
    request: z.strictObject({
      attemptId: id,
      type: z.string(),
      payload: z.record(z.string(), z.unknown()),
    }),
    response: z.strictObject({ eventId: id }),
  },
  "sync:status": {
    request: none,
    response: z.strictObject({ lastSyncAt: z.string().nullable(), pending: z.number().int() }),
  },
  "tutor:ask": {
    request: z.strictObject({
      attemptId: id,
      question: z.string().max(4000),
      level: z.number().int().min(1).max(6),
      shareCode: z.boolean(),
    }),
    response: z.strictObject({ requestId: id }),
  },
  "tutor:cancel": { request: z.strictObject({ requestId: id }), response: none },
  "submission:preview": {
    request: z.strictObject({ attemptId: id }),
    response: z.strictObject({ files: z.array(z.string()), excluded: z.array(z.string()) }),
  },
  "submission:submit": {
    request: z.strictObject({ attemptId: id, confirmedFiles: z.array(z.string()) }),
    response: z.strictObject({ submissionId: id }),
  },
} satisfies Record<Channel, { request: z.ZodType; response: z.ZodType }>;
