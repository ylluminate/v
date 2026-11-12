import os

// A reset signal must restore the terminal, run cleanup_fn, and then end the
// program by that same signal, so the parent sees how it ended.
fn test_reset_signals_restore_the_terminal_and_end_by_the_signal() {
	$if windows {
		return
	}
	fixture := os.join_path(@VMODROOT, 'vlib', 'term', 'ui', 'testdata', 'signal_exit.c.v')
	binary := os.join_path(os.vtmp_dir(), 'term_ui_signal_exit_${os.getpid()}')
	defer {
		os.rm(binary) or {}
	}
	compiled := os.exec([@VEXE, '-o', binary, fixture])
	assert compiled.exit_code == 0, compiled.output
	show_cursor := '\x1b[?25h'
	for mode in ['hup', 'int', 'term', 'abrt', 'segv', 'cont', 'exit'] {
		mut p := os.new_process(binary)
		p.set_args([mode])
		p.set_stdin_path(os.path_devnull)
		p.set_redirect_stdio()
		p.run()
		output := p.stdout_slurp()
		p.wait()
		status, code := p.status, p.code
		p.close()
		match mode {
			'exit' {
				assert output.count(show_cursor) == 1, '${mode}: ${output}'
				assert status == .exited, '${mode}: ${output}'
				assert code == 7, '${mode}: ${output}'
			}
			'cont' {
				// SIGCONT is not a reset signal; the program keeps running
				assert output.contains(show_cursor), '${mode}: ${output}'
				assert !output.contains('cleanup'), '${mode}: ${output}'
				assert status == .exited, '${mode}: ${output}'
				assert code == 5, '${mode}: ${output}'
			}
			else {
				assert output.count(show_cursor) == 1, '${mode}: ${output}'
				sig := output.all_after('raise ').all_before('\n').int()
				assert sig > 0, '${mode}: ${output}'
				assert output.contains('cleanup'), '${mode}: ${output}'
				assert status == .aborted, '${mode}: ${output}'
				assert code == 128 + sig, '${mode}: ${output}'
			}
		}
	}
}
