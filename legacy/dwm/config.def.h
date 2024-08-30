#include <X11/XF86keysym.h>

/* See LICENSE file for copyright and license details. */

/* appearance */
static const unsigned int borderpx = 1;                              // border pixel of windows
static const unsigned int snap = 8;                                  // snap pixel
static const unsigned int systraypinning = 1;                        // 0: sloppy systray follows selected monitor, >0: pin systray to monitor X
static const unsigned int systrayonleft = 0;                         // 0: systray in the right corner, >0: systray on left of status text
static const unsigned int systrayspacing = 2;                        // systray spacing
static const int systraypinningfailfirst = 1;                        // 1: if pinning fails, display systray on the first monitor, False: display systray on the last monitor
static const int showsystray = 1;                                    // 0 means no systray
static const int showbar = 1;                                        // 0 means no bar
static const int topbar = 1;                                         // 0 means bottom bar
static const char *fonts[] = {"monospace:size=10"};   // used in dwm bar
static const char dmenufont[] = "monospace:size=10";  // used in dmenu
static const char col_gray1[] = "#222222";
static const char col_gray2[] = "#444444";
static const char col_gray3[] = "#bbbbbb";
static const char col_gray4[] = "#eeeeee";
static const char col_white[] = "#FFFFFF";
static const char col_black[] = "#000000";
static const char col_pink[] = "#ff66cc";
// og steam colours
static const char col_lgreenbg[] = "#5a6a60";
static const char col_greenbg[] = "#4c5844";
static const char col_dgreenbg[] = "#3e4637";
static const char col_offwhite[] = "#d8ded3";
static const char col_lborder[] = "#808080";
static const char col_dborder[] = "#282e22";

static const char *colors[][3] = {
        /* scheme      fg          bg         border  */
        [SchemeNorm] = {col_offwhite, col_greenbg, col_dborder},
        [SchemeSel]  = {col_offwhite, col_lgreenbg,  col_lborder},
};

/* tagging */
static const char *tags[] = {"1", "2", "3", "4", "5", "6", "7"};

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */

        /* class         instance  title    tagmask  isfloating  monitor */
        {"nheko",        NULL,     NULL,    1 << 5,  0,          1},
        {"Element",      NULL,     NULL,    1 << 5,  0,          1},
        {"qBittorrent",  NULL,     NULL,    1 << 6,  0,          1},
	{NULL,           NULL,     "Steam", 1 << 6,  0,          1},
	{"thunderbird",  NULL,     NULL,    1 << 6,  0,          1},
};

/* layout(s) */
static const float mfact = 0.55;  // factor of master area size [0.05..0.95]
static const int nmaster = 1;	  // number of clients in master area
#ifdef IS_LAPTOP
static const int resizehints = 0;
#else
static const int resizehints = 1; // 1 means respect size hints in tiled resizals
#endif
static const int ratiofullscreenborders = 1;

static const Layout layouts[] = {
	/* symbol  arrange function */
        {"tl",     tile},    // first entry is default
	{"fl",     NULL},    // no layout function means floating behavior
	{"fs",     monocle}, // monocole = fullscreen borderless
};

/* key definitions */
#define MODKEY Mod4Mask // OS key
#define TAGKEYS(KEY, TAG)                                                      \
        {MODKEY, KEY, view, {.ui = 1 << TAG}},                                 \
        {MODKEY | ControlMask, KEY, toggleview, {.ui = 1 << TAG}},             \
        {MODKEY | ShiftMask, KEY, tag, {.ui = 1 << TAG}},                      \
        {MODKEY | ControlMask | ShiftMask, KEY, toggletag, {.ui = 1 << TAG}},

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd)                                                    \
        {                                                             \
                .v = (const char *[]) { "/bin/sh", "-c", cmd, NULL }  \
        }

/* commands */
// applications
static const char *app_terminal[]     = {"st",                                                       NULL};
static const char *app_webbrowser[]   = {"firefox",                                                  NULL};
static const char *app_webbrowser2[]  = {"chromium",                                                 NULL};
static const char *app_messenger[]    = {"flatpak", "run", "im.riot.Riot",                           NULL};
static const char *app_filemanager[]  = {"thunar",                                                  NULL};
static const char *app_editor[]       = {"emacsclient", "--create-frame",                            NULL};
static const char *app_gamelauncher[] = {"steam", "-no-browser", "+open steam://open/minigameslist", "+console", NULL};
static const char *app_mediaplayer[]  = {"st", "-e", "/home/me/.config/ncmpcpp/ncmpcpp.sh",          NULL};
// media control
static const char *media_next[]          = {"mpc", "next",         NULL};
static const char *media_previous[]      = {"mpc", "prev",         NULL};
static const char *media_playpause[]     = {"mpc", "toggle",       NULL};
static const char *media_volume_up[]     = {"mpc", "volume", "+5", NULL};
static const char *media_volume_down[]   = {"mpc", "volume", "-5", NULL};
// screensaver
static const char *ss_lock[]     = {"slock", NULL};
static const char *ss_activate[] = {"xautolock", "-locknow", NULL};
static const char *ss_sleep[]   = {"loginctl", "suspend", NULL};
// resolution
static const char *res_1024[] = {"res", "1024", NULL};
static const char *res_1920[] = {"res", "1920", NULL};
// screenshotting
static const char *screenshot_full[] = {"flameshot", "full", NULL};
static const char *screenshot_crop[] = {"flameshot", "gui", NULL};
// LAPTOP ONLY
#ifdef IS_LAPTOP
// brightness
static const char *brightness_up[]   = {"brightnessctl", "s", "5%+", NULL};
static const char *brightness_down[] = {"brightnessctl", "s", "5%-", NULL};
#endif

// dmenu commands
static char dmenumon[2] = "0";

static const char *dmenucmd[] = {"dmenu_run", "-i", "-m", dmenumon, "-fn", dmenufont, "-nb", col_greenbg, "-nf", col_offwhite, "-sb", col_lgreenbg, "-sf", col_offwhite, NULL};                       // launch dmenu
static const char *app_dmenu_nm[] = {"networkmanager_dmenu", "-l", "10", "-m", dmenumon, "-fn", dmenufont, "-nb", col_greenbg, "-nf", col_offwhite, "-sb", col_lgreenbg, "-sf", col_offwhite, NULL};  // launch dmenunm

static Key keys[] = {
        /* applications */
        {MODKEY,               XK_p,      spawn, {.v = dmenucmd}},                // open dmenu
        {MODKEY,               XK_Return, spawn, {.v = app_terminal}},            // spawn terminal
        {MODKEY | ShiftMask,   XK_f,      spawn, {.v = app_webbrowser}},          // spawn web browser
        {MODKEY | ControlMask, XK_f,      spawn, {.v = app_webbrowser2}},         // spawn other web browser
        {MODKEY | ShiftMask,   XK_g,      spawn, {.v = app_filemanager}},         // spawn file manager
        {MODKEY | ShiftMask,   XK_e,      spawn, {.v = app_editor}},              // spawn text editor
        {MODKEY | ShiftMask,   XK_d,      spawn, {.v = app_messenger}},           // spawn messenger
        {MODKEY | ShiftMask,   XK_o,      spawn, {.v = app_dmenu_nm}},            // spawn networkmanager dmenu
        {MODKEY | ShiftMask,   XK_r,      spawn, {.v = app_gamelauncher}},        // spawn game launcher
        {0, XF86XK_AudioMute,             spawn, {.v = app_mediaplayer}},         // spawn media player
        /* media control */
        {0, XF86XK_AudioNext, spawn, {.v = media_next}},                          // media next track (bound to defined media player)
        {0, XK_KP_Right, spawn, {.v = media_next}},                               // ^ see above ^
        {0, XF86XK_AudioPrev, spawn, {.v = media_previous}},                      // media previous track (bound to defined media player)
        {0, XK_KP_Left, spawn, {.v = media_previous}},                            // ^ see above ^
        {0, XF86XK_AudioPlay, spawn, {.v = media_playpause}},                     // media pause/play (bound to defined media player)
        {0, XK_KP_Begin, spawn, {.v = media_playpause}},                          // ^ see above ^
        {0, XF86XK_AudioRaiseVolume, spawn, {.v = media_volume_up}},              // media vol up (bound to defined media player)
        {0, XK_KP_Up, spawn, {.v = media_volume_up}},                             // ^ see above ^
        {0, XF86XK_AudioLowerVolume, spawn, {.v = media_volume_down}},            // media vol down (bound to defined media player)
        {0, XK_KP_Down, spawn, {.v = media_volume_down}},                         // ^ see above ^
        /* screensaver */
        {MODKEY,               XK_Delete, spawn, {.v = ss_lock}},                 // activate only x11 lock
        {MODKEY | ShiftMask,   XK_Delete, spawn, {.v = ss_activate}},             // activate screensaver
        {MODKEY | ControlMask, XK_Delete, spawn, {.v = ss_sleep}},                // sleep computer
        /* screenshot hotkeys */
        {MODKEY | ControlMask, XK_s, spawn, {.v = screenshot_full}},              // full screenshot
        {MODKEY | ShiftMask,   XK_s, spawn, {.v = screenshot_crop}},              // selection screenshot
        /* resolution */
        {MODKEY | ControlMask, XK_z, spawn, {.v = res_1920}},                     // set res to 1920x1080@144
        {MODKEY | ControlMask, XK_x, spawn, {.v = res_1024}},                     // set res to 1024x768@144
        /* layout */
        {MODKEY | ShiftMask, XK_m, togglefullscr, {0}},                           // toggle fullscreen on a window
        {MODKEY | ControlMask, XK_m, toggleratiofullscr, {0}},                    // toggle ratio fs on window
        {MODKEY, XK_b, togglebar, {0}},                                           // toggle showing top bar
        {MODKEY, XK_j, focusstack, {.i = +1}},                                    // focus next window
        {MODKEY, XK_k, focusstack, {.i = -1}},                                    // focus previous window
        {MODKEY, XK_i, incnmaster, {.i = +1}},                                    // increase master stack size
        {MODKEY, XK_d, incnmaster, {.i = -1}},                                    // decrease master stack size
        {MODKEY, XK_l, setmfact, {.f = +0.05}},                                   // increase master stack width
        {MODKEY, XK_h, setmfact, {.f = -0.05}},                                   // decrease master stack width
        {MODKEY | ShiftMask, XK_Return, zoom, {0}},                               // swap focused window with top of master stack
        {MODKEY, XK_t, setlayout, {.v = &layouts[0]}},                            // set layout to tiling
        {MODKEY, XK_f, setlayout, {.v = &layouts[1]}},                            // set layout to floating
        {MODKEY, XK_m, setlayout, {.v = &layouts[2]}},                            // set layout to borderless windowed
        {MODKEY | ShiftMask, XK_space, togglefloating, {0}},                      // toggle floating on active window
        /* windows */
        {MODKEY, XK_q, killclient, {0}},                                          // kill active window
        /* tagging */
        {MODKEY, XK_8, view, {.ui = ~0}},                                         // view all tags at once
        {MODKEY | ShiftMask, XK_8, tag, {.ui = ~0}},                              // send current window to all tags
        {MODKEY, XK_Tab, view, {0}},                                              // swap to last used tag
        TAGKEYS(XK_1, 0)                                                          //   tagkeys
        TAGKEYS(XK_2, 1)                                                          //      |
        TAGKEYS(XK_3, 2)                                                          //      |
        TAGKEYS(XK_4, 3)                                                          //      |
        TAGKEYS(XK_5, 4)                                                          //      |
        TAGKEYS(XK_6, 5)                                                          //      V
        TAGKEYS(XK_7, 6)                                                          // for tags 1-6
        /* monitor */
        {MODKEY, XK_comma, focusmon, {.i = -1}},                                  // change focused monitor to previous monitor
        {MODKEY, XK_period, focusmon, {.i = +1}},                                 // change focused monitor to next monitor
        {MODKEY | ShiftMask, XK_comma, tagmon, {.i = -1}},                        // send current window to previous monitor
        {MODKEY | ShiftMask, XK_period, tagmon, {.i = +1}},                       // send current window to next monitor
        /* meta */
        {MODKEY | ShiftMask, XK_c, quit, {0}},                                    // quit dwm
        /* LAPTOP ONLY */
#ifdef IS_LAPTOP
        /* brightness */
        {MODKEY | ShiftMask, XK_Up, spawn, {.v = brightness_up}},                 // brightness up (laptop)
        {MODKEY | ShiftMask, XK_Down, spawn, {.v = brightness_down}},             // brightness down (laptop)
        {0, XF86XK_MonBrightnessUp, spawn, {.v = brightness_up}},                 // brightness up
        {0, XF86XK_MonBrightnessDown, spawn, {.v = brightness_down}},             // brightness down
#endif
};

/* button definitions, no touchy! */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static Button buttons[] = {
        /* click                event mask      button          function        argument */
        {ClkLtSymbol, 0, Button1, setlayout, {0}},
        {ClkLtSymbol, 0, Button3, setlayout, {.v = &layouts[2]}},
        {ClkWinTitle, 0, Button2, zoom, {0}},
        {ClkStatusText, 0, Button2, spawn, {.v = app_terminal}},
        {ClkClientWin, MODKEY, Button1, movemouse, {0}},
        {ClkClientWin, MODKEY, Button2, togglefloating, {0}},
        {ClkClientWin, MODKEY | ShiftMask, Button1, togglefloating, {0}},
        {ClkClientWin, MODKEY, Button3, resizemouse, {0}},
        {ClkTagBar, 0, Button1, view, {0}},
        {ClkTagBar, 0, Button3, toggleview, {0}},
        {ClkTagBar, MODKEY, Button1, tag, {0}},
        {ClkTagBar, MODKEY, Button3, toggletag, {0}},
};
