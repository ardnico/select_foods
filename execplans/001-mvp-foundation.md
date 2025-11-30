# MVP foundation for iPad meal planning app

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds. Maintain this document in accordance with `.agent/PLANS.md`.

## Purpose / Big Picture

Enable an offline-first iPad meal-planning app that lets a user set a date range, assign lunch/dinner menus per day, and view aggregated shopping ingredients. At completion of this plan, someone can run the SwiftUI app, pick a 7-day window, assign menus from predefined samples filtered by type, and see a combined ingredient list. This fulfills the MVP scope in `PROJECT_PLAN.md` (Phase 1–3 plus essential parts of Phase 4).

## Progress

- [x] (2025-01-06 00:00Z) Draft initial ExecPlan aligned with PROJECT_PLAN.md.
- [x] (2025-01-06 01:15Z) Set up SwiftUI-oriented source layout under `src/` with app entry and unit test target folder.
- [x] (2025-01-06 01:40Z) Defined domain models (Plan, PlanDay, Menu, MenuType, MenuTypeSet, Ingredient, MenuIngredient, IngredientTotal, MealSlot) with validation helpers and sample data.
- [x] (2025-01-06 02:00Z) Added in-memory Plan/Menu repositories with seed data and type sets, exposing Combine publishers.
- [x] (2025-01-06 02:20Z) Built PlanStore/MenuStore with date-range updates, menu assignment, filtering, and ingredient aggregation plus an initial aggregation unit test scaffold.
- [x] (2025-01-06 02:45Z) Created SwiftUI views for period selection, daily plan slots, menu picker with filters, ingredient summary, and menu management wired to stores.
- [x] (2025-01-06 03:10Z) Added minimal validation (trimmed names/units, positive quantities) and documented offline-only assumptions for simulator use.
- [x] (2025-11-30 09:05Z) Added SwiftPM packaging with Linux-friendly Combine shim/SwiftUI guards and executed `swift test` successfully.
- [x] (2025-11-30 09:20Z) Added unit test covering date-range rebuild and reassignment reset when shrinking the planning window.
- [x] (2025-11-30 09:35Z) Added MenuStore tests for filter behavior and menu validation to cover UI-critical flows without simulator access.
- [x] (2025-11-30 09:50Z) Added PlanStore aggregation test to ensure invalid or zero-quantity ingredients are ignored when summing totals.
- [x] (2025-11-30 10:05Z) Fixed plan rebuild to preserve in-range assignments while dropping out-of-range ones and added regression test.
- [x] (2025-11-30 10:20Z) Added deterministic ingredient ordering that keeps same-name ingredients with different units separate and covered the behavior with a regression test.
- [x] (2025-11-30 10:35Z) Added menu-slot clearing from the picker, dismissed the picker after selection, and covered clearing with a regression test.
- [ ] Manual walkthrough verifying period change, menu assignment, filtering, and ingredient aggregation.
- [ ] Update Outcomes & Retrospective with learnings and finalize plan.

## Surprises & Discoveries

- Observation: Swift toolchain is unavailable in the Linux container, so compilation and previews cannot be exercised here.
  Evidence: Will need simulator or macOS Xcode to run; tests were previously unexecuted in this environment.
- Observation: Added a lightweight Combine shim and SwiftUI compile guards to allow `swift test` to run in Linux CI while keeping the iPad UI code for macOS/iOS builds.
  Evidence: `swift test` now passes in the container with aggregation test succeeding (2025-11-30).
- Observation: Validation now filters out empty ingredient names/units and non-positive quantities before persistence, so manual testing must include invalid input attempts on simulator.
  Evidence: MenuStore guards on `Menu.isValid` and `MenuIngredient.isValid` and ignores invalid saves.
- Observation: Plan rebuild previously wiped all assignments on any date-range change, even those still in range; preserving in-range slots prevents accidental data loss when shrinking windows.
  Evidence: Added regression test showing a shrink keeps assignments on overlapping days while dropping out-of-range ones (2025-11-30).
- Observation: Ingredient totals were sorted only by name, which could reorder same-name items with different units unpredictably; tie-breaking by unit yields deterministic output for the summary view.
  Evidence: Added ordering test that asserts separate salt entries (g, 小さじ) remain distinct and stable (2025-11-30).

## Decision Log

- Decision: Use in-memory repositories first with a protocol boundary to swap in Core Data later.
  Rationale: Accelerates MVP without blocking on storage setup while aligning with PROJECT_PLAN.md offline requirement.
  Date/Author: 2025-01-06 / agent
- Decision: Introduce SwiftPM package with Linux-safe Combine shim and SwiftUI guards so unit tests compile in non-Apple environments.
  Rationale: Enables CI/test execution in this container while preserving app code for iOS builds.
  Date/Author: 2025-11-30 / agent
- Decision: Preserve menu assignments that remain within the new date range when rebuilding PlanDays, dropping only out-of-range slots.
  Rationale: Aligns with user expectation that changing the window should not delete still-relevant selections.
  Date/Author: 2025-11-30 / agent
- Decision: Sort ingredient totals by name then unit to keep same-name ingredients with different units distinct and deterministic in summaries.
  Rationale: Prevents unstable ordering when displaying or asserting against aggregated lists that include mixed units.
  Date/Author: 2025-11-30 / agent
- Decision: Allow clearing an assigned menu slot directly from the picker and auto-dismiss the sheet after any choice.
  Rationale: Users need an escape hatch to unset mistaken assignments without extra taps, and selections should immediately close the picker to confirm the change.
  Date/Author: 2025-11-30 / agent

## Outcomes & Retrospective

- Minimal validation is in place for menus and ingredients with offline-only repositories. `swift test` now passes in the Linux container using the Combine shim, confirming aggregation logic. Still need simulator run to confirm UI behavior and complete remaining acceptance steps.
- Added a regression test for date-range shrinking to ensure plan days rebuild cleanly and previous assignments are cleared when outside the new window. Still blocked on manual simulator walkthrough for UI verification.
- Added MenuStore coverage for filtering and validation to mirror expected picker behavior; remain unable to validate gestures or layout without a simulator.
- Added PlanStore coverage that proves aggregation skips invalid ingredients and zero/negative quantities, reinforcing data hygiene in the absence of UI validation.
- Adjusted PlanStore date-range rebuild to keep in-range assignments and documented the prior data-loss hazard; regression test now guards this flow.
- Added deterministic ordering for ingredient totals that keeps mixed-unit entries separate and documented the stability requirement for summary displays.

## Context and Orientation

The repository currently has empty `src/` and `tests/` directories. This plan introduces a SwiftUI iPad app targeting iPadOS 17 with offline data. Core code will live under `src/` (app target) and `tests/` (unit tests). No prior ExecPlans exist.

Key entities from `PROJECT_PLAN.md`:
- Plan/PlanDay: represent the selected date range and per-day lunch/dinner menu slots.
- Menu/MenuType/MenuTypeSet: menu items, their single type (e.g., 和食/洋食), and predefined filter sets (e.g., 和食中心/時短/ヘルシー).
- Ingredient/MenuIngredient: materials with quantities and units assigned to a menu.

Critical behaviors:
- Date range changes rebuild PlanDays and drop out-of-range assignments (M1).
- Each day stores lunch and dinner menus (M2).
- Menus can be filtered by type and type sets when picking (M3, M4).
- Aggregation sums ingredients by (name, unit) across the selected period (M5).
- Views show the period schedule and ingredient list (M6), plus a simple menu manager with seed data (M7).
- Offline assumption: all data is local/in-memory; no network calls occur. Simulator/iPad should be set to iPadOS 17 with persistence limited to the session.

## Plan of Work

1. Initialize a Swift package/Xcode project suitable for SwiftUI iPad app with a companion test target. Place source under `src/` and tests under `tests/`. Configure a main App entry targeting iPadOS 17.
2. Define domain models in `src/Domain/` as plain Swift structs/enums with Codable conformance for storage flexibility. Include helper constructors for sample data and equality/hash where needed.
3. Create repository protocols in `src/Data/Repositories/` for PlanRepository, MenuRepository, and IngredientRepository (the latter derived from menus). Provide in-memory implementations with seeded menus, types, and type sets in `src/Data/InMemory/`.
4. Implement stores in `src/Application/Stores/` using `ObservableObject`:
   - `PlanStore` manages current date range, PlanDays, menu assignments, and exposes ingredient aggregation function using repository data.
   - `MenuStore` exposes menus, menu types, type sets, and filtering helpers.
   Add unit tests in `tests/` to verify date-range recalculation and ingredient aggregation.
5. Build SwiftUI views in `src/Presentation/Views/`:
   - PeriodSelectionView: start/end date picker with recomputation trigger.
   - PlanListView: list of days with lunch/dinner slots showing assigned menu names; tapping opens picker.
   - MenuPickerView: list of menus with filters by type and type set toggles; allows assignment to the selected slot.
   - IngredientSummaryView: aggregated list showing ingredient name, total quantity, and unit.
   - MenuManagementView: shows seeded menus and allows adding a simple menu with name/type/ingredients validation.
   Compose them in a root `ContentView` within `SelectFoodsApp` configured for iPad layouts.
6. Add validation rules: block saving menus with empty ingredient names or units; ensure aggregation ignores empty quantities; default serving size for 2–3 people per PROJECT_PLAN.md assumptions.
7. Testing and validation:
   - Write unit tests for aggregation (same name+unit sums; differing units stay separate) and date-range pruning behavior.
   - Manual run on iPadOS 17 simulator: set a 7-day range, assign menus, use filters, view aggregated list. Document observed outputs in this plan.
8. Prepare for persistence swap: note TODOs where Core Data/SQLite can replace in-memory, keeping protocols stable. Document in Outcomes.

## Concrete Steps

Run commands from repository root unless stated.

1. Initialize Swift package/Xcode structure (if SwiftPM usable):
   - `swift package init --type executable` then adjust to SwiftUI/iPadOS target by editing `Package.swift` (or create Xcode project if available). Ensure sources live under `src/` by moving generated files.
2. Create domain and repository Swift files per Plan of Work with namespaces using folders under `src/`.
3. Add SwiftUI app entry and views; update imports (`SwiftUI`, `Foundation`).
4. Add unit tests under `tests/` validating domain logic.
5. Run `swift test` to verify domain logic; run Xcode build if environment allows (`xcodebuild -scheme SelectFoods -destination 'platform=iOS Simulator,name=iPad (10th generation),OS=17.0'`). Capture results in this plan.
6. Update this ExecPlan sections after each milestone, recording discoveries and decisions. Ensure outcomes describe how to observe the MVP behavior.

## Validation and Acceptance

- Automated: `swift test` passes, covering date-range recalculation and ingredient aggregation rules.
- Manual: Launch app (simulator or SwiftUI preview). User can:
  1. Select a start/end date; PlanDays reflect the range and remove out-of-range assignments.
  2. For each day, set lunch/dinner menus using type/type-set filters.
  3. Open ingredient summary to see aggregated totals by (name, unit); confirm sums match assigned menus.
  4. Add a simple menu; it appears in picker and participates in aggregation.
- Acceptance: A novice can follow the app UI to plan 1–2 days and view ingredients within 5 minutes, matching PROJECT_PLAN.md goal G5.

## Idempotence and Recovery

- In-memory repositories reset on app relaunch; safe to re-run tests or restart without cleanup.
- Date-range changes rebuild PlanDays deterministically; reassignments can be repeated. If build fails, revert to last commit; protocols isolate data layer for easy rollback.

## Artifacts and Notes

- Keep sample outputs from `swift test` and manual scenarios appended here as implementation progresses.

## Interfaces and Dependencies

- Dependencies: Swift 5.9+, SwiftUI, Foundation. No external network APIs.
- Protocols to define:
  - `PlanRepository`: load/save `Plan` and `PlanDay` data; in-memory implementation uses arrays.
  - `MenuRepository`: fetch menus, menu types, and type sets; support adding new menu.
  - `IngredientAggregator` helper (can be static function in PlanStore) that accepts `[PlanDay]` and `MenuRepository` data to produce aggregated `[IngredientTotal]` grouped by `(name, unit)`.
- Types to expose:
  - `struct Plan { let startDate: Date; let endDate: Date; var days: [PlanDay] }`
  - `struct PlanDay { let date: Date; var lunch: Menu?; var dinner: Menu? }`
  - `struct Menu { let id: UUID; var name: String; var type: MenuType; var ingredients: [MenuIngredient] }`
  - `enum MenuType { case japanese, western, chinese, italian, other(String) }` (extendable)
  - `struct MenuTypeSet { let id: UUID; let name: String; let includedTypes: [MenuType] }`
  - `struct Ingredient { let name: String; let unit: String }`
  - `struct MenuIngredient { let ingredient: Ingredient; let quantity: Double }`
  - `struct IngredientTotal { let ingredient: Ingredient; let totalQuantity: Double }`

Note: Update this plan with actual implementations, evidence, and retrospective entries as work proceeds.

Revision note (2025-01-06): Updated progress, added implemented SwiftUI/domain/repository details, and documented environment limitation (no Swift toolchain) while leaving remaining validation tasks open.
Revision note (2025-11-30): Captured deterministic ingredient ordering decision and accompanying regression test in Progress, Surprises & Discoveries, Decision Log, and Outcomes.
