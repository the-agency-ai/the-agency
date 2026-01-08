// Prevents additional console window on Windows in release
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use tauri::Manager;

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

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_dialog::init())
        .invoke_handler(tauri::generate_handler![
            read_file,
            list_files,
            get_project_root
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
