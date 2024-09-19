use config::{Config, ConfigError, Environment, File};
use serde::Deserialize;
use std::env;

const ENV_PRODUCTION: &str = "production";
const ENV_PRODUCTION_CONFIG_FILE: &str = "openbas-agent-config";

#[derive(Debug, Deserialize, Clone)]
#[allow(unused)]
pub struct OpenBAS {
    pub url: String,
    pub token: String,
    pub non_system_user: String,
    pub non_system_pwd: String,
}

#[derive(Debug, Deserialize, Clone)]
#[allow(unused)]
pub struct Settings {
    pub debug: bool,
    pub openbas: OpenBAS,
}

impl Settings {
    pub fn mode() -> String {
        return env::var("env").unwrap_or_else(|_| ENV_PRODUCTION.into());
    }

    pub fn new() -> Result<Self, ConfigError> {
        let run_mode = Self::mode();
        let config = Config::builder().add_source(Environment::with_prefix("openbas"));
        if run_mode == ENV_PRODUCTION {
            // Get the current executable path
            let current_exe_patch = env::current_exe().unwrap();
            let parent_path = current_exe_patch.parent().unwrap();
            // Join the expected config file with the parent
            let config_file = parent_path.join(ENV_PRODUCTION_CONFIG_FILE);
            let config_path = config_file.display();
            config.add_source(File::with_name(&config_path.to_string()).required(true)).build()?.try_deserialize()
        } else {
            config.add_source(File::with_name("config/default"))
                .add_source(File::with_name(&format!("config/{}", run_mode)).required(false))
                .build()?.try_deserialize()
        }
    }
}