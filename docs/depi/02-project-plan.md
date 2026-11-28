# 02 — Project Plan

**Project:** Sufra (سفرة)
**Group:** HRV | #17 | ONL5_SWD8_G1 | DEPI5
**Track:** Cross-Platform Mobile Development

> **Timeline status: proposed reconstruction.** Dates are anchored to the official DEPI deadlines and the repository's real commit history (initial commit 7 Oct 2026, auth-flow merge 8 Nov, milestone 1 merge 27 Nov). Day-level task boundaries are a proposed reconstruction for the discussion, to be confirmed by the team.

---

## 1. Timeline (Gantt)

```mermaid
gantt
    title Sufra project timeline (proposed, anchored to DEPI deadlines and real commits)
    dateFormat YYYY-MM-DD
    axisFormat %d %b

    section Planning
    Project proposal & scope           :p1, 2026-10-01, 2026-10-07
    Initial repository & structure     :milestone, ms0, 2026-10-07, 0d
    Requirements & stakeholder draft   :p2, 2026-10-07, 2026-10-16
    DEPI deadline Planning + Requirements  :milestone, ms1, 2026-10-16, 0d

    section Analysis & Design
    Design system (31 screens, HTML)   :d1, 2026-10-16, 2026-10-30
    Architecture & data modeling       :d2, 2026-10-20, 2026-11-06
    DEPI deadline Analysis and Design        :milestone, ms2, 2026-11-06, 0d

    section Implementation
    Auth flow (first prototype)        :i1, 2026-11-07, 2026-11-08
    Core app: logging, diary, tracking :i2, 2026-11-08, 2026-11-20
    AI services: coach + food vision   :i3, 2026-11-15, 2026-11-26
    Full review, fixes, security pass  :i4, 2026-11-26, 2026-11-28
    Milestone 1 merged (main)          :milestone, ms3, 2026-11-27, 0d
    DEPI deadline Implementation           :milestone, ms4, 2026-11-30, 0d

    section Final
    Documentation set completion       :f1, 2026-11-28, 2026-12-02
    Physical-device QA                 :f2, 2026-11-28, 2026-12-02
    Presentation + infographic         :f3, 2026-11-28, 2026-12-03
    DEPI deadline Final presentation :milestone, ms5, 2026-12-04, 0d
```

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
