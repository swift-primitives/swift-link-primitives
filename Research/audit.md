# Audit: swift-link-primitives

## Code Surface — 2026-04-01

### Scope

- **Target**: swift-link-primitives
- **Skill**: code-surface — [API-NAME-001–004], [API-ERR-001–005], [API-IMPL-005–010]
- **Files**: 5 source files

### Findings

| # | Severity | Rule | Location | Finding | Status |
|---|----------|------|----------|---------|--------|
| 1 | MEDIUM | [API-NAME-002] | Link+Topology.swift:229 | `insertAfter(_:after:header:_:)` — compound name redundant with `after:` parameter label. Renamed to `insert(_:after:header:_:)`. | RESOLVED 2026-04-01 |
| 2 | LOW | [API-NAME-002] | Link+Topology.swift:various | `unlinkFirst`, `unlinkLast` — compound names, accepted under [IMPL-024] (static implementation layer; consumers wrap via Property.View `unlink.first()`/`unlink.last()`). Follows stdlib verb+position pattern. | FALSE_POSITIVE — [IMPL-024] static layer |
| 3 | LOW | [API-NAME-002] | Link.Node.swift:63 | `linksPointer(in:)` — compound, minor stutter with `Link` namespace. Accepted under [IMPL-024]; `links` refers to the stored field, not the domain. | FALSE_POSITIVE — [IMPL-024] static layer |

### Summary

3 findings: 0 critical, 0 high, 1 medium, 2 low. All types use Nest.Name (`Link`, `Link.Header`, `Link.Node`). No compound type names. No throwing functions (error rules N/A). One type per file with correct dot-naming. Type bodies are minimal (stored properties + canonical init only). Extension file uses `+` suffix (`Link+Topology.swift`). The `insertAfter` compound name was redundant with its `after:` label — renamed to `insert`. The remaining compound statics (`unlinkFirst`, `unlinkLast`, `linksPointer`) are accepted under [IMPL-024] as implementation-layer building blocks that downstream consumers wrap in Property.View nested accessors.

---

## Implementation — 2026-04-01

### Scope

- **Target**: swift-link-primitives
- **Skill**: implementation — [IMPL-002], [IMPL-006], [IMPL-010], [IMPL-024], [IMPL-034], [IMPL-064], [IMPL-067], [IMPL-EXPR-001], [COPY-FIX-003], [COPY-FIX-004], [COPY-FIX-008], [PATTERN-022]
- **Files**: 5 source files

### Findings

| # | Severity | Rule | Location | Finding | Status |
|---|----------|------|----------|---------|--------|
| — | — | — | — | No violations found | — |

### Summary

0 findings. Typed arithmetic throughout (`count += .one`, `count.subtract.saturating(.one)`). No `.rawValue` at call sites. Static methods use compound names correctly per [IMPL-024] (implementation layer behind consumer Property.View). `unsafe` keyword placement is correct (always leftmost). Node defaults to `~Copyable` with justified `Copyable` on Header (lightweight cursor). Ownership annotations present (`consuming Element` in Node init, `inout Header` in topology ops). ~Copyable nested types in separate files per [PATTERN-022]. Conditional conformances same-file per [COPY-FIX-004].

---

## Modularization — 2026-04-01

### Scope

- **Target**: swift-link-primitives
- **Skill**: modularization — [MOD-001–014]
- **Files**: Package.swift + 5 source files

### Findings

| # | Severity | Rule | Location | Finding | Status |
|---|----------|------|----------|---------|--------|
| — | — | — | — | No violations found | — |

### Summary

0 findings. Single-product package — Core/umbrella rules N/A. Target naming follows `{Domain} Primitives` convention. Dependencies minimal and genuine (index-primitives for `Index<Tag>`, vector-primitives for `InlineArray`). Re-exports in `exports.swift` correct. Single-target justified per [MOD-008]: no independent consumers of types-only vs. operations-only.

---

## Memory Safety — 2026-04-01

### Scope

- **Target**: swift-link-primitives
- **Skill**: memory-safety — [MEM-SAFE-001–002], [MEM-SAFE-020–025], [MEM-SEND-001–004], [MEM-COPY-001–006], [MEM-OWN-001–002]
- **Files**: 5 source files

### Findings

| # | Severity | Rule | Location | Finding | Status |
|---|----------|------|----------|---------|--------|
| 1 | MEDIUM | [MEM-SEND-004] | Link.Node.swift:74 | `@unchecked Sendable` on Node when all stored properties are Sendable (InlineArray of Sendable Index + Element: Sendable). Plain `Sendable` suffices. | RESOLVED 2026-04-01 |

### Summary

1 finding: 0 critical, 0 high, 1 medium, 0 low. Strict memory safety enabled. All `unsafe` operations individually acknowledged. `@unsafe` on all static methods is correct — Link is an implementation primitive whose consumers absorb the unsafety. Node's `@unchecked Sendable` was the sole violation; fixed by switching to plain conditional `Sendable`.

---

## Primitives — 2026-04-01

### Scope

- **Target**: swift-link-primitives
- **Skill**: primitives — [PRIM-FOUND-001–003], [PRIM-ARCH-001–002], [PRIM-NAME-001]
- **Files**: Package.swift + 5 source files

### Findings

| # | Severity | Rule | Location | Finding | Status |
|---|----------|------|----------|---------|--------|
| — | — | — | — | No violations found | — |

### Summary

0 findings. No Foundation imports. Package uses `-primitives` suffix. Dependencies are lower-tier (index-primitives Tier 0, vector-primitives lower tier). Swift 6 settings complete (language mode v6, strict memory safety, ExistentialAny, InternalImportsByDefault, MemberImportVisibility, Lifetimes, SuppressedAssociatedTypes, NonisolatedNonsendingByDefault).
