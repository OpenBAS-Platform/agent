use std::env;
use std::fs::{create_dir, File};
use std::io::Write;
use std::path::PathBuf;
use std::process::{Command, Stdio};
use log::info;
use crate::common::error_model::Error;

pub fn compute_working_dir(asset_agent_id: &str) -> PathBuf {
    let current_exe_patch = env::current_exe().unwrap();
    let executable_path = current_exe_patch.parent().unwrap();
    return executable_path.join(format!("execution-{}", asset_agent_id));
}

pub fn command_execution(asset_agent_id: &str, command: &str) -> Result<(), Error> {
    if cfg!(target_os = "windows") {
        let working_dir = compute_working_dir(asset_agent_id);
        let command_with_location = command.replace("#{location}", working_dir.to_str().unwrap());
        info!(identifier:? = asset_agent_id, command:? = command_with_location; "Invoking execution");
        // Write the script in specific directory
        create_dir(working_dir.clone())?;
        let script_file_name = working_dir.join("execution.ps1");
        {
            let mut file = File::create(script_file_name.clone())?;
            file.write_all(command_with_location.as_bytes())?;
        }
        // Prepare and execute the command
        let command_args = &["/d", "/c", "powershell.exe", "-ExecutionPolicy", "Bypass", "-WindowStyle", "Hidden",
            "-NonInteractive", "-NoProfile", script_file_name.to_str().unwrap()];
        let child_execution = Command::new("cmd.exe")
            .args(command_args)
            .stderr(Stdio::piped())
            .stdout(Stdio::piped())
            .spawn()?;
        // Save execution pid
        let pid_file_name = working_dir.join("execution.pid");
        {
            let mut file = File::create(pid_file_name.clone())?;
            file.write_all(child_execution.id().to_string().as_bytes())?;
        }
        info!(identifier:? = asset_agent_id; "Invoking result");
        return Ok(())
    }
    if cfg!(target_os = "linux") || cfg!(target_os = "macos") {
        let working_dir = compute_working_dir(asset_agent_id);
        let command_with_location = command.replace("#{location}", working_dir.to_str().unwrap());
        info!(identifier = asset_agent_id, command = &command_with_location.as_str(); "Invoking execution");
        // Write the script in specific directory
        create_dir(working_dir.clone())?;
        let script_file_name = working_dir.join("execution.sh");
        {
            let mut file = File::create(script_file_name.clone())?;
            file.write_all(command_with_location.as_bytes())?;
        }
        // Prepare and execute the command
        let command_args = &[script_file_name.to_str().unwrap(), "&"];
        let child_execution = Command::new("bash")
            .args(command_args)
            .stderr(Stdio::piped())
            .stdout(Stdio::piped())
            .spawn()?;
        // Save execution pid
        let pid_file_name = working_dir.join("execution.pid");
        {
            let mut file = File::create(pid_file_name.clone())?;
            file.write_all(child_execution.id().to_string().as_bytes())?;
        }
        info!(identifier = asset_agent_id; "Revoking execution");
        return Ok(())
    }
    Err(Error::Internal(String::from("Not implemented yet")))
}