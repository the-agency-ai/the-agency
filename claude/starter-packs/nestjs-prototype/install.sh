#!/bin/bash
# NestJS Prototype Starter Pack — installer
#
# Scaffolds a new NestJS prototype module under apps/backend/src/prototype/<name>/.
# Invoked by claude/tools/service-add (via tools/service-add.ts).
#
# Contract (args):
#   --name <kebab-case>      — service name (required)
#   --pascal-name <PascalName> — PascalCase version of name (required)
#   --description <text>     — optional description (shown in module header comment)
#   --owner <text>           — optional owner attribution
#   --repo-root <path>       — absolute path to repo root (required)
#   --dry-run                — print what would be written, don't write
#
# Idempotency: refuses to overwrite existing files. Abort = non-zero exit.

set -euo pipefail

# --- parse args ----------------------------------------------------------------

NAME=""
PASCAL=""
DESCRIPTION=""
OWNER="TODO"
REPO_ROOT=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --name)        NAME="$2"; shift 2 ;;
        --pascal-name) PASCAL="$2"; shift 2 ;;
        --description) DESCRIPTION="$2"; shift 2 ;;
        --owner)       OWNER="$2"; shift 2 ;;
        --repo-root)   REPO_ROOT="$2"; shift 2 ;;
        --dry-run)     DRY_RUN=true; shift ;;
        -h|--help)
            cat <<USAGE
Usage: install.sh --name <kebab> --pascal-name <Pascal> --repo-root <path> [options]

Options:
  --name <kebab>          Service name (required, kebab-case)
  --pascal-name <Pascal>  PascalCase version (required)
  --description <text>    Optional description
  --owner <text>          Optional owner attribution
  --repo-root <path>      Repo root absolute path (required)
  --dry-run               Print plan, don't write
USAGE
            exit 0 ;;
        *) echo "[nestjs-prototype] ERROR: unknown arg: $1" >&2; exit 1 ;;
    esac
done

if [[ -z "$NAME" || -z "$PASCAL" || -z "$REPO_ROOT" ]]; then
    echo "[nestjs-prototype] ERROR: --name, --pascal-name, --repo-root are required" >&2
    exit 1
fi

: "${DESCRIPTION:="$NAME prototype (scaffolded)"}"

TARGET_DIR="$REPO_ROOT/apps/backend/src/prototype/$NAME"
MANIFEST_DIR="$REPO_ROOT/docs/prototype/$NAME"

# --- safety: reject if target exists ------------------------------------------

if [[ -e "$TARGET_DIR" ]]; then
    echo "[nestjs-prototype] ERROR: $TARGET_DIR already exists — refusing to overwrite" >&2
    exit 1
fi

# --- file templates -----------------------------------------------------------

read -r -d '' MODULE_TS <<EOF || true
import { Module } from '@nestjs/common';
import { ${PASCAL}Controller } from './${NAME}.controller';
import { ${PASCAL}Service } from './${NAME}.service';

/**
 * ${PASCAL}Module — ${DESCRIPTION}
 *
 * Scaffolded by /service-add (SPEC-PROVIDER: nestjs-prototype).
 * TODO: Add PrismaModule import if this prototype needs DB access.
 *       See apps/backend/src/prototype/hello-world/hello-world.module.ts for the DB-backed pattern.
 */
@Module({
  controllers: [${PASCAL}Controller],
  providers: [${PASCAL}Service],
})
export class ${PASCAL}Module {}
EOF

read -r -d '' CONTROLLER_TS <<EOF || true
import { Controller, Get, Post, Body, UseGuards, BadRequestException } from '@nestjs/common';
import { ${PASCAL}Service } from './${NAME}.service';
import { PrototypeAuthGuard } from '../prototype-auth.guard';

const VALID_COMPONENTS = ['fe', 'be'] as const;

@UseGuards(PrototypeAuthGuard)
@Controller()
export class ${PASCAL}Controller {
  constructor(private readonly ${NAME//-/_}Service: ${PASCAL}Service) {}

  @Get('greet')
  greet() {
    return this.${NAME//-/_}Service.greet();
  }

  @Get('build-info')
  buildInfo() {
    return this.${NAME//-/_}Service.getBuildInfo();
  }

  @Post('register-build')
  registerBuild(@Body() body: { component: string; sha: string }) {
    if (!VALID_COMPONENTS.includes(body.component as (typeof VALID_COMPONENTS)[number])) {
      throw new BadRequestException(\`component must be one of: \${VALID_COMPONENTS.join(', ')}\`);
    }
    if (!body.sha || typeof body.sha !== 'string' || !/^[0-9a-f]{4,40}\$/i.test(body.sha)) {
      throw new BadRequestException('sha must be a hex string between 4 and 40 characters');
    }
    return this.${NAME//-/_}Service.registerBuild(body.component, body.sha);
  }
}
EOF

read -r -d '' SERVICE_TS <<EOF || true
import { Injectable, Logger } from '@nestjs/common';
import { execSync } from 'child_process';
import { readManifest, writeManifest } from '../lib/build-manifest';

/**
 * ${PASCAL}Service — ${DESCRIPTION}
 *
 * Scaffolded by /service-add (SPEC-PROVIDER: nestjs-prototype).
 * v0 scaffold: manifest-backed only (no DB). To add DB caching, mirror
 * apps/backend/src/prototype/hello-world/hello-world.service.ts — add a
 * Prisma model \`proto${PASCAL}Build\` and uncomment DB paths below.
 */
@Injectable()
export class ${PASCAL}Service {
  private readonly logger = new Logger(${PASCAL}Service.name);
  private gitSha: string;

  constructor() {
    try {
      this.gitSha = execSync('git rev-parse --short HEAD', { encoding: 'utf-8' }).trim();
    } catch {
      this.gitSha = 'unknown';
    }
  }

  greet() {
    return { message: '${NAME} prototype is running', timestamp: new Date().toISOString() };
  }

  registerBuild(component: string, sha: string) {
    const manifest = readManifest('${NAME}') ?? {
      prototypeId: '${NAME}',
      builds: {},
    };

    const existing = manifest.builds[component];
    const buildNumber = (existing?.buildNumber ?? 0) + 1;
    const timestamp = new Date().toISOString();

    manifest.builds[component] = { buildNumber, gitSha: sha, timestamp };
    writeManifest('${NAME}', manifest);

    return { buildNumber, gitSha: sha, timestamp };
  }

  getBuildInfo() {
    const result: Record<string, unknown> = { prototypeId: '${NAME}' };
    const manifest = readManifest('${NAME}');
    const defaults = { be: this.gitSha, fe: 'unknown' };

    for (const comp of ['be', 'fe'] as const) {
      const m = manifest?.builds[comp];
      result[comp] = m
        ? { sha: m.gitSha, buildNumber: m.buildNumber, timestamp: m.timestamp }
        : { sha: defaults[comp], buildNumber: 0, timestamp: null };
    }

    return result;
  }
}
EOF

read -r -d '' SPEC_TS <<EOF || true
import { BadRequestException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { ${PASCAL}Controller } from './${NAME}.controller';
import { ${PASCAL}Service } from './${NAME}.service';
import { PrototypeAuthGuard } from '../prototype-auth.guard';

describe('${PASCAL}Controller', () => {
  let controller: ${PASCAL}Controller;

  beforeEach(async () => {
    process.env.ENABLE_PROTOTYPES = 'true';
    delete process.env.PROTOTYPE_TOKEN;

    const testModule: TestingModule = await Test.createTestingModule({
      controllers: [${PASCAL}Controller],
      providers: [
        {
          provide: ${PASCAL}Service,
          useValue: {
            greet: () => ({ message: '${NAME}' }),
            getBuildInfo: () => ({ prototypeId: '${NAME}', fe: {}, be: {} }),
            registerBuild: (_c: string, _s: string) => ({
              buildNumber: 1,
              gitSha: 'abc1234',
              timestamp: '2026-01-01',
            }),
          },
        },
      ],
    })
      .overrideGuard(PrototypeAuthGuard)
      .useValue({ canActivate: () => true })
      .compile();

    controller = testModule.get<${PASCAL}Controller>(${PASCAL}Controller);
  });

  describe('greet', () => {
    it('returns a message', () => {
      expect(controller.greet()).toHaveProperty('message');
    });
  });

  describe('registerBuild validation', () => {
    it('accepts valid component and sha', () => {
      const result = controller.registerBuild({ component: 'fe', sha: 'abc1234' });
      expect(result).toHaveProperty('buildNumber');
    });

    it('rejects invalid component', () => {
      expect(() => controller.registerBuild({ component: 'frontend', sha: 'abc1234' })).toThrow(
        BadRequestException,
      );
    });

    it('rejects non-hex sha', () => {
      expect(() => controller.registerBuild({ component: 'fe', sha: 'xyz12345' })).toThrow(
        BadRequestException,
      );
    });

    it('rejects sha shorter than 4 characters', () => {
      expect(() => controller.registerBuild({ component: 'fe', sha: 'abc' })).toThrow(
        BadRequestException,
      );
    });
  });
});
EOF

read -r -d '' BUILD_MANIFEST_JSON <<EOF || true
{
  "prototypeId": "${NAME}",
  "builds": {}
}
EOF

# --- dry-run preview ----------------------------------------------------------

if [[ "$DRY_RUN" == "true" ]]; then
    echo "[nestjs-prototype] DRY-RUN — would write:"
    echo "  $TARGET_DIR/${NAME}.module.ts"
    echo "  $TARGET_DIR/${NAME}.controller.ts"
    echo "  $TARGET_DIR/${NAME}.service.ts"
    echo "  $TARGET_DIR/${NAME}.controller.spec.ts"
    echo "  $MANIFEST_DIR/build-manifest.json"
    echo ""
    echo "[nestjs-prototype] module.ts preview:"
    echo "$MODULE_TS" | head -10
    exit 0
fi

# --- write --------------------------------------------------------------------

# Cleanup on failure: remove partial dirs so caller can retry cleanly.
cleanup_on_failure() {
    local code=$?
    if [[ $code -ne 0 ]]; then
        echo "[nestjs-prototype] install failed (exit $code) — removing partial dirs" >&2
        [[ -d "$TARGET_DIR" ]] && rm -rf "$TARGET_DIR"
        [[ -d "$MANIFEST_DIR" ]] && rm -rf "$MANIFEST_DIR"
    fi
}
trap cleanup_on_failure EXIT

mkdir -p "$TARGET_DIR"
mkdir -p "$MANIFEST_DIR"

printf '%s\n' "$MODULE_TS"          > "$TARGET_DIR/${NAME}.module.ts"
printf '%s\n' "$CONTROLLER_TS"      > "$TARGET_DIR/${NAME}.controller.ts"
printf '%s\n' "$SERVICE_TS"         > "$TARGET_DIR/${NAME}.service.ts"
printf '%s\n' "$SPEC_TS"            > "$TARGET_DIR/${NAME}.controller.spec.ts"
printf '%s\n' "$BUILD_MANIFEST_JSON" > "$MANIFEST_DIR/build-manifest.json"

trap - EXIT
echo "[nestjs-prototype] wrote $TARGET_DIR/ (4 files) + $MANIFEST_DIR/build-manifest.json"
