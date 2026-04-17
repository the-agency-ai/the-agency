# NestJS Prototype Starter Pack

**Provider for:** `/service-add <name> --workstream <ws> --type nestjs-prototype`

**Purpose:** scaffolds a NestJS prototype module under `apps/backend/src/prototype/<name>/` that rides inside the existing `backend` compute service. No new topology entry; registry is updated automatically.

## What it creates

```
apps/backend/src/prototype/<name>/
  <name>.module.ts          — NestJS module (no PrismaModule — add later if needed)
  <name>.controller.ts      — UseGuards(PrototypeAuthGuard), greet + build-info + register-build
  <name>.service.ts         — manifest-backed build tracking, no DB
  <name>.controller.spec.ts — Jest controller tests with mocked service
docs/prototype/<name>/
  build-manifest.json       — empty build manifest
```

Plus the registry edit to `apps/backend/src/prototype/prototype.registry.ts`:

- Adds `import { <PascalName>Module } from './<name>/<name>.module';`
- Adds an entry to `PROTOTYPE_REGISTRY`.

## What it does NOT do (v1)

- No Prisma model (add manually and wire `PrismaModule` into the module imports)
- No DTO folder (add when you need create/update endpoints)
- No Docker config (the prototype rides inside the `backend` app's container)
- No OpenAPI / Swagger setup
- No auth beyond `PrototypeAuthGuard`

## After scaffolding

1. Add a Prisma model if you need DB caching:

   ```prisma
   model Proto<PascalName>Build {
     id           String   @id @default(uuid(7)) @db.Uuid
     prototypeId  String
     component    String
     buildNumber  Int
     gitSha       String
     createdAt    DateTime @default(now())
     updatedAt    DateTime @updatedAt

     @@unique([prototypeId, component])
   }
   ```

2. Uncomment the Prisma paths in `<name>.service.ts` (mirror `hello-world.service.ts`).
3. Run `pnpm --filter backend exec prisma generate` and `prisma migrate dev`.

## Manifest contract

See `manifest.yaml` for the full provider contract that `/service-add` reads.
