#!/usr/bin/env npx tsx
/**
 * The Agency MCP Server
 *
 * Exposes Agency coordination primitives to Claude Desktop and Claude Code
 * via the Model Context Protocol.
 *
 * Usage:
 *   npx tsx claude/claude-desktop/agency-server/index.ts
 *
 * Configuration:
 *   Add to claude_desktop_config.json or .mcp.json
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import * as fs from "fs";
import * as path from "path";
import { execSync } from "child_process";

// Get project root from env or current directory
const PROJECT_ROOT = process.env.PROJECT_ROOT || process.cwd();

// Create server
const server = new Server(
  {
    name: "agency",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
      resources: {},
    },
  }
);

// Helper: Run a tool and return output
function runTool(tool: string, args: string[] = []): string {
  const toolPath = path.join(PROJECT_ROOT, "tools", tool);
  try {
    const result = execSync(`"${toolPath}" ${args.map((a) => `"${a}"`).join(" ")}`, {
      cwd: PROJECT_ROOT,
      encoding: "utf-8",
      env: { ...process.env, PROJECT_ROOT },
    });
    return result.trim();
  } catch (error: unknown) {
    const e = error as { stderr?: string; message?: string };
    return `Error: ${e.stderr || e.message}`;
  }
}

// Helper: Read file safely
function readFile(relativePath: string): string {
  const fullPath = path.join(PROJECT_ROOT, relativePath);
  try {
    return fs.readFileSync(fullPath, "utf-8");
  } catch {
    return `File not found: ${relativePath}`;
  }
}

// Helper: List collaboration files
function getCollaborations(): string[] {
  const collabDir = path.join(PROJECT_ROOT, "claude/agents/collaboration");
  try {
    return fs
      .readdirSync(collabDir)
      .filter((f) => f.startsWith("FROM-") && f.includes("COLLABORATE"));
  } catch {
    return [];
  }
}

// Helper: Get agent status
function getAgentStatus(agentName: string): Record<string, unknown> {
  const agentDir = path.join(PROJECT_ROOT, "claude/agents", agentName);
  const status: Record<string, unknown> = {
    name: agentName,
    exists: fs.existsSync(agentDir),
  };

  if (status.exists) {
    const worklogPath = path.join(agentDir, "ADHOC-WORKLOG.md");
    if (fs.existsSync(worklogPath)) {
      const worklog = fs.readFileSync(worklogPath, "utf-8");
      const lastEntry = worklog
        .split("\n## ")
        .filter((s) => s.trim())
        .pop();
      status.lastWork = lastEntry ? lastEntry.split("\n")[0] : "None";
    }

    const backupDir = path.join(agentDir, "backups/latest");
    if (fs.existsSync(backupDir)) {
      const sessionInfo = path.join(backupDir, "session-info.json");
      if (fs.existsSync(sessionInfo)) {
        status.lastSession = JSON.parse(fs.readFileSync(sessionInfo, "utf-8"));
      }
    }
  }

  return status;
}

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "get_workstream_context",
        description:
          "Get current context for a workstream including knowledge, active sprints, and pending work",
        inputSchema: {
          type: "object",
          properties: {
            workstream: {
              type: "string",
              description: "Name of the workstream",
            },
          },
          required: ["workstream"],
        },
      },
      {
        name: "get_agent_status",
        description: "Get status of an agent including last work and session info",
        inputSchema: {
          type: "object",
          properties: {
            agent: {
              type: "string",
              description: "Name of the agent",
            },
          },
          required: ["agent"],
        },
      },
      {
        name: "list_pending_collaborations",
        description: "List all pending collaboration requests that need responses",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "list_active_instructions",
        description: "List all active instructions across all principals",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "read_news",
        description: "Read unread news broadcasts from agents",
        inputSchema: {
          type: "object",
          properties: {
            agent: {
              type: "string",
              description: "Agent to read news for (optional)",
            },
          },
        },
      },
      {
        name: "post_news",
        description: "Post a news broadcast visible to all agents",
        inputSchema: {
          type: "object",
          properties: {
            message: {
              type: "string",
              description: "News message to broadcast",
            },
          },
          required: ["message"],
        },
      },
      {
        name: "create_collaboration",
        description: "Create a collaboration request for another agent",
        inputSchema: {
          type: "object",
          properties: {
            target_agent: {
              type: "string",
              description: "Agent to request help from",
            },
            subject: {
              type: "string",
              description: "Brief subject of the request",
            },
            request: {
              type: "string",
              description: "Detailed request",
            },
          },
          required: ["target_agent", "subject", "request"],
        },
      },
      {
        name: "get_project_health",
        description: "Get overall project health including git status, test status, and quality metrics",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
    ],
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  switch (name) {
    case "get_workstream_context": {
      const workstream = args?.workstream as string;
      const wsDir = path.join(PROJECT_ROOT, "claude/workstreams", workstream);

      if (!fs.existsSync(wsDir)) {
        return { content: [{ type: "text", text: `Workstream '${workstream}' not found` }] };
      }

      const knowledge = readFile(`claude/workstreams/${workstream}/KNOWLEDGE.md`);

      // Find active sprints
      const epics = fs.readdirSync(wsDir).filter((f) => f.startsWith("epic"));
      const activeSprints: string[] = [];

      for (const epic of epics) {
        const epicDir = path.join(wsDir, epic);
        if (fs.statSync(epicDir).isDirectory()) {
          const sprints = fs.readdirSync(epicDir).filter((f) => f.startsWith("sprint"));
          for (const sprint of sprints) {
            const planPath = path.join(epicDir, sprint, "sprint-plan.md");
            if (fs.existsSync(planPath)) {
              const plan = fs.readFileSync(planPath, "utf-8");
              if (plan.includes("Status: In Progress") || plan.includes("Status: Not Started")) {
                activeSprints.push(`${epic}/${sprint}`);
              }
            }
          }
        }
      }

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(
              {
                workstream,
                knowledge: knowledge.slice(0, 2000) + (knowledge.length > 2000 ? "..." : ""),
                activeSprints,
                epics,
              },
              null,
              2
            ),
          },
        ],
      };
    }

    case "get_agent_status": {
      const agent = args?.agent as string;
      const status = getAgentStatus(agent);
      return {
        content: [{ type: "text", text: JSON.stringify(status, null, 2) }],
      };
    }

    case "list_pending_collaborations": {
      const collabs = getCollaborations();
      const pending: Array<{ file: string; subject: string; from: string; status: string }> = [];

      for (const file of collabs) {
        const content = readFile(`claude/agents/collaboration/${file}`);
        const statusMatch = content.match(/\*\*Status:\*\* (\w+)/);
        const subjectMatch = content.match(/## Subject\n\n(.+)/);
        const fromMatch = file.match(/FROM-(.+?)-COLLABORATE/);

        if (statusMatch?.[1] === "Open") {
          pending.push({
            file,
            subject: subjectMatch?.[1] || "Unknown",
            from: fromMatch?.[1] || "Unknown",
            status: statusMatch[1],
          });
        }
      }

      return {
        content: [{ type: "text", text: JSON.stringify(pending, null, 2) }],
      };
    }

    case "list_active_instructions": {
      const output = runTool("list-instructions", ["--active"]);
      return {
        content: [{ type: "text", text: output }],
      };
    }

    case "read_news": {
      const agent = args?.agent as string | undefined;
      const newsArgs = agent ? [] : [];
      const output = runTool("read-news", newsArgs);
      return {
        content: [{ type: "text", text: output }],
      };
    }

    case "post_news": {
      const message = args?.message as string;
      const output = runTool("post-news", [message]);
      return {
        content: [{ type: "text", text: output }],
      };
    }

    case "create_collaboration": {
      const target = args?.target_agent as string;
      const subject = args?.subject as string;
      const request = args?.request as string;
      const output = runTool("collaborate", [target, subject, request]);
      return {
        content: [{ type: "text", text: output }],
      };
    }

    case "get_project_health": {
      // Git status
      let gitStatus = "Unknown";
      try {
        const status = execSync("git status --short", {
          cwd: PROJECT_ROOT,
          encoding: "utf-8",
        });
        gitStatus = status.trim() || "Clean";
      } catch {
        gitStatus = "Error checking git status";
      }

      // Count agents
      const agentsDir = path.join(PROJECT_ROOT, "claude/agents");
      let agentCount = 0;
      if (fs.existsSync(agentsDir)) {
        agentCount = fs
          .readdirSync(agentsDir)
          .filter((f) => {
            const p = path.join(agentsDir, f);
            return fs.statSync(p).isDirectory() && f !== "collaboration";
          }).length;
      }

      // Pending collabs
      const pendingCollabs = getCollaborations().filter((f) => {
        const content = readFile(`claude/agents/collaboration/${f}`);
        return content.includes("**Status:** Open");
      }).length;

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(
              {
                git: gitStatus === "Clean" ? "Clean" : "Has changes",
                uncommittedFiles: gitStatus === "Clean" ? 0 : gitStatus.split("\n").length,
                agents: agentCount,
                pendingCollaborations: pendingCollabs,
              },
              null,
              2
            ),
          },
        ],
      };
    }

    default:
      return {
        content: [{ type: "text", text: `Unknown tool: ${name}` }],
      };
  }
});

// List available resources
server.setRequestHandler(ListResourcesRequestSchema, async () => {
  const resources = [
    {
      uri: "agency://claude.md",
      name: "CLAUDE.md",
      description: "The Agency constitution - main reference document",
      mimeType: "text/markdown",
    },
    {
      uri: "agency://config.yaml",
      name: "config.yaml",
      description: "Project configuration including principal mappings",
      mimeType: "text/yaml",
    },
  ];

  // Add agent resources
  const agentsDir = path.join(PROJECT_ROOT, "claude/agents");
  if (fs.existsSync(agentsDir)) {
    const agents = fs.readdirSync(agentsDir).filter((f) => {
      const p = path.join(agentsDir, f);
      return fs.statSync(p).isDirectory() && f !== "collaboration";
    });

    for (const agent of agents) {
      resources.push({
        uri: `agency://agents/${agent}/agent.md`,
        name: `${agent} Agent`,
        description: `Identity and purpose of the ${agent} agent`,
        mimeType: "text/markdown",
      });
    }
  }

  return { resources };
});

// Read resources
server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
  const { uri } = request.params;

  if (uri === "agency://claude.md") {
    return {
      contents: [
        {
          uri,
          mimeType: "text/markdown",
          text: readFile("CLAUDE.md"),
        },
      ],
    };
  }

  if (uri === "agency://config.yaml") {
    return {
      contents: [
        {
          uri,
          mimeType: "text/yaml",
          text: readFile("claude/config.yaml"),
        },
      ],
    };
  }

  if (uri.startsWith("agency://agents/")) {
    const match = uri.match(/agency:\/\/agents\/(.+)\/(.+)/);
    if (match) {
      const [, agent, file] = match;
      return {
        contents: [
          {
            uri,
            mimeType: "text/markdown",
            text: readFile(`claude/agents/${agent}/${file}`),
          },
        ],
      };
    }
  }

  return {
    contents: [
      {
        uri,
        mimeType: "text/plain",
        text: `Resource not found: ${uri}`,
      },
    ],
  };
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Agency MCP Server running");
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
