# 02 — Project Plan

**Project:** Sufra (سفرة)
**Group:** HRV | #17 | ONL5_SWD8_G1 | DEPI5
**Track:** Cross-Platform Mobile Development

> **Timeline status: proposed reconstruction.** Dates are anchored to the official DEPI deadlines and the repository's real commit history (initial commit 7 Oct 2026, auth-flow merge 8 Nov, milestone 1 merge 27 Nov). Day-level task boundaries are a proposed reconstruction for the discussion, to be confirmed by the team.

---

## 1. Timeline (Gantt)

| Phase | Work | Window | Status |
|---|---|---|---|
| Planning | Project proposal & scope | 1-7 Oct 2026 | Done |
| | Initial repository & structure | 7 Oct 2026 | Done |
| | Requirements & stakeholder draft | 7-16 Oct 2026 | Done |
| | **DEPI deadline: Planning + Requirements** | **16 Oct 2026** | **Met** |
| Analysis & Design | Design system (31 screens, HTML) | 16-30 Oct 2026 | Done |
| | Architecture & data modeling | 20 Oct-6 Nov 2026 | Done |
| | **DEPI deadline: Analysis and Design** | **6 Nov 2026** | **Met** |
| Implementation | Auth flow (first prototype) | 7-8 Nov 2026 | Done |
| | Core app: logging, diary, tracking | 8-20 Nov 2026 | Done |
| | AI services: coach + food vision | 15-26 Nov 2026 | Done |
| | Full review, fixes, security pass | 26-28 Nov 2026 | Done |
| | Milestone 1 merged (main) | 27 Nov 2026 | Done |
| | **DEPI deadline: Implementation** | **30 Nov 2026** | **On track** |
| Final | Documentation set completion | 28 Nov-2 Dec 2026 | In progress |
| | Physical-device QA | 28 Nov-2 Dec 2026 | In progress |
| | Presentation + infographic | 28 Nov-3 Dec 2026 | Done |
| | **DEPI deadline: Final presentation & testing** | **4 Dec 2026** | **Scheduled** |

*(A Mermaid Gantt version of this timeline is included in the repository history; it is replaced here with a table because GitHub's embedded Mermaid renderer currently fails on this chart.)*

---

## 2. Milestones

| Milestone | Date | Evidence |
|---|---|---|
| Repository initialized | 7 Oct 2026 | Initial commit on `main` |
| DEPI Planning, Literature Review, Requirements | 16 Oct 2026 | This documentation set, sections 01–06 |
| DEPI System Analysis & Design | 6 Nov 2026 | Design system file + sections 07–11 |
| Auth prototype merged | 8 Nov 2026 | PR #1 (`feature/sofrah-auth-screens`) |
| Milestone 1: complete core experience | 27 Nov 2026 | PR #2 merge: app, workers, docs, tests |
| DEPI Implementation | 30 Nov 2026 | Repository + README |
| DEPI Final Presentation & Testing | 4 Dec 2026 | Sections 12–15 + presentation + infographic |

---

## 3. Deliverables

| # | Deliverable | Where |
|---|---|---|
| D1 | Flutter application (6 platforms, one codebase) | `lib/`, platform folders |
| D2 | Backend: 4 Cloudflare Workers | `backend/` |
| D3 | Interactive design system, 31 screens | `design/Sufra_Design_UI_fast.html` |
| D4 | Automated tests (292 Dart files + worker suites) | `test/`, `backend/` |
| D5 | Documentation set (this folder) | `docs/depi/` |
| D6 | Final presentation (PDF) | `docs/depi/15-presentation.pdf` |
| D7 | Project infographic (single 16:9 image) | `docs/depi/assets/infographic.png` |
| D8 | User manual (Arabic) | `docs/depi/13-user-manual.md` |

---

## 4. Resource Allocation

| Resource | Allocation |
|---|---|
| Team | 6 members, screen-based ownership (see 03 Task Assignment & Roles) |
| Compute | Free tiers only: Firebase Spark, Cloudflare Workers + Workers AI free allocations |
| Data | Open Food Facts, USDA FoodData Central (free public databases) |
| Tooling | Flutter 3.35.7, Dart 3.9.2, Node (worker tests), Git/GitHub, wrangler CLI |
| Budget | $0 by design; quotas enforced as hard ceilings in code |

**Time-risk buffer:** the final week (28 Nov – 4 Dec) is reserved for documentation, device QA and the presentation only; no new features are accepted in that window.
