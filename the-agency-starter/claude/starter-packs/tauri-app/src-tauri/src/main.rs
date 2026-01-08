// Prevents additional console window on Windows in release
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

/// Read a file from the filesystem
#[tauri::command]
async fn read_file(path: String) -> Result<String, String> {
    std::fs::read_to_string(&path).map_err(|e| e.to_string())
}

/// Write content to a file
#[tauri::command]
async fn write_file(path: String, content: String) -> Result<(), String> {
    std::fs::write(&path, content).map_err(|e| e.to_string())
}

/// List files in a directory
#[tauri::command]
async fn list_directory(path: String) -> Result<Vec<String>, String> {
    let entries = std::fs::read_dir(&path).map_err(|e| e.to_string())?;

    let files: Vec<String> = entries
        .filter_map(|e| e.ok())
        .map(|e| e.path().to_string_lossy().to_string())
        .collect();

    Ok(files)
}

/// Example command - customize this for your app
#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! Welcome to your Tauri app.", name)
}

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_dialog::init())
        .invoke_handler(tauri::generate_handler![
            read_file,
            write_file,
            list_directory,
            greet
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
