#!/bin/sh

test_description='Test the dir-iterator functionality'

TEST_PASSES_SANITIZE_LEAK=true
. ./test-lib.sh

test_expect_success 'setup -- dir w/ complex structure' '
	mkdir -p dir &&
	mkdir -p dir/a/b/c/ &&
	>dir/b &&
	>dir/c &&
	mkdir -p dir/d/e/d/ &&
	>dir/a/b/c/d &&
	>dir/a/e &&
	>dir/d/e/d/a
'
test_expect_success 'dir-iterator should iterate through all files' '
	cat >expected-sorted-out <<-EOF &&
	[d] (a) [a] ./dir/a
	[d] (a/b) [b] ./dir/a/b
	[d] (a/b/c) [c] ./dir/a/b/c
	[d] (d) [d] ./dir/d
	[d] (d/e) [e] ./dir/d/e
	[d] (d/e/d) [d] ./dir/d/e/d
	[f] (a/b/c/d) [d] ./dir/a/b/c/d
	[f] (a/e) [e] ./dir/a/e
	[f] (b) [b] ./dir/b
	[f] (c) [c] ./dir/c
	[f] (d/e/d/a) [a] ./dir/d/e/d/a
	EOF

	test-tool dir-iterator ./dir >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-sorted-out actual-sorted-out
'

test_expect_success 'setup -- dir w/ three nested dirs w/ file' '
	mkdir -p dir2/a/b/c &&
	>dir2/a/b/c/d
'
test_expect_success 'dir-iterator should list files in the correct order' '
	cat >expected-out <<-EOF &&
	[d] (a) [a] ./dir2/a
	[d] (a/b) [b] ./dir2/a/b
	[d] (a/b/c) [c] ./dir2/a/b/c
	[f] (a/b/c/d) [d] ./dir2/a/b/c/d
	EOF

	test-tool dir-iterator ./dir2 >actual-out &&

	test_cmp expected-out actual-out
'

test_expect_success 'begin should fail upon inexistent paths' '
	echo "dir_iterator_begin failure: ENOENT" >expected-out &&

	test_must_fail test-tool dir-iterator ./inexistent-path >actual-out &&

	test_cmp expected-out actual-out
'

test_expect_success 'begin should fail upon non directory paths' '
	>some-file &&

	echo "dir_iterator_begin failure: ENOTDIR" >expected-out &&

	test_must_fail test-tool dir-iterator ./some-file >actual-out &&

	test_cmp expected-out actual-out
'

test_expect_success POSIXPERM,SANITY 'setup -- dir w/ dir w/o perms w/ file' '
	mkdir -p dir3/a &&
	>dir3/a/b
'
test_expect_success POSIXPERM,SANITY 'advance should not fail on errors by default' '
	cat >expected-out <<-EOF &&
	[d] (a) [a] ./dir3/a
	EOF

	chmod 0 dir3/a &&

	test-tool dir-iterator ./dir3 >actual-out &&
	test_cmp expected-out actual-out &&

	chmod 755 dir3/a
'
test_expect_success POSIXPERM,SANITY 'advance should fail on errors, w/ pedantic flag' '
	cat >expected-out <<-EOF &&
	[d] (a) [a] ./dir3/a
	dir_iterator_advance failure
	EOF

	chmod 0 dir3/a &&

	test_must_fail test-tool dir-iterator --pedantic ./dir3 >actual-out &&
	test_cmp expected-out actual-out &&

	chmod 755 dir3/a
'

test_expect_success SYMLINKS 'setup -- dir w/ symlinks w/o cycle' '
	mkdir -p dir4/a &&
	mkdir -p dir4/b/c &&
	>dir4/a/d &&
	ln -s d dir4/a/e &&
	ln -s ../b dir4/a/f
'
test_expect_success SYMLINKS 'dir-iterator should not follow symlinks by default' '
	cat >expected-sorted-out <<-EOF &&
	[d] (a) [a] ./dir4/a
	[d] (b) [b] ./dir4/b
	[d] (b/c) [c] ./dir4/b/c
	[f] (a/d) [d] ./dir4/a/d
	[s] (a/e) [e] ./dir4/a/e
	[s] (a/f) [f] ./dir4/a/f
	EOF

	test-tool dir-iterator ./dir4 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-sorted-out actual-sorted-out
'
test_expect_success SYMLINKS 'dir-iterator should follow symlinks w/ follow flag' '
	cat >expected-sorted-out <<-EOF &&
	[d] (a) [a] ./dir4/a
	[d] (a/f) [f] ./dir4/a/f
	[d] (a/f/c) [c] ./dir4/a/f/c
	[d] (b) [b] ./dir4/b
	[d] (b/c) [c] ./dir4/b/c
	[f] (a/d) [d] ./dir4/a/d
	[f] (a/e) [e] ./dir4/a/e
	EOF

	test-tool dir-iterator --follow-symlinks ./dir4 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-sorted-out actual-sorted-out
'

test_expect_success SYMLINKS 'setup -- dir w/ symlinks w/ cycle' '
	mkdir -p dir5/a/b &&
	mkdir -p dir5/a/c &&
	ln -s ../c dir5/a/b/d &&
	ln -s ../ dir5/a/b/e &&
	ln -s ../../ dir5/a/b/f
'

test_done
