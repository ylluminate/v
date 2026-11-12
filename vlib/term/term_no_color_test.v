import os

const vexe = @VEXE

const probe_source = "import os\nimport term\n\nfn main() {\n\tprintln('tty=\${os.is_atty(1) > 0 && os.is_atty(2) > 0} stdout=\${term.can_show_color_on_stdout()} stderr=\${term.can_show_color_on_stderr()}')\n}\n"

// run_on_a_terminal runs `exe` on a pseudo-terminal with the given `NO_COLOR` and `VCOLORS`
// values ('unset' leaves the variable out), and returns what it printed.
fn run_on_a_terminal(script_exe string, exe string, no_color string, vcolors string) string {
	for name, value in {
		'NO_COLOR': no_color
		'VCOLORS':  vcolors
	} {
		if value == 'unset' {
			os.unsetenv(name)
		} else {
			os.setenv(name, value, true)
		}
	}
	os.setenv('TERM', 'xterm', true)
	mut p := os.new_process(script_exe)
	$if linux {
		p.set_args(['-q', '-c', os.quoted_path(exe), '/dev/null'])
	} $else {
		p.set_args(['-q', '/dev/null', exe])
	}
	p.set_redirect_stdio()
	p.run()
	p.wait()
	output := p.stdout_slurp() + p.stderr_slurp()
	p.close()
	return output
}

fn test_can_show_color_follows_no_color_on_a_terminal() {
	$if !(macos || linux || freebsd) {
		return
	}
	script_exe := os.find_abs_path_of_executable('script') or { return }
	tmp_dir := os.join_path(os.vtmp_dir(), 'term_no_color_test_${os.getpid()}')
	os.mkdir_all(tmp_dir) or { panic(err) }
	saved := {
		'NO_COLOR': os.getenv_opt('NO_COLOR')
		'VCOLORS':  os.getenv_opt('VCOLORS')
		'TERM':     os.getenv_opt('TERM')
	}
	defer {
		for name, value in saved {
			if v := value {
				os.setenv(name, v, true)
			} else {
				os.unsetenv(name)
			}
		}
		os.rmdir_all(tmp_dir) or {}
	}
	source := os.join_path(tmp_dir, 'probe.v')
	exe := os.join_path(tmp_dir, 'probe')
	os.write_file(source, probe_source) or { panic(err) }
	res := os.exec([vexe, '-o', exe, source])
	assert res.exit_code == 0, res.output
	colors := 'stdout=true stderr=true'
	plain := 'stdout=false stderr=false'
	control := run_on_a_terminal(script_exe, exe, 'unset', 'unset')
	if !control.contains('tty=true') {
		eprintln('skipping, `script` did not give the probe a terminal: ${control}')
		return
	}
	assert control.contains(colors)
	assert run_on_a_terminal(script_exe, exe, '1', 'unset').contains(plain)
	assert run_on_a_terminal(script_exe, exe, 'false', 'unset').contains(plain)
	assert run_on_a_terminal(script_exe, exe, '', 'unset').contains(colors)
	assert run_on_a_terminal(script_exe, exe, '1', 'always').contains(colors)
	assert run_on_a_terminal(script_exe, exe, '1', 'never').contains(plain)
}
