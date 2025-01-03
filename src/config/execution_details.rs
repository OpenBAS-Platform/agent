use config::{Config, ConfigError, Environment, File};
use std::env;
use std::process::{Command, Stdio};
use log::info;
use serde::Deserialize;

#[derive(Debug, Deserialize)]
#[allow(unused)]
pub struct ExecutionDetails {
    pub is_elevated: bool,
    pub executed_by_user: String,
}

impl ExecutionDetails {
    pub fn new() -> Result<Self, ConfigError> {
        // TODO is service for Ubuntu !?
        let output = if cfg!(target_os = "windows") {
            Command::new("powershell")
                .args([
                    "-ExecutionPolicy",
                    "Bypass",
                    "-WindowStyle",
                    "Hidden",
                    "-NonInteractive",
                    "-NoProfile",
                    "-Command"])
                .arg("whoami; ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator);")
                .stdout(Stdio::piped())
                .spawn().unwrap()
                .wait_with_output()
        } else {
            Command::new("sh")
                .arg("-c")
                .arg("whoami & id & ps -Flww -p $PPID")
                .stdout(Stdio::piped())
                .spawn().unwrap()
                .wait_with_output()
        };
        let result = String::from_utf8(output.unwrap().stdout.to_vec()).unwrap();
        let mut test = result.split("\r\n");
        let name = test.next().unwrap();
        info!("{:?} ---- {:?} ---- {:?}", name, test.next().unwrap(), test.next().unwrap());
        Ok(ExecutionDetails {
            is_elevated: true,
            executed_by_user: "toto".to_string(),
        })
    }
}