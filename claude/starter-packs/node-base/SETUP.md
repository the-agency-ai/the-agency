# Setup: Node Base

**Time:** ~10 minutes
**Difficulty:** Beginner

## Step 1: Install nvm (Node Version Manager)

```bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Reload shell
source ~/.zshrc  # or ~/.bashrc

# Verify
nvm --version
```

## Step 2: Install Node.js

```bash
# Install latest LTS
nvm install --lts

# Set as default
nvm alias default node

# Verify
node --version  # Should show v22.x or higher
```

## Step 3: Install pnpm

```bash
# Install pnpm globally
npm install -g pnpm

# Verify
pnpm --version  # Should show 9.x or higher
```

## Step 4: Initialize Project

```bash
# Create project directory
mkdir my-project && cd my-project

# Initialize with pnpm
pnpm init

# Create .nvmrc for consistent Node version
node --version > .nvmrc
```

## Step 5: Add TypeScript

```bash
# Install TypeScript and types
pnpm add -D typescript @types/node

# Initialize tsconfig
pnpm exec tsc --init

# Update tsconfig.json with recommended settings
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF
```

## Step 6: Add ESLint + Prettier

```bash
# Install ESLint with TypeScript support
pnpm add -D eslint @eslint/js typescript-eslint prettier eslint-config-prettier

# Create eslint.config.js
cat > eslint.config.js << 'EOF'
import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';
import prettier from 'eslint-config-prettier';

export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.recommended,
  prettier,
  {
    ignores: ['dist/**', 'node_modules/**'],
  }
);
EOF

# Create .prettierrc
cat > .prettierrc << 'EOF'
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100
}
EOF
```

## Step 7: Create Project Structure

```bash
# Create directories
mkdir -p src

# Create entry point
cat > src/index.ts << 'EOF'
console.log('Hello from The Agency!');
EOF

# Add scripts to package.json
pnpm pkg set type="module"
pnpm pkg set scripts.build="tsc"
pnpm pkg set scripts.start="node dist/index.js"
pnpm pkg set scripts.dev="tsx src/index.ts"
pnpm pkg set scripts.lint="eslint ."
pnpm pkg set scripts.format="prettier --write ."

# Install tsx for development
pnpm add -D tsx
```

## Step 8: Initialize Git

```bash
# Create .gitignore
cat > .gitignore << 'EOF'
node_modules/
dist/
.env
.env.local
*.log
.DS_Store
EOF

# Initialize repo
git init
git add .
git commit -m "Initial commit: node-base starter pack"
```

## Done!

Proceed to [VERIFY.md](./VERIFY.md) to confirm setup.
