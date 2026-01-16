// sample cfg
/*
{
  "drive_rename": {
  "EFI\\x20-\\x20GENTO": "EFI"
  },
  "drive_blacklist": [
    "SWAP"
  ],
  "battery": "/sys/class/power_supply/macsmc-battery/"
}
*/
use resolve_path::PathResolveExt;
use serde::Deserialize;
use std::{collections::HashMap, fs};

#[derive(Deserialize)]
pub struct Config {
    pub drive_rename: Option<HashMap<String, String>>,
    pub drive_blacklist: Option<Vec<String>>,
    pub battery: Option<String>,
}

impl Config {
    pub fn get_config() -> Self {
        match fs::read_to_string("~/.config/sway-bar-status.json".resolve()) {
            Ok(s) => serde_json::from_str::<Config>(s.as_str()).expect("Unable to parse config!"),
            Err(_) => {
                println!("no config at '~/.config/sway-bar-status.json' found! using defaults");
                Config {
                    drive_rename: None,
                    drive_blacklist: None,
                    battery: None,
                }
            }
        }
    }
}
