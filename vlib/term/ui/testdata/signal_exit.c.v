module main

// Used by signal_exit_test.v: starts a term.ui app, which then either exits
// normally or delivers a signal to itself, so the test can check how it ends.
import os
import term.ui as tui

#include <signal.h>

fn C.raise(i32) i32

struct App {
mut:
	tui    &tui.Context = unsafe { nil }
	frames int
}

fn frame(x voidptr) {
	mut app := unsafe { &App(x) }
	app.frames++
	if app.frames < 2 {
		return
	}
	sig := match os.args[1] {
		'hup' { int(C.SIGHUP) }
		'int' { int(C.SIGINT) }
		'term' { int(C.SIGTERM) }
		'abrt' { int(C.SIGABRT) }
		'segv' { int(C.SIGSEGV) }
		'cont' { int(C.SIGCONT) }
		else { exit(7) }
	}
	println('raise ${sig}')
	flush_stdout()
	C.raise(i32(sig))
	// only reached when the signal does not end the program
	exit(5)
}

fn cleanup(_ voidptr) {
	println('cleanup')
	flush_stdout()
}

fn main() {
	mut app := &App{}
	app.tui = tui.init(
		user_data:        app
		frame_fn:         frame
		cleanup_fn:       cleanup
		skip_init_checks: true
		frame_rate:       60
	)
	app.tui.run()!
}
