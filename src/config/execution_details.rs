use config::{ConfigError};
use std::process::{Command, Output, Stdio};
use serde::Deserialize;

#[derive(Debug, Deserialize)]
#[allow(unused)]
pub struct ExecutionDetails {
    pub is_elevated: bool,
    pub is_service: bool,
    pub executed_by_user: String,
}

impl ExecutionDetails {

    pub fn invoke_command(executor: &str, cmd_expression:  &str, args: &[&str]) -> std::io::Result<Output> {
        Command::new(executor)
            .args(args)
            .arg(cmd_expression)
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()?
            .wait_with_output()
    }

    pub fn decode_output(raw_bytes: &[u8]) -> String {
        // Try decoding as UTF-8
        if let Ok(decoded) = String::from_utf8(raw_bytes.to_vec()) {
            return decoded; // Return if successful
        }
        // Fallback to UTF-8 lossy decoding
        String::from_utf8_lossy(raw_bytes).to_string()
    }

    #[cfg(target_os = "windows")]
    pub fn new(is_service: bool) -> Result<Self, ConfigError> {
        let executor = "powershell";
        let args = Vec::from([
            "-ExecutionPolicy",
            "Bypass",
            "-WindowStyle",
            "Hidden",
            "-NonInteractive",
            "-NoProfile",
            "-Command"]);
        let user_output = Self::invoke_command(executor, "whoami", args.as_slice());
        let user = Self::decode_output(&user_output.unwrap().clone().stdout).replace("\r\n", "");
        let is_elevated_output = Self::invoke_command(executor,
                                                      "([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator);", args.as_slice());
        let is_elevated = Self::decode_output(&is_elevated_output.unwrap().clone().stdout);
        Ok(ExecutionDetails {
            is_elevated: is_elevated.contains("True"),
            is_service,
            executed_by_user: user,
        })
    }

    #[cfg(target_os = "linux")]
    pub fn new(_is_service: bool) -> Result<Self, ConfigError> {
        let executor = "sh";
        let args = vec!["-c"];
        let user_output = Self::invoke_command(executor, "whoami", args.as_slice());
        let user = Self::decode_output(&user_output.unwrap().clone().stdout).replace("\n", "");
        if user == "root" {
            Ok(ExecutionDetails {
                is_elevated: true,
                is_service: true,
                executed_by_user: user,
            })
        } else {
            let is_elevated_output = Self::invoke_command(executor, "id", args.as_slice());
            let is_elevated = Self::decode_output(&is_elevated_output.unwrap().clone().stdout);
            let is_service_output = Self::invoke_command(executor, "systemctl status $PPID", args.as_slice());
            let is_service = Self::decode_output(&is_service_output.unwrap().clone().stdout);
            Ok(ExecutionDetails {
                is_elevated: is_elevated.contains("(sudo)"),
                is_service: is_service.split("\n").next().unwrap().contains("openbas-agent.service"),
                executed_by_user: user,
            })
        }
    }

    #[cfg(target_os = "macos")]
    pub fn new(_is_service: bool) -> Result<Self, ConfigError> {
        let executor = "sh";
        let args = vec!["-c"];
        let user_output = Self::invoke_command(executor, "whoami", args.as_slice());
        let user = Self::decode_output(&user_output.unwrap().clone().stdout).replace("\n", "");
        if user == "root" {
            Ok(ExecutionDetails {
                is_elevated: true,
                is_service: true,
                executed_by_user: user,
            })
        } else {
            let is_elevated_output = Self::invoke_command(executor, "id", args.as_slice());
            let is_elevated = Self::decode_output(&is_elevated_output.unwrap().clone().stdout);
            let is_service_output = Self::invoke_command(executor, "launchctl print openbas.agent", args.as_slice());
            let is_service = Self::decode_output(&is_service_output.unwrap().clone().stderr);
            Ok(ExecutionDetails {
                is_elevated: is_elevated.contains("(admin)"),
                is_service: is_service.contains("openbas.agent"),
                executed_by_user: user,
            })
        }
    }
}