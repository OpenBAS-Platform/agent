use config::{Config, ConfigError, Environment, File};
use std::env;
use log::info;
use serde::Deserialize;

#[derive(Debug, Deserialize)]
#[allow(unused)]
pub struct OpenBAS {
    pub url: String,
    pub token: String,
}

#[derive(Debug, Deserialize)]
#[allow(unused)]
pub struct Settings {
    pub debug: bool,
    pub openbas: OpenBAS,
}

impl Settings {
    pub fn new() -> Result<Self, ConfigError> {
        let run_mode = env::var("env").unwrap_or_else(|_| "production".into());
        info!("Starting OpenBAS agent 0.0.1 ({})", run_mode);
        let s = Config::builder()
            .add_source(File::with_name("config/default"))
            .add_source(File::with_name(&format!("config/{}", run_mode)).required(false))
            .add_source(Environment::with_prefix("openbas"))
            .build()?;
        s.try_deserialize()
    }
}