/* See LICENSE file for copyright and license details. */

#include <X11/XF86keysym.h>

/* appearance */
static const unsigned int borderpx = 0; /* border pixel of windows */
static const unsigned int default_border =
    0; /* to switch back to default border after dynamic border resizing via
          keybinds */
static const unsigned int snap = 32;   /* snap pixel */
static const unsigned int gappih = 10; /* horiz inner gap between windows */
static const unsigned int gappiv = 10; /* vert inner gap between windows */
static const unsigned int gappoh =
    10; /* horiz outer gap between windows and screen edge */
static const unsigned int gappov =
    10; /* vert outer gap between windows and screen edge */
static const int smartgaps =
    0; /* 1 means no outer gap when there is only one window */
static const unsigned int systraypinning =
    0; /* 0: sloppy systray follows selected monitor, >0: pin systray to monitor
          X */
static const unsigned int systrayspacing = 2; /* systray spacing */
static const int systraypinningfailfirst =
    1; /* 1: if pinning fails,display systray on the 1st monitor,False: display
          systray on last monitor*/
static const int showsystray = 1; /* 0 means no systray */
static const int showbar = 1;     /* 0 means no bar */
static const int showtab = showtab_auto;
static const int toptab = 1;       /* 0 means bottom tab */
static const int floatbar = 1;     /* 1 means the bar will float(don't have
                                      padding),0 means the bar have padding */
static const int topbar = 1;       /* 0 means bottom bar */
static const int horizpadbar = 10; // Increased from 5
static const int vertpadbar = 18;  // Increased from 11
#define ICONSIZE 24                // Increased from 19
#define ICONSPACING 12             // Increased from 8
static const int vertpadtab = 35;
static const int horizpadtabi = 15;
static const int horizpadtabo = 15;
static const int scalepreview = 4;
static const int tag_preview = 0; /* 1 means enable, 0 is off */
static const int colorfultag =
    1; /* 0 means use SchemeSel for selected non vacant tag */
static const char *upvol[] = {"/usr/bin/pactl", "set-sink-volume",
                              "@DEFAULT_SINK@", "+5%", NULL};
static const char *downvol[] = {"/usr/bin/pactl", "set-sink-volume",
                                "@DEFAULT_SINK@", "-5%", NULL};
static const char *mutevol[] = {"/usr/bin/pactl", "set-sink-mute",
                                "@DEFAULT_SINK@", "toggle", NULL};
static const char *light_up[] = {"/usr/bin/light", "-A", "5", NULL};
static const char *light_down[] = {"/usr/bin/light", "-U", "5", NULL};
static const int new_window_attach_on_end =
    0; /*  1 means the new window will attach on the end; 0 means the new window
          will attach on the front,default is front */
#define ICONSIZE 19   /* icon size */
#define ICONSPACING 8 /* space between icon and title */

static const char *fonts[] = {
    "IBM Plex Mono:size=14:antialias=true:autohint=true", // Increased to 14
    "Symbols Nerd Font:size=14:antialias=true:autohint=true",
    "Iosevka:style:medium:size=14",
    "JetBrainsMono Nerd Font Mono:style:medium:size=22" // Increased for large
                                                        // titles
};

// theme
#include "themes/onedark.h"

static const char *colors[][3] = {
    /*                     fg       bg      border */
    [SchemeNorm] = {gray3, black, gray2},
    [SchemeSel] = {gray4, blue, blue},
    [SchemeTitle] = {white, black, black}, // active window title
    [TabSel] = {blue, gray2, black},
    [TabNorm] = {gray3, black, black},
    [SchemeTag] = {gray3, black, black},
    [SchemeTag1] = {blue, black, black},
    [SchemeTag2] = {red, black, black},
    [SchemeTag3] = {orange, black, black},
    [SchemeTag4] = {green, black, black},
    [SchemeTag5] = {pink, black, black},
    [SchemeLayout] = {green, black, black},
    [SchemeBtnPrev] = {green, black, black},
    [SchemeBtnNext] = {yellow, black, black},
    [SchemeBtnClose] = {red, black, black},
};

/* tagging */
static char *tags[] = {"💻", "🏢", "🏠", "🔲", "🔑", "6", "7", "8", "9"};

/* launcher commands */
static const char *eww[] = {"eww", "open", "eww", NULL};
static const char *nm_editor[] = {"nm-connection-editor", NULL};
static const char *thunarcmd[] = {"thunar", NULL};
static const char *mullvadtoggle[] = {
    "/bin/sh", "-c", "$HOME/.local/bin/mullvad-toggle.sh", NULL};
static const char *tailscaletoggle[] = {
    "/bin/sh", "-c", "$HOME/.local/bin/tailscale-toggle.sh", NULL};

static const Launcher launchers[] = {
    /* command     name to display */
    {eww, ""},
    {nm_editor, ""},
    {thunarcmd, ""},
    {mullvadtoggle, ""},
    {tailscaletoggle, ""}};

static const int tagschemes[] = {SchemeTag1, SchemeTag2, SchemeTag3, SchemeTag4,
                                 SchemeTag5};

static const unsigned int ulinepad =
    5; /* horizontal padding between the underline and tag */
static const unsigned int ulinestroke =
    2; /* thickness / height of the underline */
static const unsigned int ulinevoffset =
    0; /* how far above the bottom of the bar the line should appear */
static const int ulineall =
    0; /* 1 to show underline on all tags, 0 for just the active ones */

static const Rule rules[] = {
    /* xprop(1):
     *	WM_CLASS(STRING) = instance, class
     *	WM_NAME(STRING) = title
     */
    /* class      instance    title       tags mask     iscentered   isfloating
       monitor */
    {"Thunar", NULL, NULL, 0, 0, 1, -1},
    {"nm-connection-editor", NULL, NULL, 0, 0, 1, -1},
    {"eww", NULL, NULL, 0, 0, 1, -1},
};

/* layout(s) */
static const float mfact = 0.4; /* factor of master area size [0.05..0.95] */
static const int nmaster = 1;   /* number of clients in master area */
static const int resizehints =
    0; /* 1 means respect size hints in tiled resizals */
static const int lockfullscreen =
    1; /* 1 will force focus on the fullscreen window */

#define FORCE_VSPLIT                                                           \
  1 /* nrowgrid layout: force two clients to always split vertically */
#include "functions.h"

static const Layout layouts[] = {
    /* symbol arrange function */
    /* first entry is default */
    {"|M|", centeredmaster},
    {"[\\]", dwindle},
    {"###", nrowgrid},
    {"[]=", tile},
    {"HHH", grid},
    {":::", gaplessgrid},
    {"===", bstackhoriz},
    {"[M]", monocle},
    {"[@]", spiral},
    {"H[]", deck},
    {"TTT", bstack},
    {"---", horizgrid},
    {">M>", centeredfloatingmaster},
    {"><>", NULL},
    /* no layout function means floating behavior */ {NULL, NULL},
};

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY, TAG)                                                      \
  {MODKEY, KEY, view, {.ui = 1 << TAG}},                                       \
      {MODKEY | ControlMask, KEY, toggleview, {.ui = 1 << TAG}},               \
      {MODKEY | ShiftMask, KEY, tag, {.ui = 1 << TAG}},                        \
      {MODKEY | ControlMask | ShiftMask, KEY, toggletag, {.ui = 1 << TAG}},

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd)                                                             \
  {                                                                            \
    .v = (const char *[]) { "/bin/sh", "-c", cmd, NULL }                       \
  }

/* helpers */
static const char *termcmd[] = {"kitty", NULL};
static const char *browsercmd[] = {"xdg-open", "https://",
                                   NULL}; /* or "firefox" */
static const char *appmenu[] = {"rofi", "-show", "drun", NULL}; /* Win+Space */
static const char *cmdmenu[] = {"rofi", "-show", "run",
                                NULL};         /* Win+Shift+Space */
static const char *files[] = {"thunar", NULL}; /* or "nautilus" */
static const char *filesrch[] = {"rofi", "-show", "window", NULL}; /* approx */
static const char *notif[] = {"dunstctl", "history-pop",
                              NULL}; /* needs dunst */
static const char *settings[] = {"gnome-control-center",
                                 NULL};          /* pick your settings app */
static const char *display[] = {"arandr", NULL}; /* display settings */
static const char *poweroffcmd[] = {"systemctl", "poweroff", NULL};
static const char *rebootcmd[] = {"systemctl", "reboot", NULL};
static const char *lockcmd[] = {"/bin/sh", "-c",
                                "$HOME/.config/chadwm/scripts/lock.sh", NULL};

/* commands */

static const Key keys[] = {
    /* Regolith: Launch */
    {MODKEY, XK_space, spawn, {.v = appmenu}}, /* Win Space: app menu */
    {MODKEY | ShiftMask,
     XK_space,
     spawn,
     {.v = cmdmenu}},                           /* Win Shift Space: command */
    {MODKEY, XK_Return, spawn, {.v = termcmd}}, /* Win Enter: terminal */
    {MODKEY | ShiftMask,
     XK_Return,
     spawn,
     {.v = browsercmd}}, /* Win Shift Enter: browser */
    {MODKEY | ShiftMask, XK_n, spawn, {.v = notif}}, /* Win Shift n: files */
    {MODKEY | Mod1Mask,
     XK_space,
     spawn,
     {.v = filesrch}},                   /* Win Alt Space: file search approx */
    {MODKEY, XK_n, spawn, {.v = files}}, /* Win n: notifications */
    /* Launch “this dialog” (help) not applicable in dwm → skip or bind to man
       page/cheatsheet */

    /* Regolith: Modify */
    {MODKEY,
     XK_b,
     spawn,
     {.v = display}}, /* Win b: bluetooth settings (approx: display) */
    {MODKEY, XK_d, spawn, {.v = display}}, /* Win d: display settings */
    {MODKEY,
     XK_comma,
     spawn,
     {.v = settings}}, /* Win ,: settings (save layout ≠ dwm) */
    {MODKEY | ShiftMask,
     XK_t,
     togglefloating,
     {0}},                          /* Win Shift t: tile/float focus toggle */
    {MODKEY, XK_i, togglebar, {0}}, /* Win i: toggle bar */
    {MODKEY | ShiftMask,
     XK_f,
     togglefloating,
     {0}},                              /* Win Shift f: float toggle */
    {MODKEY, XK_f, togglefullscr, {0}}, /* Win f: fullscreen toggle */
    {MODKEY,
     XK_t,
     setlayout,
     {.v = &layouts[0]}}, /* Win t: layout mode (tiling) */
    {MODKEY,
     XK_BackSpace,
     setlayout,
     {0}}, /* Win Backspace: next layout approx */

    /* Move/resize focus (dwm = stack focus; no directional focus without
       patches) */
    {MODKEY, XK_j, focusstack, {.i = +1}}, /* Win j: next window */
    {MODKEY, XK_k, focusstack, {.i = -1}}, /* Win k: prev window */
    {MODKEY | ShiftMask,
     XK_h,
     movestack,
     {.i = -1}}, /* Win Shift h: move window left in stack */
    {MODKEY | ShiftMask,
     XK_l,
     movestack,
     {.i = +1}}, /* Win Shift l: move window right in stack */
    {MODKEY, XK_h, setmfact, {.f = -0.05}}, /* Win h: shrink */
    {MODKEY, XK_l, setmfact, {.f = +0.05}}, /* Win l: grow */

    /* Workspaces (tags) */
    {MODKEY, XK_Tab, view, {0}}, /* Win Tab: next workspace approx */
    {MODKEY,
     XK_Left,
     shiftview,
     {.i = -1}}, /* Win Alt ←/→ approx with plain arrows */
    {MODKEY, XK_Right, shiftview, {.i = +1}},
    TAGKEYS(XK_1, 0) TAGKEYS(XK_2, 1) TAGKEYS(XK_3, 2) TAGKEYS(XK_4, 3)
        TAGKEYS(XK_5, 4) TAGKEYS(XK_6, 5) TAGKEYS(XK_7, 6) TAGKEYS(XK_8, 7)
            TAGKEYS(XK_9, 8)
    /* Regolith has workspaces 1–19; dwm ships 1–9 only. “Carry to workspace” ≈
       tag + stay: */
    {MODKEY | ShiftMask,
     XK_1,
     tag,
     {.ui = 1 << 0}}, /* Win Shift 1..9: move window */

    /* Session */
    {MODKEY | ShiftMask,
     XK_q,
     killclient,
     {0}}, /* Win Shift q: terminate app */
    // {MODKEY | Mod1Mask, XK_q, killclient, {0}}, /* Win Alt q: same behavior
    // */
    {MODKEY, XK_Escape, spawn, {.v = lockcmd}}, /* Win Esc: lock */
    {MODKEY | ShiftMask, XK_e, spawn,
     SHCMD("killall chadwm")}, /* Win Shift e: logout */
    {MODKEY | ShiftMask,
     XK_p,
     spawn,
     {.v = poweroffcmd}}, /* Win Shift p: power down */
    {MODKEY | ShiftMask,
     XK_b,
     spawn,
     {.v = rebootcmd}},                       /* Win Shift b: reboot */
    {MODKEY | ShiftMask, XK_r, restart, {0}}, /* Win Shift r: refresh session */
    {MODKEY | ControlMask, XK_r, restart, {0}}, /* Win Ctrl r: restart WM */

    {0, XF86XK_AudioLowerVolume, spawn, {.v = downvol}},
    {0, XF86XK_AudioMute, spawn, {.v = mutevol}},
    {0, XF86XK_AudioRaiseVolume, spawn, {.v = upvol}},
    {0, XF86XK_MonBrightnessUp, spawn, {.v = light_up}},
    {0, XF86XK_MonBrightnessDown, spawn, {.v = light_down}},
    /* screenshots */
    {MODKEY | ControlMask, XK_u, spawn,
     SHCMD("maim | xclip -selection clipboard -t image/png")},
    {MODKEY, XK_u, spawn,
     SHCMD("maim --select | xclip -selection clipboard -t image/png")},
    /* logout */
    {ControlMask | Mod1Mask, XK_Delete, spawn,
     SHCMD("killall chadwm zed zed-editor;loginctl terminate-session "
           "$XDG_SESSION_ID")},
    /*screenshots    */
    {MODKEY | ShiftMask, XK_s, spawn,
     SHCMD("maim --select ~/Pictures/screenshot-$(date +%F_%T).png")},
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle,
 * ClkClientWin, or ClkRootWin */
static const Button buttons[] = {
    /* click                event mask      button          function
       argument */
    {ClkLtSymbol, 0, Button1, setlayout, {0}},
    {ClkLtSymbol, 0, Button3, setlayout, {.v = &layouts[2]}},
    {ClkWinTitle, 0, Button2, zoom, {0}},
    {ClkStatusText, 0, Button2, spawn, SHCMD("kitty")},

    /* Keep movemouse? */
    /* { ClkClientWin,         MODKEY,         Button1,        movemouse,
     * {0} },
     */

    /* placemouse options, choose which feels more natural:
     *    0 - tiled position is relative to mouse cursor
     *    1 - tiled position is relative to window center
     *    2 - mouse pointer warps to window center
     *
     * The moveorplace uses movemouse or placemouse depending on the
     * floating state of the selected client. Set up individual keybindings
     * for the two if you want to control these separately (i.e. to retain
     * the feature to move a tiled window into a floating position).
     */
    {ClkClientWin, MODKEY, Button1, moveorplace, {.i = 0}},
    {ClkClientWin, MODKEY, Button2, togglefloating, {0}},
    {ClkClientWin, MODKEY, Button3, dragmfact, {0}},
    // {ClkClientWin, ControlMask, Button1, dragmfact, {0}},
    // {ClkClientWin, ControlMask, Button3, dragcfact, {0}},
    {ClkTagBar, 0, Button1, view, {0}},
    {ClkTagBar, 0, Button3, toggleview, {0}},
    {ClkTagBar, MODKEY, Button1, tag, {0}},
    {ClkTagBar, MODKEY, Button3, toggletag, {0}},
    {ClkTabBar, 0, Button1, focuswin, {0}},
    {ClkTabPrev, 0, Button1, movestack, {.i = -1}},
    {ClkTabNext, 0, Button1, movestack, {.i = +1}},
    {ClkTabClose, 0, Button1, killclient, {0}},
};
