// Prevents additional console window on Windows in release
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::path::Path;

// Command to read a file from the filesystem
#[tauri::command]
async fn read_file(path: String) -> Result<String, String> {
    std::fs::read_to_string(&path).map_err(|e| e.to_string())
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

// Command to get project root (for The Agency context)
#[tauri::command]
fn get_project_root() -> Result<String, String> {
    std::env::current_dir()
        .map(|p| p.to_string_lossy().to_string())
        .map_err(|e| e.to_string())
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
            list_files,
            get_project_root,
            list_markdown_files,
            search_files
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
