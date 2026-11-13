fn source[T](a []T) &[]T {
	return &a
}

fn joined[T](a []T) string {
	return source(a).join(',')
}

fn test_join_on_an_array_pointer_returned_by_a_generic_call() {
	assert joined(['a', 'b', 'c']) == 'a,b,c'
}
