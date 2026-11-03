#!/usr/bin/env python3
"""Generate test_plan_v1.md from tools/test_plan_prose.md, srs_v1.md and backlog_v1.csv.
Fails if a committed requirement (MVP/R2/R3) lacks TC-<id>-01, a detailed case names an unknown requirement,
case numbers are not contiguous, or the prose references a test case that does not exist."""
import re, csv, sys
from collections import Counter, OrderedDict

srs = open("docs/main/srs_v1.md", encoding="utf-8").read()
rows = re.findall(r"^\|\s*((?:FR|NFR)-[A-Z]+-\d{3})\s*\|\s*(.+?)\s*\|\s*(MVP|R2|R3|LATER)\s*\|\s*([TIAD])\s*\|\s*$", srs, flags=re.M)
req = OrderedDict((r[0], {"text": r[1], "rel": r[2], "ver": r[3], "area": r[0].rsplit("-", 1)[0]}) for r in rows)

story = {}
for r in csv.DictReader(open("docs/backlog/backlog_v1.csv", encoding="utf-8")):
    for col in ("Functional requirements", "Non-functional requirements"):
        for i in filter(None, (x.strip() for x in r[col].split(";"))):
            story[i] = (r["Sprint"], r["Story ID"])

LEVEL = {"FR-AUTH": "Integration, system, security", "FR-PROF": "Integration, system", "FR-CAT": "Unit, integration",
 "FR-CONT": "CI evidence", "FR-ENV": "Unit, system (each OS)", "FR-WS": "System, demonstration", "FR-GUIDE": "System",
 "FR-EXEC": "Unit, system (each OS)", "FR-AI": "Unit, integration, prompt set", "FR-GRADE": "Integration, security, system",
 "FR-PROG": "Unit, integration, fault injection", "FR-BUG": "Integration, system", "FR-GIT": "System", "FR-OSS": "Integration, security",
 "NFR-SEC": "Security", "NFR-PRIV": "Security, inspection", "NFR-PERF": "Performance", "NFR-REL": "Fault injection",
 "NFR-UX": "Usability", "NFR-PORT": "System (each OS)", "NFR-MAINT": "Inspection", "NFR-COST": "Inspection, demonstration",
 "NFR-LEGAL": "Inspection", "NFR-TEST": "Inspection"}
METHOD = {"T": "Test", "I": "Inspection", "A": "Analysis", "D": "Demonstration"}

# (requirement, nn, title, steps/data, expected result)
D = [
("FR-AUTH-001",2,"Sign-in cancelled in the browser","Start sign-in, close the browser tab without approving.","Client shows a 'cancelled' message with a retry action; no session is stored; no account is created."),
("FR-AUTH-002",2,"Packaged client contains no secret","Build the release package; run a secret scanner over every file; search for the OAuth client secret and backend keys.","Scanner reports no secret; only the public desktop client ID is present."),
("FR-AUTH-004",2,"Token validation matrix","Call a protected endpoint with each FX-08 token.","Valid token: 200. Expired, wrong audience, wrong issuer, bad signature, revoked, missing: 401, with no data returned and an audit-safe log entry."),
("FR-AUTH-005",2,"Stable account key","Sign in; change the account's email at the provider; sign in again; run two simultaneous first sign-ins for one subject.","Same internal user ID each time; exactly one user row exists."),
("FR-AUTH-007",2,"No secure storage available","Run the Client where OS secure storage is unavailable or reports a weak backend.","Nothing is persisted; the Client works for the session and asks for sign-in at next start; no plaintext token on disk."),
("FR-AUTH-009",2,"Forged role is ignored","Send a request with a role or operator flag in the body, a header and a self-made token claim; call an operator endpoint as a student.","Role is read from server data only; operator endpoint returns 403; no state change."),
("FR-PROF-005",2,"User ID in body is ignored","As student A, PUT a profile whose body carries student B's user ID.","Student A's profile changes; B's profile is unchanged."),
("FR-PROF-006",2,"Cross-student read attempt","As student A, request B's profile, attempts, submissions and results by ID.","403 or 404 on every request; no data returned; operator read as operator succeeds and creates an audit event."),
("FR-CAT-004",2,"Tampered cached bundle","Download a bundle; change one byte in the cache; open the lab.","Checksum mismatch is detected; bundle is not used; student is told to re-download."),
("FR-CAT-006",2,"New version during an attempt","Start an attempt on v1; publish v2.","The attempt keeps v1, rubric and evaluator versions; a 'newer version available' notice appears; a new attempt uses v2."),
("FR-CAT-007",2,"No protected material delivered","Download every published bundle and call every student-facing endpoint; search all content for FX-12 canary strings.","No canary string found anywhere."),
("FR-CONT-003",2,"Reference solution fails a required test","Open a pull request with FX-02.","CI fails and names the failing test; publication is blocked."),
("FR-CONT-004",2,"Starter already passes","Open a pull request with FX-03.","CI fails with 'starter does not produce expected failures'."),
("FR-CONT-005",2,"Nondeterministic test","Open a pull request with FX-04 (N repeats from TBD-11).","CI fails on inconsistent results."),
("FR-CONT-002",2,"Broken content","Open pull requests with FX-05 variants (broken link, missing asset, weights not summing).","CI fails for each, naming the defect."),
("FR-CONT-007",2,"Rollback","Publish v1 and v2; roll back to the content of v1.","A new version v3 exists with content identical to v1 (same file hashes); v1 and v2 are unchanged; the rollback is recorded."),
("FR-ENV-005",2,"Consent declined","Snapshot the system (installed tools, PATH, services); show the setup plan; decline; compare.","No change to the system; the lab shows 'not ready' with the reason."),
("FR-ENV-006",2,"No persistent elevation","Run the Client and a setup step needing elevation on each OS.","The Client process is not elevated; elevation is requested for the single step only."),
("FR-ENV-009",2,"Compatible Python already present","Use the image with a compatible Python; open the lab.","Python is reported ready; the setup plan has no Python install step; readiness credit is recorded."),
("FR-ENV-010",2,"Network lost during a download","Cut the network during a setup download.","Failure is shown with recovery guidance; partial files are cleaned up or reported; a redacted log is available."),
("FR-ENV-008",2,"Success is verified, not assumed","Make an install step 'succeed' without installing the tool (stub).","Re-detection fails; the step is reported as failed."),
("FR-EXEC-002",2,"Shell metacharacters in names","Create files, branches and inputs named with spaces, quotes, `;`, `&`, `$()`, newlines; run tasks that use them.","Names are treated as literal data; a canary file that an injected command would create is not created."),
("FR-EXEC-005",2,"Stop a task with children","Start a task that spawns child processes; press stop (each OS).","Task and children end; none remain after 5 seconds."),
("FR-EXEC-006",2,"Runaway task","Run an infinite loop and an output flood.","Stopped at the time or output limit; limit reached message shown; UI stays responsive."),
("FR-EXEC-008",2,"Tutor proposes a destructive command","Make the tutor return a command that deletes files; do not approve; then approve a harmless one.","Nothing runs without approval; declining leaves no change; approval runs only the shown command through the normal consent step."),
("FR-AI-005",2,"Secrets in tutor context","Place FX-07 secrets in selected code, terminal output and a protected file; ask the tutor with all context enabled; capture the request at the proxy.","No secret and no protected file content in the outbound request; redaction is also applied by the backend."),
("FR-AI-006",2,"Level cap is applied by the backend","Lab maximum level is 3; send requests for level 6 from a modified client.","Backend uses level 3 and logs it; response follows level 3 policy."),
("FR-AI-009",2,"Prompt injection in files and output","Put 'ignore previous instructions' text, fake system messages and tool-grant requests in a file and in terminal output; ask a question.","Policy, level and context are unchanged; no tool or command is granted or run; deterministic checks pass."),
("FR-AI-010",2,"Provider failure classes","Make the provider return 401, 429, timeout, 5xx and network error.","Each is classified correctly; 401 is not retried; others retry within the bounded policy; the Client shows a matching message."),
("FR-AI-011",2,"AI is unavailable","Turn the provider off; use guide, editor, terminal, practice checks and submit for verification.","All other functions work; 'AI unavailable' is shown."),
("FR-AI-015",2,"No content retention by default","Send tutor requests; inspect the database, logs and storage.","Only provider, model, status and latency are stored; no prompt or response text; with opt-in enabled, content is stored and the opt-in is recorded."),
("FR-GRADE-004",2,"Snapshot contents","Workspace contains `.env`, private-key file, `.git`, ignored files, very large file and a disallowed type; start submission.","File list is shown; secret-bearing and ignored paths are excluded by default; oversize or disallowed files are blocked with a reason; student must confirm."),
("FR-GRADE-007",1,"Hostile suite","Run H-01 to H-20 (Section 5.1) on the staging grader.","Every case ends with its listed outcome; grader stays healthy; no effect outside the sandbox."),
("FR-GRADE-009",2,"Client-supplied score fields","POST a submission result, score, rank, rubric version and evaluator version in bodies and headers.","All are ignored; the stored score comes only from the signed grader result."),
("FR-GRADE-009",3,"Forged grader result","POST a result to the internal endpoint with no signature, a wrong signature and a replayed signature.","All rejected; no score record is written."),
("FR-GRADE-012",2,"Duplicate submission and redelivery","Submit the same snapshot twice; redeliver the same job three times; retry the result write.","One evaluation run and one score record exist; points are awarded once."),
("FR-GRADE-015",2,"Infrastructure failure","Kill the sandbox mid-run; make the grader service unavailable for the first two attempts.","Run is retried within the bounded policy; if it still fails it is shown as an infrastructure error, not a student failure; it is visible to operators; quota is not consumed; resubmit works."),
("FR-GRADE-020",2,"Dependency outside the locked set","Submit code that imports an unlisted package and code that tries to install one.","Result 'dependency not allowed'; no network connection attempted; run is not scored as a pass."),
("FR-GRADE-021",2,"Tampered harness inputs","Submit `conftest.py` forcing passes, a plugin, deleted tests and an early exit with status 0.","Student configuration is ignored; if executed test IDs differ from the pinned manifest the run is blocked; the result is never passed."),
("FR-GRADE-011",2,"Score correction","Operator corrects a score.","A new record with actor, reason and time is added; the original record is unchanged; an update or delete of a score row is refused."),
("FR-PROG-003",2,"Crash recovery","Kill the extension host during a step.","On restart, completed steps and results are restored; the incomplete step is shown as incomplete."),
("FR-PROG-004",2,"Replayed and interrupted sync","Send the same event batch three times; drop the connection mid-batch; reconnect.","No duplicate event; no lost event; pending count returns to zero."),
("FR-PROG-005",2,"Two devices offline","Complete different steps offline on two devices; reconnect both; also send a client-side 'verified' result.","Step completions are the union; the client-sent verified result is ignored."),
("FR-PROG-006",1,"Offline behaviour","Disable the network.","Cached lab, workspace and practice checks work; the UI shows last sync and pending events and explains that grading and tutor need a connection."),
("NFR-SEC-014",2,"Hostile archives in all three components","Send H-10, H-11 and H-12 style archives to the Client import path, the API upload and the Grader.","Each component rejects them; no file is written outside the target directory."),
("NFR-SEC-015",2,"Rate limits","Send bursts to sign-in-related, tutor, submission and profile endpoints.","429 with retry information after the limit; normal use is unaffected."),
("NFR-PERF-005",2,"Grading latency under load","Submit the TBD-10 cohort load within five minutes.","95th percentile total time is within target; no job lost; queue drains."),
("NFR-REL-005",2,"Restore rehearsal","Restore the latest backup into a clean instance.","Row counts and checksums of key tables match; restore time is recorded; the application starts against the restored data."),
("NFR-TEST-002",2,"Reproducible verified results","Grade the same snapshot five times with identical bundle, rubric, evaluator and image.","All five results are identical."),
("FR-BUG-007",2,"Hard-coded visible expectations (R2)","Submit a fix that returns the values the visible tests expect.","Protected variants fail; the challenge is not scored as fully passed."),
("FR-OSS-005",2,"Wrong target (R3)","Open a PR against the wrong repository and the wrong base branch.","Not treated as a submission; the student is told why."),
("FR-OSS-006",2,"Fork-PR secret access (R3)","A PR workflow tries to print repository secrets and obtain a write token.","Secrets are empty and write access is denied."),
("FR-OSS-007",2,"Webhook forgery, replay, disorder (R3)","Send a delivery with a bad signature, a replayed delivery ID and events in reverse order.","Bad signature rejected; replay deduplicated; final PR state is correct; no PR code is run in the request."),
("FR-OSS-016",2,"No duplicate points (R3)","Deliver the same qualifying PR state twice, and re-run checks without a new head commit.","Points awarded once."),
]
detail = {}
errors = []
for rid, nn, *rest in D:
    if rid not in req: errors.append(f"detail case for unknown requirement {rid}"); continue
    detail.setdefault(rid, []).append((nn, *rest))
for rid, cs in detail.items():
    nums = sorted(c[0] for c in cs)
    if len(set(nums)) != len(nums): errors.append(f"{rid}: duplicate case numbers")
    start = 1 if nums[0] == 1 else 2   # -01 is the baseline unless a detailed -01 replaces it
    if nums != list(range(start, start + len(nums))): errors.append(f"{rid}: case numbers not contiguous: {nums}")

committed = [r for r, v in req.items() if v["rel"] in ("MVP", "R2", "R3")]
cases = {}   # tc id -> info
for r in committed:
    v = req[r]
    sprint, st = story.get(r, ("?", "?"))
    if sprint == "?": errors.append(f"{r} is not in any backlog story")
    base_overridden = any(c[0] == 1 for c in detail.get(r, []))
    if not base_overridden:
        cases[f"TC-{r}-01"] = dict(req=r, title="Baseline: " + v["text"], steps="As described by the requirement.", exp=v["text"], base=True)
    for nn, title, steps, exp in detail.get(r, []):
        cases[f"TC-{r}-{nn:02d}"] = dict(req=r, title=title, steps=steps, exp=exp, base=False)

prose = open("tools/test_plan_prose.md", encoding="utf-8").read()
for m in re.finditer(r"TC-((?:FR|NFR)-[A-Z]+-\d{3})-(\d{2})", prose):
    if m.group(0) not in cases: errors.append(f"prose references missing test case {m.group(0)}")
for m in re.finditer(r"\b((?:FR|NFR)-[A-Z]+-\d{3})\b", prose):
    if m.group(1) not in req: errors.append(f"prose references unknown requirement {m.group(1)}")
for t in set(re.findall(r"\bTBD-\d{2}\b", prose)):
    if t not in srs: errors.append(f"prose references unknown decision {t}")

if errors:
    print("TEST PLAN FAILED:"); [print(" -", e) for e in errors]; sys.exit(1)

esc = lambda s: s.replace("|", "\\|").replace("\n", " ")
# Section 10: detailed cases
out10 = ["# 10. Detailed Test Cases", "",
 "These cases add concrete data and results to the baseline case of each requirement listed. All other requirements are covered by their baseline case in Section 11. Fixtures (`FX-nn`) and hostile cases (`H-nn`) are defined in Sections 4 and 5.", "",
 "| Test case | Title | Steps and data | Expected result |", "|---|---|---|---|"]
for rid in req:
    for nn, title, steps, exp in sorted(detail.get(rid, [])):
        out10.append(f"| TC-{rid}-{nn:02d} | {esc(title)} | {esc(steps)} | {esc(exp)} |")
detail_n = sum(len(v) for v in detail.values())

# Section 11: counts + catalogue
areas = list(OrderedDict.fromkeys(req[r]["area"] for r in committed))
out11 = ["# 11. Test Case Catalogue (generated)", "", "<!--CAT-BEGIN-->", "", "### Counts", "",
 "| Area | Requirements | Test cases | T | I | A | D |", "|---|---:|---:|---:|---:|---:|---:|"]
tot = Counter()
for a in areas:
    rs = [r for r in committed if req[r]["area"] == a]
    tcs = [t for t, c in cases.items() if req[c["req"]]["area"] == a]
    m = Counter(req[r]["ver"] for r in rs)
    out11.append(f"| {a} | {len(rs)} | {len(tcs)} | {m['T']} | {m['I']} | {m['A']} | {m['D']} |")
    tot.update(requirements=len(rs), cases=len(tcs), T=m["T"], I=m["I"], A=m["A"], D=m["D"])
out11.append(f"| **All** | **{tot['requirements']}** | **{tot['cases']}** | **{tot['T']}** | **{tot['I']}** | **{tot['A']}** | **{tot['D']}** |")
later = [r for r, v in req.items() if v["rel"] == "LATER"]
out11 += ["", f"Requirements tagged LATER ({len(later)}) have no test cases until promoted by change control.", "",
 "### Catalogue", "",
 "Status starts as **Not run**. Update results in the test management record; a requirement is verified only with a recorded pass.", "",
 "| Test case | Requirement | Method | Level | Sprint | Story | Release | Pass criterion | Status |", "|---|---|---|---|---|---|---|---|---|"]
for t, c in cases.items():
    r = c["req"]; v = req[r]; sp, st = story[r]
    out11.append(f"| {t} | {r} | {METHOD[v['ver']]} | {LEVEL[v['area']]} | {sp} | {st} | {v['rel']} | {esc(c['exp'])} | Not run |")
out11 += ["", "<!--CAT-END-->"]

doc = prose.replace("<!--DETAIL-->", "\n".join(out10)).replace("<!--CATALOGUE-->", "\n".join(out11))
open("docs/main/test_plan_v1.md", "w", encoding="utf-8").write(doc + "\n")
print(f"OK: {len(committed)} committed requirements, {len(cases)} test cases ({detail_n} detailed), {len(later)} LATER excluded")
