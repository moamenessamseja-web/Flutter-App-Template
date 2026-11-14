# HTTP-only agent profile (no bash / no git fallback)

Use this when the harness has **no shell, no git, no local filesystem** — only a way to send HTTPS requests (a fetch/URL/web tool) and read JSON. Everything the normal git+bash path does can be done against the GitHub REST API. Owner: `moamenessamseja-web`. Replace `<REPO>`, `<PATH>` and the other placeholders below with real values.

**Requires:** an HTTP tool that can set headers, the method and a JSON body, and a way to base64-encode file content. If it can only GET, it can read and monitor but cannot write.

> If the harness **does** have bash+git, prefer the normal path (clone with the auth header trick in `ACCESS.md`). This file is the fallback, not the default.

## 0. Auth (same rules as everywhere)
- Token comes from the harness secret store / owner, env name `GH_TOKEN` by convention.
- Header on **every** request: `Authorization: Bearer $GH_TOKEN` and `Accept: application/vnd.github+json` and `X-GitHub-Api-Version: 2022-11-28`.
- **Never** put the token in a URL, a file content, a commit message, a PR body, or a log. Never print it.
- Base: `https://api.github.com/repos/moamenessamseja-web/<REPO>`

## 1a. Orient (replaces `orient.sh`, the start gate)
- Gateway docs (public, no token): `GET https://raw.githubusercontent.com/moamenessamseja-web/Flutter-Android-Build/main/<path>`. Read `.agent/README.md`, then `.skills/engineer-in-charge/SKILL.md`, then the other skills the task needs. You cannot run the gate scripts in this mode; this file defines the API equivalents.
- State claim check: `GET /repos/moamenessamseja-web/<REPO>/commits/<branch>` gives the head sha. Compare it with the headline of `.agent/IMPLEMENTATION_STATE.md` in the target repo; if they disagree, trust the code and say so.

## 1. Read a file (and get its SHA for later update)
```
GET /repos/moamenessamseja-web/<REPO>/contents/<PATH>?ref=<branch>
```
- `content` is base64 → decode it. `sha` is required when updating.
- If the repo is public, read works without a token (but write always needs one).

## 2. Create a branch (never work on main)
```
GET  /repos/moamenessamseja-web/<REPO>/git/ref/heads/main        → object.sha  (base commit)
POST /repos/moamenessamseja-web/<REPO>/git/refs
     {"ref":"refs/heads/agent/<short-task>","sha":"<base sha>"}
```
Branch name format: `agent/<short-task>`. If the owner named a different base branch, use its ref instead of `heads/main`.

## 3. Write ONE file (create or update) — simplest path
```
PUT /repos/moamenessamseja-web/<REPO>/contents/<PATH>
{
  "message": "<why, not just what; state 'not run locally'>",
  "content": "<base64 of the new file content>",
  "branch":  "agent/<short-task>",
  "sha":     "<sha from step 1 — required only when updating an existing file>"
}
```
One concern per commit. For several files in one commit, use the Git Data flow in step 4.

## 4. Write MULTIPLE files in one commit (Git Data API)
```
# (a) one blob per file
POST /repos/moamenessamseja-web/<REPO>/git/blobs
     {"content":"<file content, plain utf-8>","encoding":"utf-8"}   → blob.sha

# (b) tree, base_tree = the branch's current tree sha (from the ref object, field .object.sha then GET /git/commits/<sha> → .tree.sha)
POST /repos/moamenessamseja-web/<REPO>/git/trees
     {"base_tree":"<base tree sha>","tree":[
        {"path":"lib/x.dart","mode":"100644","type":"blob","sha":"<blob1 sha>"},
        {"path":".agent/IMPLEMENTATION_STATE.md","mode":"100644","type":"blob","sha":"<blob2 sha>"}
     ]}                                                              → tree.sha

# (c) commit
POST /repos/moamenessamseja-web/<REPO>/git/commits
     {"message":"<why>","tree":"<tree sha>","parents":["<parent commit sha>"]}  → commit.sha

# (d) move the branch
PATCH /repos/moamenessamseja-web/<REPO>/git/refs/heads/agent/<short-task>
     {"sha":"<commit sha>"}
```
Always update `.agent/` memory files (IMPLEMENTATION_STATE / HANDOFF / CHANGELOG) in the same push as the code, via this same multi-file commit.

## 5. Open a Pull Request (this triggers CI via pull_request)
```
POST /repos/moamenessamseja-web/<REPO>/pulls
{"title":"<short>","head":"agent/<short-task>","base":"main","body":"<what + verification level>"}
```
Must be created with the agent's PAT (not `GITHUB_TOKEN`) or CI will not start.

## 6. Trigger / watch the build (equivalent of gh_ci.sh push-run + wait)
```
# dispatch (only if no PR trigger, e.g. you pushed without PR)
POST /repos/moamenessamseja-web/<REPO>/actions/workflows/build-apk.yml/dispatches
{"ref":"agent/<short-task>"}

# poll newest run on the branch (every ~20s, max ~270s per call, then call again)
GET /repos/moamenessamseja-web/<REPO>/actions/runs?branch=agent/<short-task>&per_page=1
    → workflow_runs[0].status / .conclusion / .id / .html_url
# conclusion = success (green) / failure (red) ; status = completed vs still running
# ALWAYS compare workflow_runs[0].head_sha with the commit you just wrote before trusting "success":
# a stale run on the same branch can report green for old code.
```

## 7. Read the result (no artifact download needed for the report)
```
# jobs of the run → take the job id (check_run url contains it)
GET /repos/moamenessamseja-web/<REPO>/actions/runs/<RUN_ID>/jobs
# failure annotations (red build):
GET /repos/moamenessamseja-web/<REPO>/check-runs/<JOB_ID>/annotations
    → keep entries with annotation_level == "failure" (title + message)
# success: the "APK ready" annotation gives applicationId, size, SHA-256, signer fingerprint.
# artifact (APK zip) download link:
GET /repos/moamenessamseja-web/<REPO>/actions/runs/<RUN_ID>/artifacts
    → artifacts[0].archive_download_url  (fetch with the Bearer header, it redirects to a pre-signed URL;
      do not forward the Authorization header to the redirect target. Not verified by the author of this note.)
```

## 8. New app from the template (HTTP only, no git)
```
POST /repos/moamenessamseja-web/Flutter-App-Template/generate
{"owner":"moamenessamseja-web","name":"<app-lowercase-hyphens>","private":false}
```
Wait a few seconds, then continue from step 2 (branch) on the new repo. The template already contains `build-apk.yml` (pinned Flutter), `AGENTS.md`, and a minimal app. Pick the Dart package name first — it becomes `com.moamen.<name>` and cannot change after first install.

## 9. Rules that do NOT change in HTTP-only mode
- Never commit to / push `main`. Always `agent/<task>` branch + PR.
- One concern per commit; commit message says *why* and states what was not run locally.
- Red build: read the failure annotation, fix on the same branch, push, wait. **Three failures with the same cause → stop and report.**
- Report in Arabic, exactly these: repo+PR links, branch, **commit SHA built**, run link, APK download place (run page → Artifacts → android-apk), applicationId, size, signing fingerprint, what was verified vs not, open decisions.
- Verification ladder: read code → local sanity (YAML/bracket balance by eye) → CI green → artifact inspected → owner device-confirmed. Never claim a level you did not reach.
- Ladder unchanged: an HTTP commit is not a green build, and a green build is not "works". Report the level you reached.
- Match the run's `head_sha` to the commit you wrote before trusting `success`.
- Stop gate without bash (equivalent of `stop_gate.py`): before saying "done", confirm through the API that `.agent/IMPLEMENTATION_STATE.md`, `HANDOFF.md` and `CHANGELOG.md` changed in this session's commits (`GET /commits/<sha>` lists the files), that the branch head on GitHub is your last commit, and that STATE carries today's date.

## 10. What already works without this file
`gh_ci.sh push-run / status / wait` are **pure HTTP (curl)** already — translate them 1:1 to your fetch tool. Only `clone` / multi-file `commit` / `push` need steps 2–4 above. Its `log`/`notes`/`download` commands read release assets this pipeline does not produce — use the annotations + artifacts in step 7 instead.
