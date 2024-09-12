//! sway-bar-status
//!
//! simple statusbar for sway written in rust
//! this file is full of disgusting safety violations ;D

use glob::glob;
use std::{
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

const TRACK_UPDATE_RATE: u128 = 5000 / UPDATE_RATE_MS.as_millis();

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

    has_track: bool,
    track: String,
}

impl Status {
    fn new() -> Status {
        // select the first battery
        let mut has_bat = true;
        let mut bat_selection = "".to_string();
        for battery in glob("/sys/class/power_supply/BAT*").unwrap() {
            match battery {
                Ok(path) => {
                    bat_selection = format!("{}", path.display());
                    break;
                }
                Err(_) => has_bat = false,
            }
        }

        // select the first backlight
        let mut has_bl = true;
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
                    break;
                }
                Err(_) => has_bl = false,
            }
        }

        // build list of drives
        let mut drives_vec = Vec::<PathBuf>::new();
        let mut drives_max_length = 0;
        for drive in glob(format!("{}/*", DRIVES_PATH).as_str()).unwrap() {
            match drive {
                Ok(d) => {
                    let len = d.as_path().to_str().unwrap().len();
                    if len > drives_max_length {
                        drives_max_length = len
                    }
                    drives_vec.push(d);
                }
                Err(_) => unreachable!(),
            }
        }
        drives_max_length = drives_max_length - DRIVES_PATH.len();

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

            has_track: false,
            track: String::new(),
        };
        status.update_time();
        status.update_battery();
        status.update_backlight();
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
        let mut stat = fs::read_to_string(self.bat_stat_file.clone()).unwrap();
        stat.pop(); // remove newline

        self.battery = format!(
            "{stat}{cap}%",
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
            self.memory = format!("#{}Mi", mem_active_mb);
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

        self.drives = format!(
            "{: <1$}{pcent}",
            drive
                .file_name()
                .unwrap()
                .to_ascii_lowercase()
                .to_str()
                .unwrap(),
            self.drives_max_length,
            pcent = drive_use,
        );
    }

    // now playing. ex: Touhiron 3:04/4:35 [19%]
    // TODO use something besides mpc
    fn update_track(&mut self) {
        let mpc_out =
            String::from_utf8(Command::new("/usr/bin/mpc").output().unwrap().stdout).unwrap();
        let mut track = "";
        let mut status = "";
        let mut position = "";
        let mut volume = "";

        for (i, line) in mpc_out.lines().enumerate() {
            match i {
                0 => track = line,
                1 => {
                    for (j, col) in line.split_whitespace().enumerate() {
                        match j {
                            0 => status = col,
                            1 => (),
                            2 => position = col,
                            _ => break,
                        }
                    }
                }
                2 => volume = line.split_whitespace().skip(1).peekable().peek().unwrap(),
                _ => break,
            }
        }

        if status != "[playing]" {
            self.has_track = false;
            return;
        }
        self.has_track = true;
        self.track = format!("{track} {position} [{volume}]");
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
    let mut status = Status::new();
    status.print();
    thread::sleep(UPDATE_RATE_MS);

    loop {
        status.update();
        status.print();
        thread::sleep(UPDATE_RATE_MS);
    }
}
