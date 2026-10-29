//! sway-autotiler
//! simple autotiling daemon for sway
//! switches the focused container between splith and splitv based on its height/width ratio

mod args;
mod master;
mod tiling;
mod tree;

use clap::Parser;
use swayipc::{Connection, Event, EventType, Fallible, WindowChange};

use args::Args;
use master::focus_to_master;
use tiling::autotile;

fn main() -> Fallible<()> {
    let args = Args::parse();

    if args.focus_to_master {
        return focus_to_master();
    }

    let mut connection = Connection::new()?;
    let event_stream = Connection::new()?.subscribe([EventType::Window, EventType::Mode])?;

    for event in event_stream {
        let event = match event {
            Ok(event) => event,
            Err(error) => {
                // a closed socket means sway exited/restarted; exit quietly
                if !matches!(error, swayipc::Error::Io(_)) {
                    eprintln!("Error: {error}");
                }
                break;
            }
        };

        let is_new_or_moved = matches!(
            &event,
            Event::Window(window)
                if matches!(window.change, WindowChange::New | WindowChange::Move)
        );

        if let Err(error) = autotile(&mut connection, is_new_or_moved, &args) {
            eprintln!("Error: {error}");
        }
    }

    Ok(())
}
