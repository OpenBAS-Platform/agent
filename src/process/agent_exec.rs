use std::process::{Command, Stdio};
use base64::Engine;
use base64::prelude::BASE64_STANDARD;
use log::info;
use crate::common::error_model::Error;

pub struct ExecutionResult {
    pub stdout: String,
    pub stderr: String,
}

pub fn command_execution(command: &str) -> Result<ExecutionResult, Error> {
    if cfg!(target_os = "windows") {
        let invoke_expression = format!("Invoke-Expression ([System.Text.Encoding]::UTF8.GetString([convert]::FromBase64String(\"{}\")))", BASE64_STANDARD.encode(command));
        let command_args = &["/d", "/c", "powershell.exe", "-ExecutionPolicy", "Bypass", "-WindowStyle", "Hidden", "-NonInteractive", "-NoProfile", "-Command", &invoke_expression];
        info!("Invoking command execution {}", command_args.join(" "));
        let invoke_output = Command::new("cmd.exe")
            .args(command_args)
            .stderr(Stdio::piped())
            .stdout(Stdio::piped())
            .spawn()?.wait_with_output();
        let invoke_result = invoke_output.unwrap().clone();
        let stdout =  String::from_utf8 (invoke_result.stdout).unwrap();
        let stderr = String::from_utf8 (invoke_result.stderr).unwrap();
        Ok(ExecutionResult { stderr, stdout })
    } else {
        // LINUX|MAC => /bin/sh -c "/bin/echo $1 | base64 -d | sh"
        Err(Error::Internal(String::from("Not implemented yet")))
    }
}