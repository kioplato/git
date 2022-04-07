#!/bin/sh

test_description='Test the dir-iterator functionality'

TEST_PASSES_SANITIZE_LEAK=true
. ./test-lib.sh

test_expect_success 'setup -- dir w/ three nested dirs w/ file' '
	mkdir -p dir6/a/b/c &&
	>dir6/a/b/c/d &&


	cat >expected-out <<-EOF
	[d] (a) [a] ./dir6/a
	[d] (a/b) [b] ./dir6/a/b
	[d] (a/b/c) [c] ./dir6/a/b/c
	[f] (a/b/c/d) [d] ./dir6/a/b/c/d
	EOF
'
test_expect_success 'iteration of dir w/ three nested dirs w/ file' '
	test-tool dir-iterator ./dir6 >actual-out &&
	test_cmp expected-out actual-out
'

test_expect_success 'setup -- dir w/ complex structure w/o symlinks' '
	mkdir -p dir11/a/b/c/ &&
	>dir11/b &&
	>dir11/c &&
	>dir11/a/e &&
	>dir11/a/b/c/d &&
	mkdir -p dir11/d/e/d/ &&
	>dir11/d/e/d/a &&


	cat >expected-sorted-out <<-EOF
	[d] (a) [a] ./dir11/a
	[d] (a/b) [b] ./dir11/a/b
	[d] (a/b/c) [c] ./dir11/a/b/c
	[d] (d) [d] ./dir11/d
	[d] (d/e) [e] ./dir11/d/e
	[d] (d/e/d) [d] ./dir11/d/e/d
	[f] (a/b/c/d) [d] ./dir11/a/b/c/d
	[f] (a/e) [e] ./dir11/a/e
	[f] (b) [b] ./dir11/b
	[f] (c) [c] ./dir11/c
	[f] (d/e/d/a) [a] ./dir11/d/e/d/a
	EOF
'
test_expect_success 'iteration of dir w/ complex structure w/o symlinks' '
	test-tool dir-iterator ./dir11 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-sorted-out actual-sorted-out
'

test_expect_success 'dir_iterator_begin() should fail upon inexistent paths' '
	echo "dir_iterator_begin failure: ENOENT" >expected-inexistent-path-out &&

	test_must_fail test-tool dir-iterator ./inexistent-path >actual-out &&
	test_cmp expected-inexistent-path-out actual-out
'

test_expect_success 'dir_iterator_begin() should fail upon non directory paths' '
	>some-file &&


	echo "dir_iterator_begin failure: ENOTDIR" >expected-non-dir-out &&

	test_must_fail test-tool dir-iterator ./some-file >actual-out &&
	test_cmp expected-non-dir-out actual-out &&

	test_must_fail test-tool dir-iterator --pedantic ./some-file >actual-out &&
	test_cmp expected-non-dir-out actual-out
'

test_expect_success POSIXPERM,SANITY \
'dir_iterator_advance() should not fail on errors by default' '

	mkdir -p dir13/a &&
	>dir13/a/b &&
	chmod 0 dir13/a &&


	cat >expected-no-permissions-out <<-EOF &&
	[d] (a) [a] ./dir13/a
	EOF

	test-tool dir-iterator ./dir13 >actual-out &&
	test_cmp expected-no-permissions-out actual-out &&

	chmod 755 dir13/a &&
	rm -rf dir13
'

test_expect_success POSIXPERM,SANITY \
'dir_iterator_advance() should fail on errors, w/ pedantic flag' '

	mkdir -p dir13/a &&
	>dir13/a/b &&
	chmod 0 dir13/a &&


	cat >expected-no-permissions-pedantic-out <<-EOF &&
	[d] (a) [a] ./dir13/a
	dir_iterator_advance failure
	EOF

	test_must_fail test-tool dir-iterator --pedantic ./dir13 >actual-out &&
	test_cmp expected-no-permissions-pedantic-out actual-out &&

	chmod 755 dir13/a &&
	rm -rf dir13
'

test_expect_success SYMLINKS 'setup -- dir w/ symlinks w/o cycle' '
	mkdir -p dir14/a &&
	mkdir -p dir14/b/c &&
	>dir14/a/d &&
	ln -s d dir14/a/e &&
	ln -s ../b dir14/a/f &&


	cat >expected-dont-follow-sorted-out <<-EOF &&
	[d] (a) [a] ./dir14/a
	[d] (b) [b] ./dir14/b
	[d] (b/c) [c] ./dir14/b/c
	[f] (a/d) [d] ./dir14/a/d
	[s] (a/e) [e] ./dir14/a/e
	[s] (a/f) [f] ./dir14/a/f
	EOF
	cat >expected-follow-sorted-out <<-EOF
	[d] (a) [a] ./dir14/a
	[d] (a/f) [f] ./dir14/a/f
	[d] (a/f/c) [c] ./dir14/a/f/c
	[d] (b) [b] ./dir14/b
	[d] (b/c) [c] ./dir14/b/c
	[f] (a/d) [d] ./dir14/a/d
	[f] (a/e) [e] ./dir14/a/e
	EOF
'
test_expect_success SYMLINKS \
'dont-follow-symlinks of dir w/ symlinks w/o cycle' '

	test-tool dir-iterator ./dir14 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-dont-follow-sorted-out actual-sorted-out
'
test_expect_success SYMLINKS \
'follow-symlinks of dir w/ symlinks w/o cycle' '

	test-tool dir-iterator --follow-symlinks ./dir14 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-follow-sorted-out actual-sorted-out
'

test_done
