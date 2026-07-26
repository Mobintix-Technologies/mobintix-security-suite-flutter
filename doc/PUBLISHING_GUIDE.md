# Publishing Guide — Mobintix Security Suite

This guide covers pub.dev setup, first publish, and CI/CD auto-publish.

---

## Private repository and public demo

- The **library** GitHub repository (`mobintix_security_suite`) may be **private**. Consumers install **only from [pub.dev](https://pub.dev/packages/mobintix_security_suite)**.
- **Issues, discussions, and integration help** for external developers are tracked on the **public** **[mobintix_security_suite_demo](https://github.com/Mobintix-Technologies/mobintix-security-suite-flutter-demo)** repository (`issue_tracker` in `pubspec.yaml` points there).
- The **demo** app should depend on **semver** packages from pub.dev (not `path:`) so a standalone clone of the demo works with `flutter pub get`.
- Maintainers working in the **monorepo** can use a gitignored **`pubspec_overrides.yaml`** (see `pubspec_overrides.yaml.example` in this package and in the demo) to point at local paths for `mobintix_ui_kit` / `mobintix_security_suite` until changes are published.

---

## Table of Contents

1. [Create a pub.dev Account](#1-create-a-pubdev-account)
2. [First-Time Local Publish](#2-first-time-local-publish)
3. [Set Up Trusted Publishing (GitHub Actions)](#3-set-up-trusted-publishing-github-actions)
4. [CI/CD Workflow Overview](#4-cicd-workflow-overview)
5. [Releasing a New Version](#5-releasing-a-new-version)
6. [Manual Version Bump (Without CI)](#6-manual-version-bump-without-ci)
7. [Troubleshooting](#7-troubleshooting)
8. [Screenshots for pub.dev](#8-screenshots-for-pubdev)

---

## 1. Create a pub.dev Account

### Step 1: Go to pub.dev

Open [https://pub.dev](https://pub.dev) in your browser.

### Step 2: Sign in with Google

1. Click **Sign in** (top-right corner).
2. Sign in with the **Google account** you want associated with your packages.
3. Accept the pub.dev terms of service.

### Step 3: (Optional) Create a Verified Publisher

1. Go to [https://pub.dev/create-publisher](https://pub.dev/create-publisher).
2. Enter your publisher domain (e.g., `mobintix.com`).
3. Add the DNS TXT record pub.dev provides, wait for propagation, and click **Verify**.
4. Transfer packages to this publisher from the package Admin tab.

### Step 4: Authenticate Locally

```bash
dart pub login
dart pub token list   # verify
```

---

## 2. First-Time Local Publish

The first publish **must** be done locally to establish package ownership.

### Pre-publish Checklist

```bash
cd /path/to/mobintix_security_suite

flutter pub get
flutter analyze --fatal-infos
flutter test
dart format --set-exit-if-changed lib/ test/
dart pub publish --dry-run
```

### Publish

```bash
dart pub publish
```

### (Optional) Transfer to Verified Publisher

1. Go to your package page on pub.dev → **Admin** tab.
2. Under "Publisher", click **Transfer to publisher** → select `mobintix.com`.

---

## 3. Set Up Trusted Publishing (GitHub Actions)

Trusted publishing uses OIDC — no secrets needed.

### Step 1: Package Admin on pub.dev

1. Open `https://pub.dev/packages/mobintix_security_suite`
2. Click the **Admin** tab.

### Step 2: Enable Automated Publishing

1. Scroll to **Automated publishing**.
2. Click **Enable publishing from GitHub Actions**.
3. Fill in:

| Field | Value |
|---|---|
| **Repository** | `Mobintix-Technologies/mobintix-security-suite-flutter` |
| **Tag pattern** | `v[0-9]+.[0-9]+.[0-9]+*` (e.g. `v0.0.1`, `v1.0.0-beta.1`) — same as mobintix_ui_kit |
| **Require environment** | Leave empty |

4. Click **Save**.

### Step 3: Test

```bash
git tag v0.0.1
git push origin v0.0.1
```

Check GitHub → Actions → the **Publish to pub.dev** workflow should run.

---

## 4. CI/CD Workflow Overview

Same **three-workflow** layout as **[mobintix_ui_kit](https://github.com/Mobintix-Technologies/mobintix-ui-kit-flutter)** (no `example/` here — use **mobintix_security_suite_demo** as the runnable app):

### `ci.yml` — Continuous integration

```
Triggers: Push to main/develop, PRs to main
```

| Step | Command |
|---|---|
| Install deps | `flutter pub get` |
| Check format | `dart format --set-exit-if-changed lib/ test/` |
| Analyze | `flutter analyze --fatal-infos` |
| Test | `flutter test --coverage` |
| Dry-run | `dart pub publish --dry-run` |

### `release.yml` — Version bump & tag (manual only)

```
Triggers: workflow_dispatch only — do not add push: or it will duplicate CI
```

1. Bumps `pubspec.yaml` and prepends a **Keep a Changelog**–style entry to `CHANGELOG.md`
2. Commits, tags `vX.Y.Z`, pushes (tag triggers **publish.yml**)
3. Creates a GitHub Release

### `publish.yml` — Publish to pub.dev

```
Triggers: Push of semver tag v* (e.g. v0.0.1)
```

1. Format, analyze, test
2. `dart pub publish --force` with OIDC (trusted publishing on pub.dev)

### Flow

```
  Actions → Release & Version Bump → Run workflow
         │
         ▼
  ┌─────────────────┐
  │  release.yml     │
  │  Bump + tag      │
  └────────┬─────────┘
           │ tag push
           ▼
  ┌─────────────────┐
  │  publish.yml     │
  │  Publish pub.dev │
  └─────────────────┘
```

---

## 5. Releasing a New Version

### Using GitHub Actions (Recommended)

1. Go to GitHub → **Actions** tab.
2. Click **Release & Version Bump** in the sidebar (same as mobintix_ui_kit).
3. Click **Run workflow** → choose branch (usually `main`).
4. Select bump type:

| Type | When | Example |
|---|---|---|
| **patch** | Bug fixes, small tweaks | 0.0.1 → 0.0.2 |
| **minor** | New features, non-breaking | 0.0.2 → 0.1.0 |
| **major** | Breaking API changes | 0.1.0 → 1.0.0 |

5. (Optional) Enter pre-release label (`beta`, `rc.1`).
6. Click **Run workflow**. When the tag is pushed, **Publish to pub.dev** runs automatically—wait for that workflow to finish.
7. Verify on pub.dev: `https://pub.dev/packages/mobintix_security_suite`

---

## 6. Manual Version Bump (Without CI)

```bash
# 1. Update version in pubspec.yaml
# 2. Update CHANGELOG.md

git add pubspec.yaml CHANGELOG.md
git commit -m "chore: release v0.0.2"
git tag v0.0.2
git push origin main --tags
```

If trusted publishing is configured, the tag push triggers auto-publish.
Otherwise: `dart pub publish`.

---

## 7. Troubleshooting

### "Package validation found the following error"

Run `dart pub publish --dry-run` and fix all listed errors.

### "Authentication failed" in CI

- Verify trusted publishing is configured on pub.dev Admin → Automated publishing.
- Repository name must match exactly (`Mobintix-Technologies/mobintix-security-suite-flutter`).
- Tag pattern must match the workflow (semver-style tags like `v0.0.1`; see `publish.yml`).
- `publish.yml` must have `permissions: id-token: write`.

### "Pub score is low"

- Add `///` doc comments to all public APIs.
- Run `flutter pub upgrade` to keep deps current.
- Link the **public demo** in README (this package does not ship an `example/` folder; pub.dev scoring may still reward API docs and tests).

---

## 8. Screenshots for pub.dev

The repo lists **four PNGs** under **`screenshots/`** in **`pubspec.yaml`** → **`screenshots:`**, similar to [mobintix_ui_kit](https://pub.dev/packages/mobintix_ui_kit).

Canonical filenames (must match **`pubspec.yaml`** unless you change both). Match **screen content**, not only tab order (see **[mobintix_security_suite_demo](https://github.com/Mobintix-Technologies/mobintix-security-suite-flutter-demo)** README).

| File | Tab | What the PNG should show |
|------|-----|---------------------------|
| **`screenshots/mpin.png`** | MPIN | Verify (or create) MPIN with keypad and PIN dots |
| **`screenshots/otp.png`** | OTP | After “Send OTP”: SMS-style banner, six-digit entry, countdown |
| **`screenshots/biometric.png`** | Biometric | Authenticate screen when enrolled (fingerprint + CTA) |
| **`screenshots/face.png`** | Face | Live camera, oval guide, Face Authentication / Verify |

Workflow:

1. Run **[mobintix_security_suite_demo](https://github.com/Mobintix-Technologies/mobintix-security-suite-flutter-demo)** on a device or emulator (see that repo’s README — *Screenshot reference* and *For maintainers*).
2. Capture the correct screen for each filename (see table above; order of tabs is **not** enough — e.g. OTP needs the code-entry screen, not MPIN).
3. Copy the four PNGs into **`mobintix_security_suite/screenshots/`** and, for the public gallery, into **`mobintix_security_suite_demo/screenshots/`** (same names in both repos).
4. Run **`dart pub publish --dry-run`** before publishing.

Each file must be **under 8 MB**.

---

## Quick Reference

| Task | Command / Action |
|---|---|
| Login to pub.dev | `dart pub login` |
| Check before publish | `dart pub publish --dry-run` |
| First publish | `dart pub publish` |
| Release new version | GitHub Actions → **Release & Version Bump** → Run workflow |
| Check pub score | `https://pub.dev/packages/mobintix_security_suite/score` |
| View package | `https://pub.dev/packages/mobintix_security_suite` |
