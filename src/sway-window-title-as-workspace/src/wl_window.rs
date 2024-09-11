// simple wayland window from https://github.com/Smithay/client-toolkit/blob/master/examples/simple_window.rs
use std::sync::{Arc, Mutex};
use std::time::Duration;

use smithay_client_toolkit::activation::RequestData;
use smithay_client_toolkit::reexports::calloop::EventLoop;
use smithay_client_toolkit::reexports::calloop_wayland_source::WaylandSource;
use smithay_client_toolkit::{
    activation::{ActivationHandler, ActivationState},
    compositor::{CompositorHandler, CompositorState},
    delegate_activation, delegate_compositor, delegate_keyboard, delegate_output, delegate_pointer,
    delegate_registry, delegate_seat, delegate_shm, delegate_xdg_shell, delegate_xdg_window,
    output::{OutputHandler, OutputState},
    registry::{ProvidesRegistryState, RegistryState},
    registry_handlers,
    seat::{
        keyboard::{KeyEvent, KeyboardHandler, Keysym, Modifiers},
        pointer::{PointerEvent, PointerHandler},
        Capability, SeatHandler, SeatState,
    },
    shell::{
        xdg::{
            window::{Window, WindowConfigure, WindowDecorations, WindowHandler},
            XdgShell,
        },
        WaylandSurface,
    },
    shm::{
        slot::{Buffer, SlotPool},
        Shm, ShmHandler,
    },
};
use wayland_client::{
    globals::registry_queue_init,
    protocol::{wl_keyboard, wl_output, wl_pointer, wl_seat, wl_shm, wl_surface},
    Connection, QueueHandle,
};

pub fn create_blank_window(init_mutex: Arc<Mutex<bool>>) {
    let lock = init_mutex.lock().unwrap();
    // All Wayland apps start by connecting the compositor (server).
    let conn = Connection::connect_to_env().unwrap();

    // Enumerate the list of globals to get the protocols the server implements.
    let (globals, event_queue) = registry_queue_init(&conn).unwrap();
    let qh = event_queue.handle();
    let mut event_loop: EventLoop<SimpleWindow> =
        EventLoop::try_new().expect("Failed to initialize the event loop!");
    let loop_handle = event_loop.handle();
    WaylandSource::new(conn.clone(), event_queue)
        .insert(loop_handle)
        .unwrap();

    // The compositor (not to be confused with the server which is commonly called the compositor) allows
    // configuring surfaces to be presented.
    let compositor = CompositorState::bind(&globals, &qh).expect("wl_compositor not available");
    // For desktop platforms, the XDG shell is the standard protocol for creating desktop windows.
    let xdg_shell = XdgShell::bind(&globals, &qh).expect("xdg shell is not available");
    // Since we are not using the GPU in this example, we use wl_shm to allow software rendering to a buffer
    // we share with the compositor process.
    let shm = Shm::bind(&globals, &qh).expect("wl shm is not available.");
    // If the compositor supports xdg-activation it probably wants us to use it to get focus
    let xdg_activation = ActivationState::bind(&globals, &qh).ok();

    // A window is created from a surface.
    let surface = compositor.create_surface(&qh);
    // And then we can create the window.
    let window = xdg_shell.create_window(surface, WindowDecorations::RequestServer, &qh);
    // Configure the window, this may include hints to the compositor about the desired minimum size of the
    // window, app id for WM identification, the window title, etc.
    window.set_title("sway workspace named window");
    window.set_app_id("dev.theokrueger.sway-named-workspace");
    window.set_min_size(Some((1, 1)));

    // In order for the window to be mapped, we need to perform an initial commit with no attached buffer.
    // For more info, see WaylandSurface::commit
    //
    // The compositor will respond with an initial configure that we can then use to present to the window with
    // the correct options.
    window.commit();

    // To request focus, we first need to request a token
    if let Some(activation) = xdg_activation.as_ref() {
        activation.request_token(
            &qh,
            RequestData {
                seat_and_serial: None,
                surface: Some(window.wl_surface().clone()),
                app_id: Some(String::from("placeholder_window_for_pinning_workspaces")),
            },
        )
    }

    // We don't know how large the window will be yet, so lets assume the minimum size we suggested for the
    // initial memory allocation.
    let pool = SlotPool::new(256 * 256 * 4, &shm).expect("Failed to create pool");

    let mut simple_window = SimpleWindow {
        // Seats and outputs may be hotplugged at runtime, therefore we need to setup a registry state to
        // listen for seats and outputs.
        registry_state: RegistryState::new(&globals),
        seat_state: SeatState::new(&globals, &qh),
        output_state: OutputState::new(&globals, &qh),
        shm,
        pool,
        buffer: None,
        window,
    };

    // We don't draw immediately, the configure will notify us when to first draw.
    drop(lock);
    loop {
        event_loop
            .dispatch(Duration::from_millis(10000), &mut simple_window)
            .unwrap();
    }
}

struct SimpleWindow {
    registry_state: RegistryState,
    seat_state: SeatState,
    output_state: OutputState,
    shm: Shm,
    pool: SlotPool,
    buffer: Option<Buffer>,
    window: Window,
}

impl CompositorHandler for SimpleWindow {
    fn scale_factor_changed(
        &mut self,
        _conn: &Connection,
        _qh: &QueueHandle<Self>,
        _surface: &wl_surface::WlSurface,
        _new_factor: i32,
    ) {
        // do nothing!! :D
    }

    fn transform_changed(
        &mut self,
        _conn: &Connection,
        _qh: &QueueHandle<Self>,
        _surface: &wl_surface::WlSurface,
        _new_transform: wl_output::Transform,
    ) {
        // do nothing!! :D
    }

    fn frame(
        &mut self,
        conn: &Connection,
        qh: &QueueHandle<Self>,
        _surface: &wl_surface::WlSurface,
        _time: u32,
    ) {
        self.draw(conn, qh);
    }

    fn surface_enter(
        &mut self,
        _conn: &Connection,
        _qh: &QueueHandle<Self>,
        _surface: &wl_surface::WlSurface,
        _output: &wl_output::WlOutput,
    ) {
        // do nothing!! :D
    }

    fn surface_leave(
        &mut self,
        _conn: &Connection,
        _qh: &QueueHandle<Self>,
        _surface: &wl_surface::WlSurface,
        _output: &wl_output::WlOutput,
    ) {
        // do nothing!! :D
    }
}

impl OutputHandler for SimpleWindow {
    fn output_state(&mut self) -> &mut OutputState {
        &mut self.output_state
    }

    fn new_output(
        &mut self,
        _conn: &Connection,
        _qh: &QueueHandle<Self>,
        _output: wl_output::WlOutput,
    ) {
        // do nothing!! :D
    }

    fn update_output(
        &mut self,
        _conn: &Connection,
        _qh: &QueueHandle<Self>,
        _output: wl_output::WlOutput,
    ) {
        // do nothing!! :D
    }

    fn output_destroyed(
        &mut self,
        _conn: &Connection,
        _qh: &QueueHandle<Self>,
        _output: wl_output::WlOutput,
    ) {
        // do nothing!! :D
    }
}

impl WindowHandler for SimpleWindow {
    fn request_close(&mut self, _: &Connection, _: &QueueHandle<Self>, _: &Window) {
        // do nothing!! :D
    }

    fn configure(
        &mut self,
        conn: &Connection,
        qh: &QueueHandle<Self>,
        _window: &Window,
        _configure: WindowConfigure,
        _serial: u32,
    ) {
        self.draw(conn, qh);
    }
}

impl ActivationHandler for SimpleWindow {
    type RequestData = RequestData;

    fn new_token(&mut self, _token: String, _data: &Self::RequestData) {
        // do nothing!! :D
    }
}

impl SeatHandler for SimpleWindow {
    fn seat_state(&mut self) -> &mut SeatState {
        &mut self.seat_state
    }

    fn new_seat(&mut self, _: &Connection, _: &QueueHandle<Self>, _: wl_seat::WlSeat) {
        // do nothing!! :D
    }

    fn new_capability(
        &mut self,
        _conn: &Connection,
        _qh: &QueueHandle<Self>,
        _seat: wl_seat::WlSeat,
        _capability: Capability,
    ) {
        // do nothing!! :D
    }

    fn remove_capability(
        &mut self,
        _conn: &Connection,
        _: &QueueHandle<Self>,
        _: wl_seat::WlSeat,
        _capability: Capability,
    ) {
        // do nothing!! :D
    }

    fn remove_seat(&mut self, _: &Connection, _: &QueueHandle<Self>, _: wl_seat::WlSeat) {
        // do nothing!! :D
    }
}

impl KeyboardHandler for SimpleWindow {
    fn enter(
        &mut self,
        _: &Connection,
        _: &QueueHandle<Self>,
        _: &wl_keyboard::WlKeyboard,
        _surface: &wl_surface::WlSurface,
        _: u32,
        _: &[u32],
        _keysyms: &[Keysym],
    ) {
        // do nothing! :D
    }

    fn leave(
        &mut self,
        _: &Connection,
        _: &QueueHandle<Self>,
        _: &wl_keyboard::WlKeyboard,
        _surface: &wl_surface::WlSurface,
        _: u32,
    ) {
        // do nothing! :D
    }

    fn press_key(
        &mut self,
        _conn: &Connection,
        _qh: &QueueHandle<Self>,
        _: &wl_keyboard::WlKeyboard,
        _: u32,
        _event: KeyEvent,
    ) {
        // do nothing!! :D
    }

    fn release_key(
        &mut self,
        _: &Connection,
        _: &QueueHandle<Self>,
        _: &wl_keyboard::WlKeyboard,
        _: u32,
        _event: KeyEvent,
    ) {
        // do nothing!! :D
    }

    fn update_modifiers(
        &mut self,
        _: &Connection,
        _: &QueueHandle<Self>,
        _: &wl_keyboard::WlKeyboard,
        _serial: u32,
        _modifiers: Modifiers,
        _layout: u32,
    ) {
        // do nothing!! :D
    }
}

impl PointerHandler for SimpleWindow {
    fn pointer_frame(
        &mut self,
        _conn: &Connection,
        _qh: &QueueHandle<Self>,
        _pointer: &wl_pointer::WlPointer,
        _events: &[PointerEvent],
    ) {
        // do nothing!!! :D
    }
}

impl ShmHandler for SimpleWindow {
    fn shm_state(&mut self) -> &mut Shm {
        &mut self.shm
    }
}

impl SimpleWindow {
    pub fn draw(&mut self, _conn: &Connection, _qh: &QueueHandle<Self>) {
        let buffer = self.buffer.get_or_insert_with(|| {
            self.pool
                .create_buffer(1, 1, 4, wl_shm::Format::Argb8888)
                .expect("create buffer")
                .0
        });
        buffer
            .attach_to(self.window.wl_surface())
            .expect("buffer attach");
        self.window.commit();
    }
}

delegate_compositor!(SimpleWindow);
delegate_output!(SimpleWindow);
delegate_shm!(SimpleWindow);

delegate_seat!(SimpleWindow);
delegate_keyboard!(SimpleWindow);
delegate_pointer!(SimpleWindow);

delegate_xdg_shell!(SimpleWindow);
delegate_xdg_window!(SimpleWindow);
delegate_activation!(SimpleWindow);

delegate_registry!(SimpleWindow);

impl ProvidesRegistryState for SimpleWindow {
    fn registry(&mut self) -> &mut RegistryState {
        &mut self.registry_state
    }
    registry_handlers![OutputState, SeatState,];
}
