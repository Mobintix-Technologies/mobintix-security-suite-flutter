# Publishing Guide — Mobintix Security Suite

This guide covers pub.dev setup, first publish, and CI/CD auto-publish.

---

## Private repository and public demo

- The **library** GitHub repository (`mobintix_security_suite`) may be **private**. Consumers install **only from [pub.dev](https://pub.dev/packages/mobintix_security_suite)**.
- **Issues, discussions, and integration help** for external developers are tracked on the **public** **[mobintix_security_suite_demo](https://github.com/Mobintix-Package/mobintix_security_suite_demo)** repository (`issue_tracker` in `pubspec.yaml` points there).
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
| **Repository** | `Mobintix-Package/mobintix_security_suite` |
| **Tag pattern** | `v*` |
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

Three workflows in `.github/workflows/`:

### `ci.yml` — Continuous Integration

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

### `release.yml` — Version Bump & Tag (Manual Trigger)

```
Triggers: Manual dispatch from GitHub Actions UI
```

1. Reads current version from `pubspec.yaml`
2. Bumps it based on selection (patch/minor/major)
3. Updates `pubspec.yaml` and `CHANGELOG.md`
4. Commits `chore: release vX.Y.Z`, creates git tag, pushes
5. Creates a GitHub Release with auto-generated notes

### `publish.yml` — Publish to pub.dev

```
Triggers: When a v* tag is pushed (auto-triggered by release.yml)
```

1. Runs full CI checks (format, analyze, test)
2. Publishes via `dart pub publish --force`
3. Authenticates via OIDC (no secrets)

### Flow

```
  Trigger "Release" workflow (GitHub Actions UI)
         │
         ▼
  ┌─────────────────┐
  │  release.yml     │
  │  Bump version    │
  │  Update CHANGELOG│
  │  Commit & Tag    │
  └────────┬─────────┘
           │ tag push triggers
           ▼
  ┌─────────────────┐
  │  publish.yml     │
  │  Analyze & Test  │
  │  Publish to      │
  │  pub.dev         │
  └─────────────────┘
```

---

## 5. Releasing a New Version

### Using GitHub Actions (Recommended)

1. Go to GitHub → **Actions** tab.
2. Click **Release & Version Bump** in the sidebar.
3. Click **Run workflow**.
4. Select bump type:

| Type | When | Example |
|---|---|---|
| **patch** | Bug fixes, small tweaks | 0.0.1 → 0.0.2 |
| **minor** | New features, non-breaking | 0.0.2 → 0.1.0 |
| **major** | Breaking API changes | 0.1.0 → 1.0.0 |

5. (Optional) Enter pre-release label (`beta`, `rc.1`).
6. Click **Run workflow** and wait for both workflows to complete.
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
- Repository name must match exactly (`Mobintix-Package/mobintix_security_suite`).
- Tag pattern must be `v*`.
- `publish.yml` must have `permissions: id-token: write`.

### "Pub score is low"

- Add `///` doc comments to all public APIs.
- Run `flutter pub upgrade` to keep deps current.
- Link the **public demo** in README (this package does not ship an `example/` folder; pub.dev scoring may still reward API docs and tests).

---

## 8. Screenshots for pub.dev

This package does **not** ship screenshot PNGs yet. They are **optional** for publishing (the package validates without them) but improve the **pub score** and listing, same idea as [mobintix_ui_kit](https://pub.dev/packages/mobintix_ui_kit).

### How to add them

1. Run the public **[mobintix_security_suite_demo](https://github.com/Mobintix-Package/mobintix_security_suite_demo)** on a phone or emulator (or Chrome for flows that work on web).
2. Capture a few representative screens (e.g. MPIN, OTP, biometric, face verification). Use a consistent **light** theme and readable resolution (roughly **1280×720** or similar is fine; each file must be **under 8 MB**).
3. Save PNGs under **`screenshots/`** in this repo (this folder is reserved for that purpose).
4. Add a top-level **`screenshots:`** block to **`pubspec.yaml`** (sibling of `dependencies:`), for example:

```yaml
screenshots:
  - description: 'MPIN entry with numeric keypad'
    path: screenshots/mpin.png
  - description: 'OTP verification with countdown'
    path: screenshots/otp.png
  - description: 'Biometric authentication'
    path: screenshots/biometric.png
  - description: 'Face verification with camera guide'
    path: screenshots/face.png
```

5. Run **`dart pub publish --dry-run`** — it will fail if any listed path is missing.
6. Commit the PNGs and `pubspec.yaml` change, then publish or tag as usual.

Until those files exist, **omit** the `screenshots:` block so CI and dry-run stay green.

---

## Quick Reference

| Task | Command / Action |
|---|---|
| Login to pub.dev | `dart pub login` |
| Check before publish | `dart pub publish --dry-run` |
| First publish | `dart pub publish` |
| Release new version | GitHub Actions → Release & Version Bump |
| Check pub score | `https://pub.dev/packages/mobintix_security_suite/score` |
| View package | `https://pub.dev/packages/mobintix_security_suite` |
