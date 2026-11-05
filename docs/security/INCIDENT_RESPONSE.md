# Incident response

## 1. What is an incident
Confirmed or suspected: secret exposure, protected content exposure, score tampering, malicious update/extension/dependency, account compromise, data breach, agent performing an unapproved destructive or outward action, sandbox escape.

## 2. Roles
| Role | Duty |
|---|---|
| Incident lead (security owner) | Decides severity, coordinates, owns communication |
| Engineer on call | Contains and fixes |
| Communications owner | Writes user and regulator notices |
| Scribe | Timeline with absolute timestamps |

## 3. Steps
1. **Detect and declare.** Anyone can declare; say what, where, when. Open a private channel and record start time.
2. **Contain.** Revoke/rotate credentials first; disable the feature via flag; pull the artefact; block the host; suspend the account.
3. **Assess.** Scope, data affected, duration, attacker capability. Preserve evidence (logs, artefacts, hashes); do not destroy it.
4. **Eradicate and recover.** Fix root cause; rebuild from clean sources; re-sign; ship.
5. **Notify.** Affected users and, where required, authorities, within legal deadlines; plain language; what happened, what data, what we did, what they should do.
6. **Learn.** Blameless postmortem within 5 business days (`.agents/templates/postmortem.md`); new tests, rule or threat-model updates; track actions to done.

## 4. Specific playbooks
- **Secret in git:** SECRETS_MANAGEMENT section 4.
- **Compromised dependency:** pin to safe version or remove; rebuild and release; audit what ran.
- **Compromised release signing key:** revoke; publish new key through an out-of-band trusted channel; force-update path; notify.
- **Protected tests exposed:** rotate affected content; reissue labs; review scores in the exposure window.
- **Agent misbehaviour:** disable the tool/mode via flag, review audit log, add red-team case.

## 5. Drills
Run a tabletop exercise before the pilot and each year.
