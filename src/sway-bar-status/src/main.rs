//! sway-bar-status
//!
//! simple statusbar for sway written in rust
//! this file is full of disgusting safety violations ;D

mod config;
use config::Config;

use glob::glob;
use mpd::Client as MpdClient;
use std::{
    collections::HashMap,
    fs::{self, File},
    io::{stdout, BufRead, BufReader, Write},
    path::PathBuf,
    process::Command,
    thread,
    time::{Duration, SystemTime},
};

const UPDATE_RATE_MS: Duration = Duration::from_millis(1000);
const BATTERY_UPDATE_RATE: u128 = 20000 / UPDATE_RATE_MS.as_millis();
const BACKLIGHT_UPDATE_RATE: u128 = 20000 / UPDATE_RATE_MS.as_millis();

const MEMINFO_FILE: &str = "/proc/meminfo";
const MEMORY_UPDATE_RATE: u128 = 5000 / UPDATE_RATE_MS.as_millis();

const DRIVES_PATH: &str = "/dev/disk/by-label/";
const DRIVES_UPDATE_RATE: u128 = 10000 / UPDATE_RATE_MS.as_millis();
const DRIVES_CYCLE_RATE_MS: usize = 10000;

const TRACK_UPDATE_RATE: u128 = 2000 / UPDATE_RATE_MS.as_millis();

struct Status {
    last_update_time: SystemTime,

    time: String,

    has_bat: bool,
    battery: String,
    bat_cap_file: String,
    bat_stat_file: String,

    has_bl: bool,
    backlight: String,
    bl_max: u32,
    bl_lvl_file: String,

    memory: String,

    drives: String,
    drives_max_length: usize,
    drives_vec: Vec<PathBuf>,
    drives_rename: HashMap<String, String>,

    has_track: bool,
    track_server: String,
    track_client: Option<MpdClient>,
    track: String,
}

impl Status {
    fn new(cfg: Config) -> Status {
        // select the first battery
        let mut has_bat = false;
        let mut bat_selection = "".to_string();
        match cfg.battery {
            Some(b) => {
                bat_selection = b;
                has_bat = true
            }
            None => {
                for path in glob("/sys/class/power_supply/BAT*")
                    .unwrap()
                    .filter_map(Result::ok)
                {
                    bat_selection = format!("{}", path.display());
                    has_bat = true;
                    break;
                }
            }
        }

        // select the first backlight
        let mut has_bl = false;
        let mut bl_selection = "".to_string();
        let mut bl_max: u32 = 0;
        for backlight in glob("/sys/class/backlight/*").unwrap() {
            match backlight {
                Ok(path) => {
                    bl_selection = format!("{}", path.display());
                    let mut max =
                        fs::read_to_string(format!("{}/max_brightness", bl_selection.clone()))
                            .unwrap();
                    max.pop();
                    bl_max = max.parse::<u32>().unwrap();
                    has_bl = true;
                    break;
                }
                Err(_) => (),
            }
        }

        // build list of drives
        let mut drives_vec = Vec::<PathBuf>::new();
        let mut drives_max_length = 0;
        let drives_rename = cfg.drive_rename.unwrap_or(HashMap::new());
        let bl = cfg.drive_blacklist.unwrap_or(Vec::new());
        for drive in glob(format!("{}/*", DRIVES_PATH).as_str()).unwrap() {
            let d = drive.unwrap();
            let dstr = d.as_path().to_str().unwrap();
            let dname = &dstr[DRIVES_PATH.len()..];
            if !bl.iter().any(|s| dname == s) {
                let len = match drives_rename.get(dname) {
                    Some(s) => s.len(),
                    None => dstr.len(),
                };
                if len > drives_max_length {
                    drives_max_length = len
                }
                drives_vec.push(d);
            }
        }
        drives_max_length = drives_max_length - DRIVES_PATH.len();

        // mpd
        let track_server = cfg.mpd_server.unwrap_or("127.0.0.1:6600".to_string());

        // build status settings
        let mut status = Status {
            last_update_time: SystemTime::UNIX_EPOCH,
            time: "".into(),

            has_bat,
            battery: String::new(),
            bat_cap_file: format!("{}/capacity", bat_selection),
            bat_stat_file: format!("{}/status", bat_selection),

            has_bl,
            backlight: String::new(),
            bl_max,
            bl_lvl_file: format!("{}/brightness", bl_selection),

            memory: String::new(),

            drives: String::new(),
            drives_max_length,
            drives_vec,
            drives_rename,

            has_track: false,
            track_server,
            track_client: None,
            track: String::new(),
        };
        status.update_time();
        if has_bat {
            status.update_battery();
        }
        if has_bl {
            status.update_backlight();
        }
        status.update_memory();
        status.update_drives(0);
        status.update_track();
        return status;
    }

    // current time. ex: 1970-01-01 00:00:00
    fn update_time(&mut self) {
        self.time = chrono::Local::now().format("%F %H:%M:%S").to_string();
    }

    // battery charge. ex: =42%
    fn update_battery(&mut self) {
        let mut cap = fs::read_to_string(self.bat_cap_file.clone()).unwrap();
        cap.pop(); // remove newline
        if cap == "100" {
            cap = "MAX".into();
        } else {
            cap = format!("{cap:02}%");
        }

        let mut stat = fs::read_to_string(self.bat_stat_file.clone()).unwrap();
        stat.pop(); // remove newline

        self.battery = format!(
            "{stat}{cap}",
            stat = match stat.as_str() {
                "Charging" => "^",
                "Discharging" => "v",
                _ => "=",
            }
        );
    }

    // backlight brightness. ex: *69%
    fn update_backlight(&mut self) {
        let mut lvl_s = fs::read_to_string(self.bl_lvl_file.clone()).unwrap();
        lvl_s.pop();
        let lvl: u32 = lvl_s.parse().unwrap();

        if lvl == self.bl_max {
            self.backlight = "*MAX".into();
        } else {
            self.backlight = format!("*{:02}%", 100 * lvl / self.bl_max);
        }
    }

    // memory usage. ex: 1.2Gi
    fn update_memory(&mut self) {
        let mem_active_mb: f32;
        {
            // 9th line of meminfo is Active(anon) in kb
            let f = File::open(MEMINFO_FILE).unwrap();
            let mut lines = BufReader::new(f).lines().skip(8).peekable();
            let mem_active_s = match lines.peek().unwrap() {
                Ok(s) => s,
                Err(_) => unreachable!(),
            };
            mem_active_mb = mem_active_s
                .split_whitespace()
                .skip(1)
                .peekable()
                .peek()
                .unwrap()
                .parse::<f32>()
                .unwrap()
                / 1024.0;
        }
        if mem_active_mb > 999.0 {
            self.memory = format!("#{:.01}Gi", mem_active_mb / 1024.0);
        } else {
            self.memory = format!("#{:.0}Mi", mem_active_mb);
        }
    }

    // storage usage. ex: HOME 21%
    // TODO use syscasll instead of df
    fn update_drives(&mut self, elapsed: u128) {
        let i = elapsed as usize / DRIVES_CYCLE_RATE_MS % self.drives_vec.len();
        let drive = self.drives_vec.get(i).unwrap().as_path();
        let mut drive_use = String::from_utf8(
            Command::new("/usr/bin/df")
                .arg("-h")
                .arg("--output=pcent")
                .arg(drive)
                .output()
                .unwrap()
                .stdout,
        )
        .unwrap();
        drive_use.pop();
        drive_use = drive_use
            .lines()
            .skip(1)
            .peekable()
            .peek()
            .unwrap()
            .to_string();
        let mut dstr = drive.file_name().unwrap().to_str().unwrap();
        match self.drives_rename.get(dstr) {
            Some(rn) => dstr = rn,
            None => (),
        }
        self.drives = format!(
            "{: <1$}{pcent}",
            dstr.to_lowercase(),
            self.drives_max_length,
            pcent = drive_use,
        );
    }

    // now playing. ex: Touhiron 3:04/4:35 [19%]
    fn update_track(&mut self) {
        if self.track_client.is_none() {
            // try reconnecting every update until it works lolmao
            eprintln!("attempting to connect to MPD...");
            self.track_client = MpdClient::connect(&self.track_server).ok();
            self.has_track = false;
            return;
        }

        let tcl = self.track_client.as_mut().unwrap();
        match tcl.status() {
            Ok(status) => {
                if status.state != mpd::status::State::Play {
                    self.has_track = false;
                    return;
                }
                self.has_track = true;
                let song = tcl.currentsong().unwrap().unwrap(); // not atomic but rare enough to not care(?)
                let artist = song.artist.unwrap_or("Unknown Artist".into());
                let track = song.title.unwrap_or("Unknown Track".into());
                let (position, end) = status.time.unwrap(); // duration shoul always extist when playing ?
                let vol = match status.volume {
                    100 => "MAX".to_string(),
                    _ => format!("{:0>2}%", status.volume),
                };
                self.track = format!(
                    "{artist} - {track} {pm}:{ps:0>2}/{em}:{es:0>2} [{vol}]",
                    pm = position.as_secs() / 60,
                    ps = position.as_secs() % 60,
                    em = end.as_secs() / 60,
                    es = end.as_secs() % 60,
                );
            }
            Err(_) => {
                self.has_track = false;
                self.track_client = None; // new connection will be established on next update
            }
        }
    }

    // update according to preferred refresh rate
    fn update(&mut self) {
        let time = SystemTime::now();
        let elapsed = time
            .duration_since(SystemTime::UNIX_EPOCH)
            .unwrap()
            .as_millis();

        let loop_num = elapsed / UPDATE_RATE_MS.as_millis();
        self.update_time();
        if self.has_bat && loop_num % BATTERY_UPDATE_RATE == 0 {
            self.update_battery();
        }
        if self.has_bl && loop_num % BACKLIGHT_UPDATE_RATE == 0 {
            self.update_backlight();
        }
        if loop_num % MEMORY_UPDATE_RATE == 0 {
            self.update_memory();
        }
        if loop_num % DRIVES_UPDATE_RATE == 0 {
            self.update_drives(elapsed);
        }
        if loop_num % TRACK_UPDATE_RATE == 0 {
            self.update_track();
        }

        self.last_update_time = time;
    }

    // print out current status
    fn print(&self) {
        if self.has_track {
            print!("{} | ", self.track);
        }
        print!("{} | {} | ", self.drives, self.memory);
        if self.has_bl {
            print!("{} | ", self.backlight);
        }
        if self.has_bat {
            print!("{} | ", self.battery);
        }
        println!("{}", self.time);
        stdout().flush().unwrap();
    }
}

// loop
fn main() {
    // TODO wait to align to exact second if possible
    let config = Config::get_config();
    let mut status = Status::new(config);
    status.print();
    thread::sleep(UPDATE_RATE_MS);

    loop {
        status.update();
        status.print();
        thread::sleep(UPDATE_RATE_MS);
    }
}
