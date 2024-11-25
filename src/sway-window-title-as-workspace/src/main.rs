//! sway-window-title-as-workspace
//! creates an empty wayland window and assigns it to a workspace that gets renamed to the currently focused window
use std::sync::{Arc, Mutex};
use std::thread;
use substring::Substring;
use swayipc::{Connection, Event, EventType, Fallible, WindowChange, WorkspaceChange};

mod wl_window;
use wl_window::create_blank_window;

const MAX_TITLE_LENGTH: usize = 100;
const STARTING_NAME: &str = "_";

fn main() -> Fallible<()> {
    // setup
    let mut ipc_connection = Connection::new()?;
    let mut last_name: String = STARTING_NAME.into();

    // spawn a new window on STARTING name then switch back the the last focused workspace
    for workspace in ipc_connection.get_workspaces()? {
        if workspace.focused {
            // create empty window in new workspace
            ipc_connection.run_command(format!(
                r#"assign [app_id="dev.theokrueger.sway-named-workspace"] workspace [{}]"#,
                STARTING_NAME
            ))?;
            let init_mutex = Arc::new(Mutex::new(false));
            let thread_mutex = init_mutex.clone();
            thread::spawn(|| {
                create_blank_window(thread_mutex);
            });

            // wait for thread to finish setup before continuing
            thread::sleep(std::time::Duration::from_millis(20));
            let _unused = init_mutex.lock().unwrap();
            thread::sleep(std::time::Duration::from_millis(20));
            break;
        }
    }

    // loop
    for event in Connection::new()?.subscribe([EventType::Window, EventType::Workspace])? {
        match event? {
            Event::Window(w) => {
                // ensure window title doesnt get updated when it shouldn't
                let mut cur_name: String = "_".into();
                match w.change {
                    WindowChange::Close | WindowChange::Urgent => (),
                    _ => {
                        cur_name =
                            format!("{}", w.container.name.unwrap_or_else(|| "_".to_owned()))
                                .replace(&['\'', '\"', '(', ')', '\\', '$'][..], "")
                                .substring(0, MAX_TITLE_LENGTH)
                                .into();
                    },
                }
                ipc_connection.run_command(format!(
                    "rename workspace '[{}]' to '[{}]'",
                    last_name, cur_name
                ))?;
                last_name = cur_name;
            }
            Event::Workspace(w) => match w.change {
                WorkspaceChange::Focus => {
                    ipc_connection
                        .run_command(format!("rename workspace '[{}]' to '[_]'", last_name))?;
                    last_name = "_".into();
                }
                _ => (),
            },
            _ => unreachable!(),
        }
    }
    Ok(())
}
