import ./private/backend

{.compile(
  "../upstream/sokol_app.h",
  "-x c -Dmain=sokol_entry -DSOKOL_IMPL -DSOKOL_WIN32_FORCE_MAIN -DSOKOL_" & sokol_backend
).}

proc sokol_entry(argc: cint, argv: cstringArray): cint {.importc, cdecl.}

const
  MAX_TOUCHPOINTS {.used.} = 8
  MAX_MOUSEBUTTONS {.used.} = 3
  MAX_KEYCODES {.used.} = 512
  MAX_ICONIMAGES {.used.} = 8

type
  AppDesc* = object
    init*: proc () {.cdecl.}
    frame*: proc () {.cdecl.}
    cleanup*: proc () {.cdecl.}
    event*: proc (event: var Event) {.cdecl.} # todo
    fail*: proc (message: cstring) {.cdecl.} # todo
    userData*: pointer
    userInit*: proc (user: pointer) {.cdecl.}
    userFrame*: proc (user: pointer) {.cdecl.}
    userCleanup*: proc (user: pointer) {.cdecl.}
    userEvent*: proc (event: var Event, user: pointer) {.cdecl.} # todo
    userFail*: proc (message: cstring, user: pointer) {.cdecl.} # todo

    width*, height*: cint
    sampleCount*: cint
    swapInterval*: cint
    highDpi*: bool
    fullscreen*: bool
    alpha*: bool
    windowTitle*: cstring
    userCursor*: bool
    enableClipboard*: bool
    clipboardSize*: cint
    enableDragndrop*: bool
    maxDroppedFiles*: cint
    maxDroppedFilesPathLength*: cint
    icon*: IconDesc

    glForceGles2*: bool
    win32ConsoleUtf8*: bool
    win32ConsoleCreate*: bool
    win32ConsoleAttach*: bool
    html5CanvasName*: cstring
    html5CanvasResize*: bool
    html5PreserveDrawingBuffer*: bool
    html5PremultipledAlpha*: bool
    html5AskLeaveSite*: bool
    iosKeyboardResizesCanvas*: bool
  IconDesc* = object
    default*: bool
    images*: array[MAX_ICONIMAGES, ImageDesc]
  ImageDesc* = object
    width*, height*: cint
    pixels*: RangePtr
  RangePtr* = object
    head*: pointer
    size*: csize_t
  Event* = object
    frameCount*: uint64
    kind*: EventKind
    keyCode*: KeyCode
    charCode*: uint32
    keyRepeat*: bool
    modifiers*: Modifiers
    mouseButton*: MouseButton
    mouseX*, mouseY*, mouseDx*, mouseDy*, scrollX*, scrollY*: float32
    numTouches*: cint
    touches*: array[MAX_TOUCHPOINTS, TouchPoint]
    windowWidth*, windowHeight*, framebufferWidth*, framebufferHeight*: cint
  EventKind* {.pure, size(4).} = enum
    ev_invalid
    ev_keydown
    ev_keyup
    ev_char
    ev_mouse_down
    ev_mouse_up
    ev_mouse_scroll
    ev_mouse_move
    ev_mouse_enter
    ev_mouse_leave
    ev_touches_begin
    ev_touches_moved
    ev_touches_ended
    ev_touches_cancelled
    ev_resized
    ev_iconified
    ev_restored
    ev_focused
    ev_unfocused
    ev_suspended
    ev_resumed
    ev_update_cursor
    ev_quit_requested
    ev_clipboard_pasted
    ev_files_dropped
  KeyCode* {.pure, size(4).} = enum
    key_invalid       = 0
    key_space         = 32
    key_apostrophe    = 39  
    key_comma         = 44  
    key_minus         = 45  
    key_period        = 46  
    key_slash         = 47  
    key_0             = 48
    key_1             = 49
    key_2             = 50
    key_3             = 51
    key_4             = 52
    key_5             = 53
    key_6             = 54
    key_7             = 55
    key_8             = 56
    key_9             = 57
    key_semicolon     = 59  
    key_equal         = 61  
    key_a             = 65
    key_b             = 66
    key_c             = 67
    key_d             = 68
    key_e             = 69
    key_f             = 70
    key_g             = 71
    key_h             = 72
    key_i             = 73
    key_j             = 74
    key_k             = 75
    key_l             = 76
    key_m             = 77
    key_n             = 78
    key_o             = 79
    key_p             = 80
    key_q             = 81
    key_r             = 82
    key_s             = 83
    key_t             = 84
    key_u             = 85
    key_v             = 86
    key_w             = 87
    key_x             = 88
    key_y             = 89
    key_z             = 90
    key_left_bracket  = 91  
    key_backslash     = 92  
    key_right_bracket = 93  
    key_grave_accent  = 96  
    key_world_1       = 161 
    key_world_2       = 162 
    key_escape        = 256
    key_enter         = 257
    key_tab           = 258
    key_backspace     = 259
    key_insert        = 260
    key_delete        = 261
    key_right         = 262
    key_left          = 263
    key_down          = 264
    key_up            = 265
    key_page_up       = 266
    key_page_down     = 267
    key_home          = 268
    key_end           = 269
    key_caps_lock     = 280
    key_scroll_lock   = 281
    key_num_lock      = 282
    key_print_screen  = 283
    key_pause         = 284
    key_f1            = 290
    key_f2            = 291
    key_f3            = 292
    key_f4            = 293
    key_f5            = 294
    key_f6            = 295
    key_f7            = 296
    key_f8            = 297
    key_f9            = 298
    key_f10           = 299
    key_f11           = 300
    key_f12           = 301
    key_f13           = 302
    key_f14           = 303
    key_f15           = 304
    key_f16           = 305
    key_f17           = 306
    key_f18           = 307
    key_f19           = 308
    key_f20           = 309
    key_f21           = 310
    key_f22           = 311
    key_f23           = 312
    key_f24           = 313
    key_f25           = 314
    key_kp_0          = 320
    key_kp_1          = 321
    key_kp_2          = 322
    key_kp_3          = 323
    key_kp_4          = 324
    key_kp_5          = 325
    key_kp_6          = 326
    key_kp_7          = 327
    key_kp_8          = 328
    key_kp_9          = 329
    key_kp_decimal    = 330
    key_kp_divide     = 331
    key_kp_multiply   = 332
    key_kp_subtract   = 333
    key_kp_add        = 334
    key_kp_enter      = 335
    key_kp_equal      = 336
    key_left_shift    = 340
    key_left_control  = 341
    key_left_alt      = 342
    key_left_super    = 343
    key_right_shift   = 344
    key_right_control = 345
    key_right_alt     = 346
    key_right_super   = 347
    key_menu          = 348
  TouchPoint* = object
    identifier*: ByteAddress
    x*, y*: float
    changed*: bool
  MouseButton* {.pure, size(4).} = enum
    mb_left    = 0x000
    mb_right   = 0x001
    mb_middle  = 0x002
    mb_invalid = 0x100
  Modifier* {.pure.} = enum
    mod_shift = 0
    mod_ctrl  = 1
    mod_alt   = 2
    mod_super = 3
    mod_lmb   = 8
    mod_rmb   = 9
    mod_mmb   = 10
  Modifiers* {.size(4).} = set[Modifier]

converter toRangePtr*(data: var openArray[byte]): RangePtr = RangePtr(head: data[0].addr, size: data.len.csize_t)
converter toRangePtr*(data: ptr openArray[byte]): RangePtr = RangePtr(head: data[0].addr, size: data[].len.csize_t)

template startApp*(desc: AppDesc): cint =
  proc sokol_main(argc: cint, argv: cstringArray): AppDesc {.exportc, cdecl.} =
    return desc
  sokol_entry(0, nil)