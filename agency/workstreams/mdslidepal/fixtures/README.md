# mdslidepal Fixtures

Canonical test fixtures that both mdslidepal-web and mdslidepal-mac MUST render correctly. These are the contract-enforcing acceptance tests: if an implementation cannot render every fixture in this directory, it does not conform to the shared contract.

## Fixture files

Captain will create these before either implementation agent starts. Each fixture exercises a specific feature area of the contract. They live here at the workstream level so both agents consume the same inputs.

| Fixture | Tests |
|---|---|
| `01-minimal.md` | Single slide, single H1, smoke test |
| `02-multi-slide.md` | Multiple slides separated by `---`, verifies break detection |
| `03-code-blocks.md` | Fenced code blocks with language hints (bash, typescript, python, swift) and syntax highlighting |
| `04-images.md` | Local image via `![alt](./image.png)`, verifies asset resolution |
| `05-tables-and-lists.md` | GFM tables, nested lists, task lists |
| `06-front-matter.md` | YAML front-matter at BOF (title, author, theme), verifies front-matter/slide-break disambiguation |
| `07-speaker-notes.md` | Slides with speaker notes, verifies notes are NOT rendered in main view |
| `08-edge-cases.md` | Empty slide, `---` inside fenced code, trailing `---`, empty file behavior |

## How to use at reconciliation time

At reconciliation, captain runs both implementations on every fixture and produces PNG snapshots of each slide. Snapshots are compared:

1. **Slide count** must match exactly
2. **Slide order** must match exactly
3. **Text content** must be semantically identical (no content missing, no content added)
4. **Code block content** must be identical (including which lines are syntax-highlighted)
5. **Speaker notes** must be identical (in presenter view only)
6. **Theme colors** must match the theme JSON specification (both implementations reading the same theme file)
7. **Aspect ratio** must be 16:9
8. **Font categories** must match (both sans, both mono, etc. — exact font metrics may differ)

Differences beyond these equivalence classes are **reconciliation bugs** and must be resolved before merge.

## Scope note

These fixtures are the MVP acceptance set. Phase 2 will expand the fixture corpus to cover more features (themes, layouts, transitions, custom metadata). For MVP, these 8 fixtures are the minimum viable test set.

**Status:** Pending creation by captain before agents start. Tracked as a required pre-work artifact alongside the Plan B safety net.
