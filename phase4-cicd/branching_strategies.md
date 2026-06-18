# Enterprise Branching Strategies & PR Guidelines

Modern MNCs rely on clean branching strategies to maintain stable codebases while enabling multiple teams to push code continuously. Understanding these workflows is essential for DevOps Engineers.

---

## Strategy 1: Trunk-based Development (Highly Recommended)
Used by high-velocity organizations (e.g. Amazon, Google, Netflix) to achieve true Continuous Integration (CI).

### Concept
- Developers push code directly to a single core branch (`main` or `trunk`) via short-lived **Feature Branches** (lasting no more than 1-2 days).
- Merges are small and frequent.
- **Feature Flags** (toggle configurations) are used to hide unreleased features, avoiding the need for long-running staging branches.

### Workflow Diagram
```text
           [Feature 1] -----\
  --------(Trunk / Main)-----+------------(Deploy to Production)
           [Feature 2] -------------/
```

### Advantages
- Eliminates "Merge Hell" (resolving giant conflict branches).
- Ensures code in `main` is always in a deployable state.
- Highly compatible with automated testing and continuous deployment (CD).

---

## Strategy 2: Gitflow (Traditional Release Cycle)
Common in organizations with scheduled release cycles, compliance mandates, or external clients.

### Concept
- Multiple long-lived branches exist:
  - `main`: Production-ready code only.
  - `develop`: Integration branch for features.
  - `feature/*`: Independent features branched from `develop`.
  - `release/*`: Release candidate branches for stabilization testing.
  - `hotfix/*`: Quick production fixes.

### Workflow Diagram
```text
  main:    -----------------------------[v1.0.0]-----------------------
                                           /    \
  release:                                /      \ [Release v1.0]
                                         /        \
  develop:   ------------+--------------+----------+-------------------
                        /              /
  feature:  \_[Feature]_/   \_[Feature]/
```

---

## MNC Code Quality & Protection Rules

To protect production systems, MNCs enforce repository constraints (e.g. on GitHub/GitLab):

### 1. Branch Protection Rules
- **Required Approvals**: At least 1-2 senior engineers must approve a Pull Request (PR) before merging.
- **Required Status Checks**: The GitHub Action CI build (linting, tests, container validation) **must pass** before the merge button is unlocked.
- **Signed Commits**: Enforces cryptographic GPG signing of commits to verify author identity.
- **No Force Push**: Disallows `git push --force` on `main` and `develop` branches.

### 2. Semantic Versioning (SemVer)
Workflows are tagged automatically. MNC pipelines parse commit messages using tools like **Semantic Release** (following Conventional Commits standard):
- `feat: add database retry connection` -> Automatically increments MINOR version (`v1.1.0`).
- `fix: crash on nil check` -> Automatically increments PATCH version (`v1.0.1`).
- `feat!: change endpoint structure` (or `BREAKING CHANGE`) -> Increments MAJOR version (`v2.0.0`).
