import { useState, useCallback, useRef } from "react";

const REVIEW_SYSTEM_PROMPT = `You are a design document reviewer using the markdown-pal comment format.

When reviewing a document, produce your review as a YAML block containing comments in this exact format:

comments:
  - id: "r001"
    type: question|suggestion|note|directive
    author: claude
    section: section-slug-here
    date: CURRENT_DATE
    context: |
      The exact text from the section you're commenting on.
      Include enough for the comment to be self-contained.
    text: >
      Your review comment here. Be specific and actionable.

Rules:
- Anchor every comment to a specific section using its slug (lowercase, hyphens, derived from heading text)
- Always include a context field with the relevant text from that section
- Use the appropriate comment type: question for things you want clarified, suggestion for proposed changes, note for observations, directive for action items
- Be specific and constructive
- Produce 5-10 comments covering the most important issues
- Return ONLY the YAML block, no preamble or explanation`;

const FOCUS_OPTIONS = {
  general: {
    label: "General",
    prompt: "Provide a general review covering the most important issues you see.",
    color: "#6B7280"
  },
  completeness: {
    label: "Completeness",
    prompt: "Focus on missing sections, gaps in the design, and areas that need more detail.",
    color: "#3B82F6"
  },
  consistency: {
    label: "Consistency",
    prompt: "Focus on internal contradictions, inconsistent terminology, and logical gaps between sections.",
    color: "#8B5CF6"
  },
  feasibility: {
    label: "Feasibility",
    prompt: "Focus on technical feasibility, implementation risks, and practical concerns.",
    color: "#F59E0B"
  },
  clarity: {
    label: "Clarity",
    prompt: "Focus on unclear writing, ambiguous requirements, and sections that would confuse an implementer.",
    color: "#10B981"
  }
};

const TYPE_CONFIG = {
  question: {
    icon: "?",
    label: "Question",
    bg: "#EFF6FF",
    border: "#BFDBFE",
    badge: "#DBEAFE",
    badgeText: "#1E40AF",
    accent: "#3B82F6"
  },
  suggestion: {
    icon: "→",
    label: "Suggestion",
    bg: "#F0FDF4",
    border: "#BBF7D0",
    badge: "#DCFCE7",
    badgeText: "#166534",
    accent: "#22C55E"
  },
  note: {
    icon: "i",
    label: "Note",
    bg: "#F9FAFB",
    border: "#E5E7EB",
    badge: "#F3F4F6",
    badgeText: "#374151",
    accent: "#6B7280"
  },
  directive: {
    icon: "!",
    label: "Directive",
    bg: "#FFFBEB",
    border: "#FDE68A",
    badge: "#FEF3C7",
    badgeText: "#92400E",
    accent: "#F59E0B"
  }
};

function parseYAMLComments(text) {
  const lines = text.split("\n");
  const comments = [];
  let current = null;
  let fieldIndent = 0;
  let multilineField = null;
  let multilineValue = "";

  for (const line of lines) {
    if (line.trim().startsWith("- id:")) {
      if (current) {
        if (multilineField) {
          current[multilineField] = multilineValue.trim();
          multilineField = null;
          multilineValue = "";
        }
        comments.push(current);
      }
      const idMatch = line.match(/["']([^"']+)["']/);
      current = { id: idMatch ? idMatch[1] : line.split(":")[1]?.trim() };
      fieldIndent = line.indexOf("id:");
      continue;
    }

    if (!current) continue;
    const trimmed = line.trim();
    if (!trimmed) {
      if (multilineField) multilineValue += "\n";
      continue;
    }

    const indent = line.length - line.trimStart().length;

    if (indent <= fieldIndent + 2 && trimmed.includes(":") && !trimmed.startsWith("-") && !multilineField) {
      const colonIdx = trimmed.indexOf(":");
      const key = trimmed.substring(0, colonIdx).trim();
      let value = trimmed.substring(colonIdx + 1).trim();

      if (value === "|" || value === ">") {
        multilineField = key;
        multilineValue = "";
      } else {
        value = value.replace(/^["']|["']$/g, "");
        current[key] = value;
      }
    } else if (multilineField) {
      if (indent <= fieldIndent && trimmed.includes(":") && !trimmed.startsWith("-")) {
        current[multilineField] = multilineValue.trim();
        multilineField = null;
        multilineValue = "";
        const colonIdx = trimmed.indexOf(":");
        const key = trimmed.substring(0, colonIdx).trim();
        let value = trimmed.substring(colonIdx + 1).trim();
        if (value === "|" || value === ">") {
          multilineField = key;
          multilineValue = "";
        } else {
          value = value.replace(/^["']|["']$/g, "");
          current[key] = value;
        }
      } else {
        multilineValue += (multilineValue ? "\n" : "") + trimmed;
      }
    }
  }

  if (current) {
    if (multilineField) current[multilineField] = multilineValue.trim();
    comments.push(current);
  }

  return comments;
}

function CommentCard({ comment, index }) {
  const [expanded, setExpanded] = useState(false);
  const config = TYPE_CONFIG[comment.type] || TYPE_CONFIG.note;

  return (
    <div
      style={{
        background: config.bg,
        border: `1px solid ${config.border}`,
        borderLeft: `3px solid ${config.accent}`,
        borderRadius: "8px",
        padding: "16px 18px",
        marginBottom: "10px",
        animation: `fadeSlideIn 0.3s ease-out ${index * 0.08}s both`,
      }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: "8px", marginBottom: "10px" }}>
        <span
          style={{
            display: "inline-flex",
            alignItems: "center",
            justifyContent: "center",
            width: "22px",
            height: "22px",
            borderRadius: "50%",
            background: config.badge,
            color: config.badgeText,
            fontSize: "12px",
            fontWeight: 700,
            fontFamily: "'JetBrains Mono', 'SF Mono', 'Fira Code', monospace",
          }}
        >
          {config.icon}
        </span>
        <span
          style={{
            fontSize: "11px",
            fontWeight: 600,
            textTransform: "uppercase",
            letterSpacing: "0.05em",
            color: config.badgeText,
            background: config.badge,
            padding: "2px 8px",
            borderRadius: "4px",
          }}
        >
          {config.label}
        </span>
        <span
          style={{
            fontSize: "12px",
            color: "#6B7280",
            fontFamily: "'JetBrains Mono', 'SF Mono', 'Fira Code', monospace",
          }}
        >
          § {comment.section}
        </span>
        <span style={{ fontSize: "11px", color: "#9CA3AF", marginLeft: "auto", fontFamily: "'JetBrains Mono', 'SF Mono', monospace" }}>
          {comment.id}
        </span>
      </div>
      <p style={{ fontSize: "14px", lineHeight: 1.6, color: "#1F2937", margin: "0 0 8px 0" }}>
        {comment.text}
      </p>
      {comment.context && (
        <div>
          <button
            onClick={() => setExpanded(!expanded)}
            style={{
              background: "none",
              border: "none",
              fontSize: "12px",
              color: config.accent,
              cursor: "pointer",
              padding: "2px 0",
              fontWeight: 500,
              opacity: 0.8,
            }}
            onMouseOver={e => e.target.style.opacity = 1}
            onMouseOut={e => e.target.style.opacity = 0.8}
          >
            {expanded ? "▾ Hide context" : "▸ Show context"}
          </button>
          {expanded && (
            <pre
              style={{
                marginTop: "8px",
                fontSize: "12px",
                lineHeight: 1.5,
                background: "rgba(255,255,255,0.6)",
                padding: "10px 12px",
                borderRadius: "6px",
                border: "1px solid rgba(0,0,0,0.06)",
                whiteSpace: "pre-wrap",
                wordBreak: "break-word",
                color: "#4B5563",
                fontFamily: "'JetBrains Mono', 'SF Mono', 'Fira Code', monospace",
              }}
            >
              {comment.context}
            </pre>
          )}
        </div>
      )}
    </div>
  );
}

function CopyButton({ text }) {
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    navigator.clipboard.writeText(text).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  };

  return (
    <button
      onClick={handleCopy}
      style={{
        background: copied ? "#DCFCE7" : "#F3F4F6",
        border: `1px solid ${copied ? "#86EFAC" : "#D1D5DB"}`,
        borderRadius: "6px",
        padding: "6px 14px",
        fontSize: "12px",
        fontWeight: 500,
        color: copied ? "#166534" : "#374151",
        cursor: "pointer",
        transition: "all 0.2s",
      }}
    >
      {copied ? "✓ Copied" : "Copy YAML"}
    </button>
  );
}

export default function ReviewPrototype() {
  const [document, setDocument] = useState("");
  const [focus, setFocus] = useState("general");
  const [comments, setComments] = useState([]);
  const [rawYAML, setRawYAML] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [showRaw, setShowRaw] = useState(false);
  const [stats, setStats] = useState(null);
  const resultsRef = useRef(null);

  const runReview = useCallback(async () => {
    if (!document.trim()) return;
    setLoading(true);
    setError(null);
    setComments([]);
    setRawYAML("");
    setStats(null);

    try {
      const today = new Date().toISOString().split("T")[0];
      const prompt = `Review the following markdown-pal artifact. ${FOCUS_OPTIONS[focus].prompt}

Replace CURRENT_DATE with: ${today}

---
${document}
---`;

      const response = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          model: "claude-sonnet-4-20250514",
          max_tokens: 4096,
          system: REVIEW_SYSTEM_PROMPT,
          messages: [{ role: "user", content: prompt }]
        })
      });

      if (!response.ok) {
        const errData = await response.json().catch(() => ({}));
        throw new Error(errData.error?.message || `API returned ${response.status}`);
      }

      const data = await response.json();
      const text = data.content?.map(b => b.text || "").join("\n") || "";
      setRawYAML(text);

      const parsed = parseYAMLComments(text);
      setComments(parsed);

      const typeCounts = {};
      parsed.forEach(c => {
        typeCounts[c.type] = (typeCounts[c.type] || 0) + 1;
      });
      setStats({ total: parsed.length, types: typeCounts });

      if (parsed.length === 0) {
        setError("No comments were parsed. Check the raw YAML output for formatting issues.");
      }

      setTimeout(() => {
        resultsRef.current?.scrollIntoView({ behavior: "smooth", block: "start" });
      }, 100);
    } catch (err) {
      setError(`Review failed: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }, [document, focus]);

  const metaBlockYAML = rawYAML ? `<!-- begin:markdown-pal-meta
\`\`\`yaml
unresolved:
${rawYAML.includes("comments:") ? rawYAML.split("comments:")[1] || rawYAML : rawYAML}
\`\`\`
end:markdown-pal-meta -->` : "";

  return (
    <div style={{ minHeight: "100vh", background: "#FAFAFA" }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600;700&family=Source+Serif+4:ital,wght@0,400;0,600;0,700;1,400&family=DM+Sans:wght@400;500;600;700&display=swap');
        
        @keyframes fadeSlideIn {
          from { opacity: 0; transform: translateY(8px); }
          to { opacity: 1; transform: translateY(0); }
        }
        
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.5; }
        }
        
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
        
        * { box-sizing: border-box; }
        
        textarea:focus, select:focus, button:focus-visible {
          outline: 2px solid #3B82F6;
          outline-offset: 2px;
        }
      `}</style>

      {/* Header */}
      <div
        style={{
          background: "#1A1A2E",
          padding: "32px 0 28px",
          borderBottom: "2px solid #E94560",
        }}
      >
        <div style={{ maxWidth: "900px", margin: "0 auto", padding: "0 24px" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "12px", marginBottom: "8px" }}>
            <div
              style={{
                width: "32px",
                height: "32px",
                borderRadius: "8px",
                background: "linear-gradient(135deg, #E94560, #0F3460)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: "16px",
                fontWeight: 700,
                color: "white",
                fontFamily: "'JetBrains Mono', monospace",
              }}
            >
              ¶
            </div>
            <h1
              style={{
                margin: 0,
                fontSize: "22px",
                fontWeight: 700,
                color: "#F5F5F5",
                fontFamily: "'DM Sans', sans-serif",
                letterSpacing: "-0.02em",
              }}
            >
              markdown-pal
              <span style={{ color: "#E94560", marginLeft: "8px", fontWeight: 400, fontSize: "16px" }}>
                review prototype
              </span>
            </h1>
          </div>
          <p
            style={{
              margin: 0,
              fontSize: "13px",
              color: "#8B8FA3",
              fontFamily: "'DM Sans', sans-serif",
              maxWidth: "600px",
              lineHeight: 1.5,
            }}
          >
            Paste an artifact, pick a focus, and Claude reviews it using the markdown-pal
            comment format — structured YAML you can append directly to your metadata block.
          </p>
        </div>
      </div>

      <div style={{ maxWidth: "900px", margin: "0 auto", padding: "32px 24px" }}>
        {/* Input Area */}
        <div style={{ marginBottom: "24px" }}>
          <label
            style={{
              display: "block",
              fontSize: "12px",
              fontWeight: 600,
              textTransform: "uppercase",
              letterSpacing: "0.06em",
              color: "#6B7280",
              marginBottom: "8px",
              fontFamily: "'DM Sans', sans-serif",
            }}
          >
            Artifact Content
          </label>
          <textarea
            value={document}
            onChange={e => setDocument(e.target.value)}
            placeholder={"# My Design Document\n\n> **Status:** Draft\n> **Version:** V0001.0001.20250310\n\n## Problem\n\nPaste your full .md artifact here..."}
            style={{
              width: "100%",
              height: "280px",
              padding: "16px",
              border: "1px solid #D1D5DB",
              borderRadius: "8px",
              fontFamily: "'JetBrains Mono', 'SF Mono', 'Fira Code', monospace",
              fontSize: "13px",
              lineHeight: 1.6,
              resize: "vertical",
              background: "#FFFFFF",
              color: "#1F2937",
              transition: "border-color 0.2s",
            }}
          />
        </div>

        {/* Controls */}
        <div style={{ display: "flex", alignItems: "flex-end", gap: "16px", marginBottom: "32px", flexWrap: "wrap" }}>
          <div>
            <label
              style={{
                display: "block",
                fontSize: "12px",
                fontWeight: 600,
                textTransform: "uppercase",
                letterSpacing: "0.06em",
                color: "#6B7280",
                marginBottom: "8px",
                fontFamily: "'DM Sans', sans-serif",
              }}
            >
              Review Focus
            </label>
            <div style={{ display: "flex", gap: "6px" }}>
              {Object.entries(FOCUS_OPTIONS).map(([key, opt]) => (
                <button
                  key={key}
                  onClick={() => setFocus(key)}
                  style={{
                    padding: "8px 14px",
                    borderRadius: "6px",
                    border: focus === key ? `2px solid ${opt.color}` : "1px solid #D1D5DB",
                    background: focus === key ? `${opt.color}10` : "#FFFFFF",
                    color: focus === key ? opt.color : "#6B7280",
                    fontSize: "13px",
                    fontWeight: focus === key ? 600 : 400,
                    cursor: "pointer",
                    fontFamily: "'DM Sans', sans-serif",
                    transition: "all 0.15s",
                  }}
                >
                  {opt.label}
                </button>
              ))}
            </div>
          </div>

          <button
            onClick={runReview}
            disabled={loading || !document.trim()}
            style={{
              padding: "10px 28px",
              borderRadius: "8px",
              border: "none",
              background: loading || !document.trim() ? "#D1D5DB" : "#1A1A2E",
              color: loading || !document.trim() ? "#9CA3AF" : "#FFFFFF",
              fontSize: "14px",
              fontWeight: 600,
              cursor: loading || !document.trim() ? "not-allowed" : "pointer",
              fontFamily: "'DM Sans', sans-serif",
              display: "flex",
              alignItems: "center",
              gap: "8px",
              transition: "all 0.2s",
              marginLeft: "auto",
            }}
          >
            {loading && (
              <span
                style={{
                  display: "inline-block",
                  width: "14px",
                  height: "14px",
                  border: "2px solid rgba(255,255,255,0.3)",
                  borderTopColor: "#fff",
                  borderRadius: "50%",
                  animation: "spin 0.6s linear infinite",
                }}
              />
            )}
            {loading ? "Reviewing…" : "Run Review"}
          </button>
        </div>

        {/* Error */}
        {error && (
          <div
            style={{
              padding: "12px 16px",
              background: "#FEF2F2",
              border: "1px solid #FECACA",
              borderLeft: "3px solid #EF4444",
              borderRadius: "8px",
              fontSize: "13px",
              color: "#991B1B",
              marginBottom: "24px",
              fontFamily: "'DM Sans', sans-serif",
            }}
          >
            {error}
          </div>
        )}

        {/* Results */}
        {(comments.length > 0 || rawYAML) && (
          <div ref={resultsRef}>
            {/* Stats Bar */}
            {stats && (
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "16px",
                  padding: "14px 18px",
                  background: "#FFFFFF",
                  border: "1px solid #E5E7EB",
                  borderRadius: "8px",
                  marginBottom: "16px",
                  flexWrap: "wrap",
                }}
              >
                <span
                  style={{
                    fontSize: "14px",
                    fontWeight: 600,
                    color: "#1F2937",
                    fontFamily: "'DM Sans', sans-serif",
                  }}
                >
                  {stats.total} comment{stats.total !== 1 ? "s" : ""}
                </span>
                <div style={{ display: "flex", gap: "8px", flex: 1 }}>
                  {Object.entries(stats.types).map(([type, count]) => {
                    const cfg = TYPE_CONFIG[type] || TYPE_CONFIG.note;
                    return (
                      <span
                        key={type}
                        style={{
                          fontSize: "11px",
                          fontWeight: 600,
                          padding: "3px 10px",
                          borderRadius: "4px",
                          background: cfg.badge,
                          color: cfg.badgeText,
                          textTransform: "uppercase",
                          letterSpacing: "0.04em",
                        }}
                      >
                        {count} {type}
                      </span>
                    );
                  })}
                </div>
                <div style={{ display: "flex", gap: "8px", alignItems: "center" }}>
                  <button
                    onClick={() => setShowRaw(!showRaw)}
                    style={{
                      background: "none",
                      border: "1px solid #D1D5DB",
                      borderRadius: "6px",
                      padding: "6px 14px",
                      fontSize: "12px",
                      fontWeight: 500,
                      color: "#374151",
                      cursor: "pointer",
                      fontFamily: "'DM Sans', sans-serif",
                    }}
                  >
                    {showRaw ? "Parsed" : "Raw YAML"}
                  </button>
                  <CopyButton text={metaBlockYAML || rawYAML} />
                </div>
              </div>
            )}

            {/* Comments or Raw */}
            {showRaw ? (
              <pre
                style={{
                  padding: "20px",
                  background: "#1A1A2E",
                  borderRadius: "8px",
                  fontSize: "12px",
                  lineHeight: 1.6,
                  color: "#E5E7EB",
                  fontFamily: "'JetBrains Mono', 'SF Mono', 'Fira Code', monospace",
                  whiteSpace: "pre-wrap",
                  wordBreak: "break-word",
                  overflow: "auto",
                  maxHeight: "600px",
                }}
              >
                {rawYAML}
              </pre>
            ) : (
              <div>
                {comments.map((c, i) => (
                  <CommentCard key={c.id || i} comment={c} index={i} />
                ))}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
