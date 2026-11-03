#!/usr/bin/env python3
"""Build backlog_v1.md and backlog_v1.csv from srs_v1.md and the story map below.
Fails if any requirement of MVP/R2/R3 is unassigned, assigned twice, or placed in a story of another release."""
import re, csv, sys

srs = open("docs/main/srs_v1.md", encoding="utf-8").read()
rows = re.findall(r"^\|\s*((?:FR|NFR)-[A-Z]+-\d{3})\s*\|\s*(.+?)\s*\|\s*(MVP|R2|R3|LATER)\s*\|\s*([TIAD])\s*\|\s*$", srs, flags=re.M)
req = {r[0]: {"text": r[1], "rel": r[2]} for r in rows}

def ids(spec):
    """'FR-AUTH-001..009' or 'NFR-SEC-004' -> list"""
    out = []
    for part in spec.split(","):
        part = part.strip()
        m = re.match(r"^((?:FR|NFR)-[A-Z]+)-(\d{3})(?:\.\.(\d{3}))?$", part)
        assert m, part
        a, lo, hi = m.group(1), int(m.group(2)), int(m.group(3) or m.group(2))
        out += [f"{a}-{n:03d}" for n in range(lo, hi + 1)]
    return out

# (sprint, release, story id, title, user story, requirement spec)
S = [
# ---- Sprint 1
(1,"MVP","US-01","Sign in with Google","As a student, I can sign in with my Google account through my browser, so that I do not create a new password.","FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006"),
(1,"MVP","US-02","Privacy notice, consent and age check","As a student, I see what data is collected and agree before I continue, so that I stay in control of my data.","FR-PROF-001, FR-PROF-010"),
(1,"MVP","US-03","Create and manage my profile","As a student, I can set my name and optional college details, and only I can see them.","FR-PROF-002..008"),
(1,"MVP","US-04","Request data export or deletion","As a student, I can ask for my data to be exported or deleted, and the action is audited.","FR-PROF-009, NFR-SEC-013"),
(1,"MVP","US-05","Backend foundation (technical enabler)","As the team, we have an API contract, structured logs with correlation IDs, database migrations and generated traceability, so that later work stays consistent.","NFR-MAINT-001, NFR-MAINT-004, NFR-MAINT-006, NFR-TEST-003"),
# ---- Sprint 2
(2,"MVP","US-06","Browse the lab catalogue","As a student, I can see available labs with difficulty, prerequisites and supported systems.","FR-CAT-001..003"),
(2,"MVP","US-07","Download and cache a verified lab bundle","As a student, I can download a lab, trust that it is unmodified, and open it offline.","FR-CAT-004, FR-CAT-007, FR-CAT-008"),
(2,"MVP","US-08","Keep my attempt on one lab version","As a student, my attempt does not change when a new lab version is published, and I am told a newer one exists.","FR-CAT-005, FR-CAT-006"),
(2,"MVP","US-09","Author a lab as files with CI checks","As a content author, I write a lab as files and CI proves the starter fails, the reference solution passes and results are repeatable.","FR-CONT-001..005, NFR-MAINT-002, NFR-LEGAL-002"),
(2,"MVP","US-10","Publish, roll back and record content","As an operator, I approve a lab, publish an immutable version, roll back by republishing, and keep a record of who published what.","FR-CONT-006..009, NFR-MAINT-003, NFR-LEGAL-001"),
# ---- Sprint 3
(3,"MVP","US-11","See whether my computer is ready","As a student, I see which tools are ready, missing or incompatible, and nothing is reinstalled needlessly.","FR-ENV-001..003, FR-ENV-009, FR-ENV-012, FR-ENV-013"),
(3,"MVP","US-12","Approve and run setup safely","As a student, I review a setup plan and consent before anything is installed, and nothing runs with permanent admin rights.","FR-ENV-004..006, FR-ENV-011, NFR-SEC-009, NFR-SEC-010"),
(3,"MVP","US-13","Create the project environment and recover from failure","As a student, my project environment is created from the lab's lockfile, checked afterwards, and failures explain how to recover.","FR-ENV-007, FR-ENV-008, FR-ENV-010"),
(3,"MVP","US-14","Work on Windows and a second OS","As a student on a supported OS, the core flow works the same way.","NFR-PORT-001..003, NFR-PORT-005"),
# ---- Sprint 4
(4,"MVP","US-15","Open the lab workspace","As a student, I get an editor, terminal and my guide side by side, chosen by the lab.","FR-WS-001..005, NFR-MAINT-005"),
(4,"MVP","US-16","Run lab tasks with limits","As a student, I can run lab tasks that have time and output limits, and stop them at any time.","FR-EXEC-001..003, FR-EXEC-005, FR-EXEC-006, FR-EXEC-009, NFR-SEC-002, NFR-SEC-003"),
(4,"MVP","US-17","Stay in control of what runs","As a student, nothing risky or AI-proposed runs without my approval, and I am told which commands are tracked.","FR-EXEC-004, FR-EXEC-007, FR-EXEC-008"),
(4,"MVP","US-18","Responsive interface","As a student, the interface stays responsive and shows progress during long operations.","NFR-PERF-003, NFR-PERF-004"),
# ---- Sprint 5
(5,"MVP","US-19","Follow a step-by-step guide","As a student, I follow ordered steps with copyable snippets and explanations, and can revisit completed steps.","FR-GUIDE-001..005, FR-GUIDE-007"),
(5,"MVP","US-20","Check my own work locally","As a student, I can run practice checks and understanding checks, clearly labelled as unverified.","FR-GUIDE-006, FR-GUIDE-008"),
(5,"MVP","US-21","Save and recover my progress","As a student, my progress is saved after every step and survives a crash.","FR-PROG-001..003, NFR-REL-001, NFR-REL-002"),
(5,"MVP","US-22","Sync progress and work offline","As a student, my progress syncs without duplicates, I can work offline, and I can continue on another device.","FR-PROG-004..007, NFR-REL-003, NFR-PERF-006, NFR-PERF-007"),
# ---- Sprint 6
(6,"MVP","US-23","Ask the tutor with context I control","As a student, I choose what the tutor sees and I give consent before my code is sent to a cloud provider.","FR-AI-001, FR-AI-004, FR-AI-012, FR-AI-014, NFR-PRIV-001, NFR-PRIV-002"),
(6,"MVP","US-24","Get hints that teach, not only answers","As a student, the tutor explains and gives progressive help up to the lab's limit and never claims code is correct.","FR-AI-006..008, FR-AI-016"),
(6,"MVP","US-25","AI through a protected proxy with limits","As the team, AI requests pass through our backend that holds the key and enforces per-student limits.","FR-AI-002, FR-AI-003, FR-AI-013, FR-AI-015, NFR-COST-002, NFR-SEC-015"),
(6,"MVP","US-26","Keep secrets and attacks out of prompts","As a student, secrets are removed before sending, and malicious text in files cannot control the tutor.","FR-AI-005, FR-AI-009, NFR-SEC-005, NFR-PRIV-003"),
(6,"MVP","US-27","Keep working when AI is down","As a student, when AI fails I get a clear message and everything else keeps working.","FR-AI-010, FR-AI-011"),
# ---- Sprint 7
(7,"MVP","US-28","Submit my work for verification","As a student, I review which files are sent, exclude secrets, and upload a snapshot for grading.","FR-GRADE-003, FR-GRADE-004, NFR-SEC-014"),
(7,"MVP","US-29","Grade in an isolated sandbox","As the team, student code runs only in a disposable sandbox with no network and no secrets, away from our data.","FR-GRADE-005, FR-GRADE-006, NFR-SEC-007, NFR-SEC-008"),
(7,"MVP","US-30","Compute official scores on the server","As a student, I get a Verified result computed from the grader's signed output, with per-check feedback that does not reveal tests.","FR-GRADE-001, FR-GRADE-008..011"),
(7,"MVP","US-31","Practice results are labelled","As a student, any result computed on my machine is marked Practice and never counted as official.","FR-GRADE-002"),
# ---- Sprint 8
(8,"MVP","US-32","Reliable and repeatable grading","As a student, resubmitting never doubles my points, grader failures are not held against me, and I see queue status and history.","FR-GRADE-012, FR-GRADE-015..017, NFR-REL-004, NFR-PERF-005, NFR-TEST-002"),
(8,"MVP","US-33","Grader resists cheating and hostile code","As the team, the grader rejects forged results, off-list dependencies and tampered tests, and passes our hostile-submission suite.","FR-GRADE-007, FR-GRADE-018, FR-GRADE-020, FR-GRADE-021"),
(8,"MVP","US-34","Fair scoring rules","As a student, my setup readiness is shown apart from my score, and using the tutor never lowers my score.","FR-GRADE-013, FR-GRADE-014"),
# ---- Sprint 9
(9,"MVP","US-35","Security review before the pilot","As the team, we complete the threat model, dependency scanning and untrusted-input rules.","NFR-SEC-001, NFR-SEC-011, NFR-SEC-012"),
(9,"MVP","US-36","Privacy and legal readiness","As the team, retention, legal review and access rules are approved before real students join.","NFR-PRIV-004..007"),
(9,"MVP","US-37","Usability and accessibility","As a beginner, I can find the next action, use the keyboard, and understand every error.","NFR-UX-001..007"),
(9,"MVP","US-38","Fast start and detection","As a student, the app starts and checks my machine within the target times.","NFR-PERF-001, NFR-PERF-002"),
(9,"MVP","US-39","Backups, degraded mode and rollback","As the team, backups are restored in a rehearsal, outages show clear messages, and bad content can be reversed.","NFR-REL-005..007"),
(9,"MVP","US-40","Cost control","As the team, budgets and alerts exist and we report cost per active student.","NFR-COST-001, NFR-COST-003"),
(9,"MVP","US-41","Every requirement has a test record","As the team, each MVP requirement has a named test or inspection record.","NFR-TEST-001"),
# ---- R2 (sprints 11-12)
(11,"R2","US-R2-1","Browse and filter challenges","As a student, I can find bug-fixing challenges by technology and difficulty and see my attempt history.","FR-CAT-009, FR-CAT-010, FR-PROG-008"),
(11,"R2","US-R2-2","Define and validate a challenge","As a content author, I define a bug challenge from a reviewed repository and CI proves it fails first and passes with the fix.","FR-BUG-001, FR-BUG-002, FR-BUG-012, FR-BUG-013"),
(11,"R2","US-R2-3","Work on a clean copy of buggy code","As a student, I get a clean copy at a pinned commit, can reset it, and the guide opens the right file.","FR-BUG-003, FR-BUG-004, FR-EXEC-010, FR-WS-006, FR-GUIDE-009"),
(12,"R2","US-R2-4","Investigate with the tutor","As a student, the tutor guides me to reproduce, locate and test, without revealing the fix.","FR-BUG-005, FR-BUG-010"),
(12,"R2","US-R2-5","Verified bug-fix grading","As a student, my fix is graded against hidden regression tests and out-of-scope changes are flagged.","FR-BUG-006..009, FR-BUG-011"),
# ---- R3 (sprints 13-15)
(13,"R3","US-R3-1","Check Git readiness","As a student, I see whether Git, my Git identity and my GitHub access are each ready.","FR-GIT-001..005"),
(13,"R3","US-R3-2","Safe branch and remote checks","As a student, I see repository status and the app checks my branch and remote before I open a PR.","FR-GIT-006..009, FR-CAT-011"),
(14,"R3","US-R3-3","Get my own template repository","As a student, I receive a personal practice repository from an approved template with my own issue variant.","FR-OSS-001..003, FR-OSS-014, NFR-LEGAL-003"),
(14,"R3","US-R3-4","Track my pull request","As a student, the platform links my PR to my attempt and I review my PR description before submitting.","FR-OSS-004, FR-OSS-005, FR-OSS-009, FR-OSS-015"),
(15,"R3","US-R3-5","Secure webhooks and CI","As the team, webhooks are verified, duplicate events are ignored, and untrusted PR code never receives secrets.","FR-OSS-006, FR-OSS-007, NFR-SEC-016, NFR-SEC-017"),
(15,"R3","US-R3-6","Points and review","As a student, I earn points from verified PR state, never twice, and maintainers can review or override with a reason.","FR-OSS-008, FR-OSS-010..013, FR-OSS-016, FR-OSS-017"),
(15,"R3","US-R3-7","Third operating system","As a student on a third OS, the core flow works.","NFR-PORT-004"),
]
SPIKES = [
 (0,"SP-01","Electron shell spike (native modules, packaging, terminal)","Closes TBD-01 (resolved as Option B). Pass criteria in SAD Section 4.1 (S1)."),
 (0,"SP-02","Sign-in spike","Closes TBD-02 (S2)."),
 (0,"SP-03","Grader sandbox spike","Closes TBD-03 (S3)."),
 (0,"SP-04","Cost and vendor comparison","Closes TBD-06 and TBD-13 (S4)."),
 (0,"SP-05","Legal review: age policy and retention","Closes TBD-08 and TBD-09 (S5)."),
 (0,"SP-06","Repository, CI skeleton and definition of done","Set up content repo, app repo, CI, and run tools/gen_rtm.py and tools/check_sad.py on each change."),
 (10,"PL-01","Run the pilot (10 to 20 students) and fix findings","Acceptance gates in SRS Section 10.1; no new requirements."),
]

seen = {}
errors = []
for sp, rel, sid, title, story, spec in S:
    for i in ids(spec):
        if i not in req: errors.append(f"{sid}: unknown {i}"); continue
        if req[i]["rel"] != rel: errors.append(f"{sid}: {i} is {req[i]['rel']} but story is {rel}")
        if i in seen: errors.append(f"{i} in {seen[i]} and {sid}")
        seen[i] = sid
for i, r in req.items():
    if r["rel"] in ("MVP","R2","R3") and i not in seen:
        errors.append(f"unassigned {r['rel']} requirement {i}")
if errors:
    print("BACKLOG FAILED:"); [print(" -", e) for e in errors]; sys.exit(1)

def split(spec):
    l = ids(spec)
    return [x for x in l if x.startswith("FR-")], [x for x in l if x.startswith("NFR-")]

with open("docs/backlog/backlog_v1.csv","w",newline="",encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["Sprint","Release","Story ID","Title","User story","Functional requirements","Non-functional requirements","Requirement count"])
    for sp,sid,t,n in SPIKES:
        if sp==0: w.writerow([sp,"-",sid,t,n,"","",0])
    for sp,rel,sid,t,st,spec in S:
        fr,nfr = split(spec)
        w.writerow([sp,rel,sid,t,st,"; ".join(fr),"; ".join(nfr),len(fr)+len(nfr)])
    for sp,sid,t,n in SPIKES:
        if sp==10: w.writerow([sp,"MVP",sid,t,n,"","",0])

out = ["# Product Backlog v1","",
"Generated by `tools/make_backlog.py` from `srs_v1.md`. Each story groups functional (FR) and non-functional (NFR) requirements. A story is done when every listed requirement has a passing `TC-<requirement ID>-<nn>` record.","",
"Assumptions: 2-week sprints, 2 to 3 people, about 20 requirements per sprint (recalibrate after sprints 1 and 2).",""]
by = {}
for sp,rel,sid,t,st,spec in S: by.setdefault(sp,[]).append((rel,sid,t,st,spec))
names = {0:"Sprint 0 - Spikes and setup (no requirements)",10:"Sprint 10 - Pilot (no new requirements)"}
for sp in range(0,16):
    if sp==0:
        out += [f"## {names[0]}","","| ID | Item | Notes |","|---|---|---|"]
        out += [f"| {sid} | {t} | {n} |" for s,sid,t,n in SPIKES if s==0] + [""]
        continue
    if sp==10:
        out += [f"## {names[10]}","","| ID | Item | Notes |","|---|---|---|"]
        out += [f"| {sid} | {t} | {n} |" for s,sid,t,n in SPIKES if s==10] + [""]
        continue
    items = by.get(sp,[])
    total = sum(len(ids(x[4])) for x in items)
    rel = items[0][0]
    out += [f"## Sprint {sp} - {rel}, {total} requirements","","| Story | Title | Functional | Non-functional | Count |","|---|---|---|---|---:|"]
    for rel,sid,t,st,spec in items:
        fr,nfr = split(spec)
        out.append(f"| {sid} | **{t}**<br>{st} | {', '.join(fr) or '-'} | {', '.join(nfr) or '-'} | {len(fr)+len(nfr)} |")
    out.append("")
tot = {r: sum(len(ids(x[5])) for x in S if x[1]==r) for r in ("MVP","R2","R3")}
out += ["## Totals","",f"MVP {tot['MVP']}, R2 {tot['R2']}, R3 {tot['R3']}. Deferred (LATER) requirements are not in this backlog.",""]
open("docs/backlog/backlog_v1.md","w",encoding="utf-8").write("\n".join(out))
per = {}
for sp,rel,*_ ,spec in S: per[sp] = per.get(sp,0)+len(ids(spec))
print("OK", tot, "stories:", len(S))
print({k:v for k,v in sorted(per.items())})
