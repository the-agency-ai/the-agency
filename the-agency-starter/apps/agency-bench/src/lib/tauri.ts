/**
 * Tauri Integration Layer
 *
 * Provides file system access via Tauri commands.
 * Falls back to mock data when running in browser mode.
 */

// Check if running in Tauri
export const isTauri = typeof window !== 'undefined' && (window as any).__TAURI__;

/**
 * Read a file from the filesystem
 */
export async function readFile(path: string): Promise<string> {
  if (isTauri) {
    const { invoke } = await import('@tauri-apps/api/core');
    return invoke('read_file', { path });
  }

  // Browser fallback - return mock content
  console.log('[Browser mode] readFile:', path);
  return `# Mock Content\n\nRunning in browser mode. File: ${path}\n\nStart the app with \`npm run tauri:dev\` for real file access.`;
}

/**
 * List files in a directory
 */
export async function listFiles(path: string, pattern?: string): Promise<string[]> {
  if (isTauri) {
    const { invoke } = await import('@tauri-apps/api/core');
    return invoke('list_files', { path, pattern });
  }

  // Browser fallback - return mock file list
  console.log('[Browser mode] listFiles:', path, pattern);
  return [
    `${path}/CLAUDE.md`,
    `${path}/README.md`,
    `${path}/CHANGELOG.md`,
  ];
}

/**
 * Get project root directory
 */
export async function getProjectRoot(): Promise<string> {
  if (isTauri) {
    const { invoke } = await import('@tauri-apps/api/core');
    return invoke('get_project_root');
  }

  // Browser fallback
  return '/Users/jdm/code/the-agency';
}

/**
 * List markdown files in the project
 */
export async function listMarkdownFiles(): Promise<{ path: string; name: string }[]> {
  const root = await getProjectRoot();

  if (isTauri) {
    const { invoke } = await import('@tauri-apps/api/core');
    const files: string[] = await invoke('list_markdown_files', { root });
    return files.map(f => ({
      path: f,
      name: f.replace(root + '/', ''),
    }));
  }

  // Browser fallback - return common Agency files
  return [
    { path: `${root}/CLAUDE.md`, name: 'CLAUDE.md' },
    { path: `${root}/README.md`, name: 'README.md' },
    { path: `${root}/CHANGELOG.md`, name: 'CHANGELOG.md' },
    { path: `${root}/claude/agents/housekeeping/agent.md`, name: 'claude/agents/housekeeping/agent.md' },
    { path: `${root}/claude/agents/housekeeping/KNOWLEDGE.md`, name: 'claude/agents/housekeeping/KNOWLEDGE.md' },
  ];
}

/**
 * Search for text in files
 */
export async function searchFiles(
  query: string,
  paths?: string[]
): Promise<{ file: string; matches: { line: number; content: string }[] }[]> {
  if (isTauri) {
    const { invoke } = await import('@tauri-apps/api/core');
    return invoke('search_files', { query, paths });
  }

  // Browser fallback
  console.log('[Browser mode] searchFiles:', query);
  return [];
}

/**
 * Write content to a file
 */
export async function writeFile(path: string, content: string): Promise<void> {
  if (isTauri) {
    const { invoke } = await import('@tauri-apps/api/core');
    return invoke('write_file', { path, content });
  }

  // Browser fallback
  console.log('[Browser mode] writeFile:', path, '(content length:', content.length, ')');
  throw new Error('File writing not available in browser mode');
}
