struct Receiver {}

fn (r Receiver) show[T](args ...T) string {
	return '${typeof(args).name} ${args}'
}

fn (r &Receiver) show_ref[T](args ...T) string {
	return '${typeof(args).name} ${args}'
}

fn (r Receiver) show_after[T](x int, args ...T) string {
	return '${x} ${typeof(args).name} ${args}'
}

fn test_generic_method_with_decomposed_array() {
	ints := [2, 1]
	names := ['a', 'b']
	r := Receiver{}
	assert Receiver{}.show(...ints) == '...int [2, 1]'
	assert r.show(...ints) == '...int [2, 1]'
	assert r.show(...names) == "...string ['a', 'b']"
	assert r.show_ref(...ints) == '...int [2, 1]'
	assert r.show_after(7, ...ints) == '7 ...int [2, 1]'
	assert '${r.show(...ints)}' == '...int [2, 1]'
}

fn test_generic_method_with_array_as_one_variadic_element() {
	ints := [2, 1]
	assert Receiver{}.show(ints) == '...[]int [[2, 1]]'
}
