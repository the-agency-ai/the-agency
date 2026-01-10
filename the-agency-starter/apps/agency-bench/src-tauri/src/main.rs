// Prevents additional console window on Windows in release
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::path::Path;
use rusqlite::{Connection, Result as SqliteResult};

// Command to read a file from the filesystem
#[tauri::command]
async fn read_file(path: String) -> Result<String, String> {
    std::fs::read_to_string(&path).map_err(|e| e.to_string())
}

// Command to write content to a file
#[tauri::command]
async fn write_file(path: String, content: String) -> Result<(), String> {
    std::fs::write(&path, &content).map_err(|e| e.to_string())
}

// Command to list files in a directory
#[tauri::command]
async fn list_files(path: String, pattern: Option<String>) -> Result<Vec<String>, String> {
    let entries = std::fs::read_dir(&path).map_err(|e| e.to_string())?;

    let mut files: Vec<String> = Vec::new();
    for entry in entries {
        if let Ok(entry) = entry {
            let file_name = entry.file_name().to_string_lossy().to_string();
            if let Some(ref pat) = pattern {
                if file_name.ends_with(pat) {
                    files.push(entry.path().to_string_lossy().to_string());
                }
            } else {
                files.push(entry.path().to_string_lossy().to_string());
            }
        }
    }

    Ok(files)
}

// Find project root by looking for CLAUDE.md
fn find_project_root() -> Option<String> {
    // Start from current dir and walk up looking for CLAUDE.md
    if let Ok(start) = std::env::current_dir() {
        let mut current = start.as_path();
        loop {
            let claude_md = current.join("CLAUDE.md");
            if claude_md.exists() {
                return Some(current.to_string_lossy().to_string());
            }
            match current.parent() {
                Some(parent) => current = parent,
                None => break,
            }
        }
    }

    // Fallback: check common locations
    let home = std::env::var("HOME").unwrap_or_default();
    let candidates = [
        format!("{}/code/the-agency", home),
        format!("{}/the-agency", home),
        "/Users/jdm/code/the-agency".to_string(),
    ];

    for candidate in candidates {
        let path = Path::new(&candidate);
        if path.join("CLAUDE.md").exists() {
            return Some(candidate);
        }
    }

    None
}

// Command to get project root (for The Agency context)
#[tauri::command]
fn get_project_root() -> Result<String, String> {
    find_project_root().ok_or_else(|| "Could not find project root (no CLAUDE.md found)".to_string())
}

// Recursively list markdown files in a directory
fn find_markdown_files_recursive(dir: &Path, files: &mut Vec<String>) {
    if let Ok(entries) = std::fs::read_dir(dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            let name = path.file_name().unwrap_or_default().to_string_lossy();

            // Skip hidden directories and node_modules
            if name.starts_with('.') || name == "node_modules" || name == "target" {
                continue;
            }

            if path.is_dir() {
                find_markdown_files_recursive(&path, files);
            } else if let Some(ext) = path.extension() {
                if ext == "md" {
                    files.push(path.to_string_lossy().to_string());
                }
            }
        }
    }
}

// Command to list all markdown files in the project
#[tauri::command]
async fn list_markdown_files(root: String) -> Result<Vec<String>, String> {
    let root_path = Path::new(&root);
    let mut files: Vec<String> = Vec::new();

    find_markdown_files_recursive(root_path, &mut files);

    // Sort files for consistent ordering
    files.sort();

    Ok(files)
}

// Message structures for the messaging system
#[derive(serde::Serialize)]
struct Message {
    id: i64,
    timestamp: String,
    from_type: String,
    from_name: String,
    to_type: String,
    to_name: Option<String>,
    subject: Option<String>,
    content: String,
}

#[derive(serde::Serialize)]
struct MessageRecipient {
    message_id: i64,
    recipient_type: String,
    recipient_name: String,
    read_at: Option<String>,
}

#[derive(serde::Serialize)]
struct MessageWithStatus {
    message: Message,
    recipients: Vec<MessageRecipient>,
}

// Get database path
fn get_messages_db_path() -> Option<String> {
    find_project_root().map(|root| format!("{}/claude/data/messages.db", root))
}

// Command to list all messages (for principal view)
#[tauri::command]
async fn list_messages(limit: Option<i64>) -> Result<Vec<MessageWithStatus>, String> {
    let db_path = get_messages_db_path().ok_or("Could not find messages database")?;

    if !Path::new(&db_path).exists() {
        return Ok(Vec::new());
    }

    let conn = Connection::open(&db_path).map_err(|e| e.to_string())?;
    let limit = limit.unwrap_or(100);

    let mut stmt = conn.prepare(
        "SELECT id, timestamp, from_type, from_name, to_type, to_name, subject, content
         FROM messages ORDER BY timestamp DESC LIMIT ?"
    ).map_err(|e| e.to_string())?;

    let messages: Vec<Message> = stmt.query_map([limit], |row| {
        Ok(Message {
            id: row.get(0)?,
            timestamp: row.get(1)?,
            from_type: row.get(2)?,
            from_name: row.get(3)?,
            to_type: row.get(4)?,
            to_name: row.get(5)?,
            subject: row.get(6)?,
            content: row.get(7)?,
        })
    }).map_err(|e| e.to_string())?
    .filter_map(|r| r.ok())
    .collect();

    // Get recipients for each message
    let mut results: Vec<MessageWithStatus> = Vec::new();
    for msg in messages {
        let mut recipient_stmt = conn.prepare(
            "SELECT message_id, recipient_type, recipient_name, read_at
             FROM recipients WHERE message_id = ?"
        ).map_err(|e| e.to_string())?;

        let recipients: Vec<MessageRecipient> = recipient_stmt.query_map([msg.id], |row| {
            Ok(MessageRecipient {
                message_id: row.get(0)?,
                recipient_type: row.get(1)?,
                recipient_name: row.get(2)?,
                read_at: row.get(3)?,
            })
        }).map_err(|e| e.to_string())?
        .filter_map(|r| r.ok())
        .collect();

        results.push(MessageWithStatus { message: msg, recipients });
    }

    Ok(results)
}

// Command to send a message
#[tauri::command]
async fn send_message(
    from_type: String,
    from_name: String,
    to_type: String,
    to_name: Option<String>,
    subject: Option<String>,
    content: String,
    recipients: Vec<(String, String)>, // (type, name) pairs
) -> Result<i64, String> {
    let db_path = get_messages_db_path().ok_or("Could not find messages database")?;
    let conn = Connection::open(&db_path).map_err(|e| e.to_string())?;

    conn.execute(
        "INSERT INTO messages (from_type, from_name, to_type, to_name, subject, content)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
        (&from_type, &from_name, &to_type, &to_name, &subject, &content),
    ).map_err(|e| e.to_string())?;

    let msg_id = conn.last_insert_rowid();

    for (rtype, rname) in recipients {
        conn.execute(
            "INSERT OR IGNORE INTO recipients (message_id, recipient_type, recipient_name)
             VALUES (?1, ?2, ?3)",
            (msg_id, &rtype, &rname),
        ).map_err(|e| e.to_string())?;
    }

    Ok(msg_id)
}

// Search result structure
#[derive(serde::Serialize)]
struct SearchMatch {
    line: usize,
    content: String,
}

#[derive(serde::Serialize)]
struct SearchResult {
    file: String,
    matches: Vec<SearchMatch>,
}

// Command to search for text in files
#[tauri::command]
async fn search_files(query: String, root: String) -> Result<Vec<SearchResult>, String> {
    let root_path = Path::new(&root);
    let mut markdown_files: Vec<String> = Vec::new();
    find_markdown_files_recursive(root_path, &mut markdown_files);

    let query_lower = query.to_lowercase();
    let mut results: Vec<SearchResult> = Vec::new();

    for file_path in markdown_files {
        if let Ok(content) = std::fs::read_to_string(&file_path) {
            let mut matches: Vec<SearchMatch> = Vec::new();

            for (line_num, line) in content.lines().enumerate() {
                if line.to_lowercase().contains(&query_lower) {
                    matches.push(SearchMatch {
                        line: line_num + 1,
                        content: line.to_string(),
                    });
                }
            }

            if !matches.is_empty() {
                results.push(SearchResult {
                    file: file_path,
                    matches,
                });
            }
        }
    }

    Ok(results)
}

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_dialog::init())
        .invoke_handler(tauri::generate_handler![
            read_file,
            write_file,
            list_files,
            get_project_root,
            list_markdown_files,
            search_files,
            list_messages,
            send_message
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
