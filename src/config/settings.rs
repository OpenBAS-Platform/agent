use config::{Config, ConfigError, Environment, File};
use std::env;
use log::info;
use serde::Deserialize;

const ENV_PRODUCTION: &str = "production";

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
        let run_mode = env::var("env").unwrap_or_else(|_| ENV_PRODUCTION.into());
        info!("Starting OpenBAS agent 0.0.1 ({})", run_mode);
        let config = Config::builder().add_source(Environment::with_prefix("openbas"));
        if run_mode == ENV_PRODUCTION {
            config.add_source(File::with_name("openbas-agent").required(true)).build()?.try_deserialize()
        } else {
            config.add_source(File::with_name("config/default"))
                .add_source(File::with_name(&format!("config/{}", run_mode)).required(false))
                .build()?.try_deserialize()
        }
    }
}