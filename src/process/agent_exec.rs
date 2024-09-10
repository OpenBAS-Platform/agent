use log::info;
use std::ffi::OsString;
use std::fs::{create_dir, File};
use std::io::Write;
use std::os::windows::ffi::OsStringExt;
use std::os::windows::process::CommandExt;
use std::path::PathBuf;
use std::process::{Command, Stdio};
use std::ptr::null_mut;
use std::{env, mem};
use winapi::um::winbase::{CREATE_UNICODE_ENVIRONMENT, WAIT_OBJECT_0};
use windows_sys::Win32::Foundation::{CloseHandle, GetLastError};
use windows_sys::Win32::System::Diagnostics::Debug::{
    FormatMessageW, FORMAT_MESSAGE_ALLOCATE_BUFFER, FORMAT_MESSAGE_FROM_SYSTEM, FORMAT_MESSAGE_IGNORE_INSERTS,
};
use windows_sys::Win32::System::Threading::{CreateProcessWithLogonW, GetExitCodeProcess, WaitForSingleObject, INFINITE, PROCESS_INFORMATION, STARTUPINFOW};

fn compute_working_dir(asset_agent_id: &str) -> PathBuf {
    let current_exe_patch = env::current_exe().unwrap();
    let executable_path = current_exe_patch.parent().unwrap();
    return executable_path.join(format!("execution-{}", asset_agent_id));
}

fn command_with_context(asset_agent_id: &str, command: &str) -> String {
    let working_dir = compute_working_dir(asset_agent_id);
    let command_server_location = command.replace("#{location}", working_dir.to_str().unwrap());
    if cfg!(target_os = "windows") {
        return format!("Set-Location -Path \"{}\"; {}", working_dir.to_str().unwrap(), command_server_location);
    }
    if cfg!(target_os = "linux") || cfg!(target_os = "macos") {
        return format!("cd \"{}\"; {}", working_dir.to_str().unwrap(), command_server_location);
    }
    return String::from(command);
}

// Helper function to get a readable error message from the Windows API
fn get_last_error_message() -> String {
    let error_code = unsafe { GetLastError() };
    if error_code == 0 {
        return "No error".to_string();
    }

    let mut buffer: Vec<u16> = Vec::with_capacity(512);
    let len = unsafe {
        FormatMessageW(
            FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_IGNORE_INSERTS,
            null_mut(),
            error_code,
            0,
            buffer.as_mut_ptr(),
            buffer.capacity() as u32,
            null_mut(),
        )
    };

    if len == 0 {
        return "Failed to format error message".to_string();
    }

    unsafe { buffer.set_len(len as usize) }; // Set the length of the buffer

    // Convert wide string to UTF-8
    OsString::from_wide(&buffer).to_string_lossy().to_string()
}

// Helper function to convert a Rust string to a null-terminated wide string
fn to_wide_string(s: &str) -> Vec<u16> {
    let mut wide: Vec<u16> = s.encode_utf16().collect();
    wide.push(0); // Null terminator
    wide
}

fn run_as_user_command(username: &str, domain: &str, password: &str, script_file_path: &PathBuf) -> Option<u32> {
    // Convert parameters to wide strings
    let username_wide = to_wide_string(username);
    let domain_wide = to_wide_string(domain);
    let password_wide = to_wide_string(password);

    println!("Script file path: {}", script_file_path.to_str().unwrap());

    let command_line = format!(
        "cmd.exe /d /c powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -NonInteractive -NoProfile -File \"{}\"",
        script_file_path.to_str().unwrap()
    );

    println!("Command line: {}", command_line.as_str());

    let command_wide = to_wide_string(&command_line);

    // Initialize STARTUPINFOW structure
    let mut startup_info = STARTUPINFOW {
        cb: mem::size_of::<STARTUPINFOW>() as u32,
        lpReserved: null_mut(),
        lpDesktop: null_mut(),
        lpTitle: null_mut(),
        dwX: 0,
        dwY: 0,
        dwXSize: 0,
        dwYSize: 0,
        dwXCountChars: 0,
        dwYCountChars: 0,
        dwFillAttribute: 0,
        dwFlags: 0,
        wShowWindow: 0,
        cbReserved2: 0,
        lpReserved2: null_mut(),
        hStdInput: null_mut(),
        hStdOutput: null_mut(),
        hStdError: null_mut(),
    };

    // Initialize PROCESS_INFORMATION structure
    let mut process_info = PROCESS_INFORMATION {
        hProcess: null_mut(),
        hThread: null_mut(),
        dwProcessId: 0,
        dwThreadId: 0,
    };

    // Call CreateProcessWithLogonW
    let result = unsafe {
        CreateProcessWithLogonW(
            username_wide.as_ptr(),
            domain_wide.as_ptr(),
            password_wide.as_ptr(),
            0, // LOGON_WITH_PROFILE
            null_mut(), // Application name
            command_wide.as_ptr() as *mut u16, // Command line
            CREATE_UNICODE_ENVIRONMENT,
            null_mut(), // No environment block
            null_mut(), // Current directory is inherited
            &mut startup_info as *mut _,
            &mut process_info as *mut _,
        )
    };

    if result != 0 {
        // Process created successfully
        eprintln!("PID process: {}", process_info.dwProcessId);

        // Wait for the process to exit and capture its exit code
        let mut exit_code: u32 = 0;
        unsafe {
            let wait_result = WaitForSingleObject(process_info.hProcess, INFINITE);
            if wait_result == WAIT_OBJECT_0 {
                GetExitCodeProcess(process_info.hProcess, &mut exit_code);
                eprintln!("Process exited with code: {}", exit_code);
            } else {
                eprintln!("Failed to wait for the process. Error: {}", get_last_error_message());
            }

            // Close handles
            CloseHandle(process_info.hProcess);
            CloseHandle(process_info.hThread);
        }

        Some(process_info.dwProcessId)
    } else {
        // Failed to create the process, retrieve the error message
        let error_code = unsafe { GetLastError() };
        println!("Failed to create process, error code: {}", error_code);
        None
    }
}

#[cfg(target_os = "windows")]
pub fn command_execution(
    asset_agent_id: &str,
    raw_command: &str,
    asset_agent_elevation_required: bool,
    non_system_user: &str,
    non_system_pwd: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    let command = command_with_context(asset_agent_id, raw_command);
    let working_dir = compute_working_dir(asset_agent_id);
    info!(identifier:? = asset_agent_id, command:? = command; "Invoking execution");
    // Write the script in specific directory
    create_dir(working_dir.clone())?;
    let script_file_name = working_dir.join("execution.ps1");
    {
        let mut file = File::create(script_file_name.clone())?;
        file.write_all(command.as_bytes())?;
    }

    if asset_agent_elevation_required {
        // Prepare and execute the command with elevation
        let win_path = format!("\"{}\"", script_file_name.to_str().unwrap());
        let command_args = &[
            "/d", "/c", "powershell.exe", "-ExecutionPolicy", "Bypass", "-WindowStyle", "Hidden",
            "-NonInteractive", "-NoProfile", "-File"
        ];
        let child_execution = Command::new("cmd.exe")
            .args(command_args)
            .raw_arg(win_path.as_str())
            .stderr(Stdio::null())
            .stdout(Stdio::null())
            .spawn()?;

        // Save execution PID to a file
        let pid_file_name = working_dir.join("execution.pid");
        {
            let mut file = File::create(pid_file_name)?;
            file.write_all(child_execution.id().to_string().as_bytes())?;
        }
    } else {
        // Execute the command as a specific user
        if let Some(pid) = run_as_user_command(non_system_user, "savacano28", non_system_pwd, &script_file_name) {
            // Save execution PID to a file
            let pid_file_name = working_dir.join("execution.pid");
            {
                let mut file = File::create(pid_file_name)?;
                file.write_all(pid.to_string().as_bytes())?;
            }
        } else {
            eprintln!("Failed to execute the command as the specified user.");
        }
    }

    info!(identifier:? = asset_agent_id; "Invoking result");
    Ok(())
}

#[cfg(any(target_os = "linux", target_os = "macos"))]
pub fn command_execution(asset_agent_id: &str, raw_command: &str) -> Result<(), Error> {
    let command = command_with_context(asset_agent_id, raw_command);
    let working_dir = compute_working_dir(asset_agent_id);
    info!(identifier = asset_agent_id, command = &command.as_str(); "Invoking execution");
    // Write the script in specific directory
    create_dir(working_dir.clone())?;
    let script_file_name = working_dir.join("execution.sh");
    {
        let mut file = File::create(script_file_name.clone())?;
        file.write_all(command.as_bytes())?;
    }
    // Prepare and execute the command
    let command_args = &[script_file_name.to_str().unwrap(), "&"];
    let child_execution = Command::new("bash")
        .args(command_args)
        .stderr(Stdio::null())
        .stdout(Stdio::null())
        .spawn()?;
    // Save execution pid
    let pid_file_name = working_dir.join("execution.pid");
    {
        let mut file = File::create(pid_file_name.clone())?;
        file.write_all(child_execution.id().to_string().as_bytes())?;
    }
    info!(identifier = asset_agent_id; "Revoking execution");
    return Ok(());
}