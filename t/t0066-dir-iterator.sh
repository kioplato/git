#!/bin/sh

test_description='Test the dir-iterator functionality'

TEST_PASSES_SANITIZE_LEAK=true
. ./test-lib.sh

test_expect_success 'setup -- dir with a single file' '
	mkdir dir1 &&
	>dir1/a
'
test_expect_success 'iteration of dir with a file' '
	cat >expected-out <<-EOF &&
	[f] (a) [a] ./dir1/a
	EOF

	test-tool dir-iterator ./dir1 >actual-out &&
	test_cmp expected-out actual-out
'

test_expect_success 'setup -- dir with a single dir' '
	mkdir -p dir2/a
'
test_expect_success 'iteration of dir with a single dir' '
	cat >expected-out <<-EOF &&
	[d] (a) [a] ./dir2/a
	EOF

	test-tool dir-iterator ./dir2 >actual-out &&
	test_cmp expected-out actual-out
'

test_expect_success POSIXPERM,SANITY 'setup -- dir w/ single dir w/o perms' '
	mkdir -p dir3/a
'
test_expect_success POSIXPERM,SANITY 'iteration of dir w/ dir w/o perms' '
	cat >expected-out <<-EOF &&
	[d] (a) [a] ./dir3/a
	EOF

	chmod 0 dir3/a &&

	test-tool dir-iterator ./dir3/ >actual-out &&
	test_cmp expected-out actual-out &&

	chmod 755 dir3/a
'
test_expect_success POSIXPERM,SANITY 'pedantic iteration of dir w/ dir w/o perms' '
	cat >expected-out <<-EOF &&
	[d] (a) [a] ./dir3/a
	dir_iterator_advance failure: EACCES
	EOF

	chmod 0 dir3/a &&

	test_must_fail test-tool dir-iterator --pedantic ./dir3/ >actual-out &&
	test_cmp expected-out actual-out &&

	chmod 755 dir3/a
'

test_expect_success 'setup -- dir w/ five files' '
	mkdir dir4 &&
	>dir4/a &&
	>dir4/b &&
	>dir4/c &&
	>dir4/d &&
	>dir4/e
'
test_expect_success 'iteration of dir w/ five files' '
	cat >expected-sorted-out <<-EOF &&
	[f] (a) [a] ./dir4/a
	[f] (b) [b] ./dir4/b
	[f] (c) [c] ./dir4/c
	[f] (d) [d] ./dir4/d
	[f] (e) [e] ./dir4/e
	EOF

	test-tool dir-iterator ./dir4 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-sorted-out actual-sorted-out
'

test_expect_success 'setup -- dir w/ dir w/ a file' '
	mkdir -p dir5/a &&
	>dir5/a/b
'
test_expect_success 'iteration of dir w/ dir w/ a file' '
	cat >expected-out <<-EOF &&
	[d] (a) [a] ./dir5/a
	[f] (a/b) [b] ./dir5/a/b
	EOF

	test-tool dir-iterator ./dir5 >actual-out &&
	test_cmp expected-out actual-out
'

test_expect_success 'setup -- dir w/ three nested dirs w/ file' '
	mkdir -p dir6/a/b/c &&
	>dir6/a/b/c/d
'
test_expect_success 'dir-iterator should list files in the correct order' '
	cat >expected-out <<-EOF &&
	[d] (a) [a] ./dir6/a
	[d] (a/b) [b] ./dir6/a/b
	[d] (a/b/c) [c] ./dir6/a/b/c
	[f] (a/b/c/d) [d] ./dir6/a/b/c/d
	EOF

	test-tool dir-iterator ./dir6 >actual-out &&
	test_cmp expected-out actual-out
'

test_expect_success POSIXPERM,SANITY \
'setup -- dir w/ three nested dirs w/ file, second nested dir w/o perms' '

	mkdir -p dir7/a/b/c &&
	>dir7/a/b/c/d
'
test_expect_success POSIXPERM,SANITY \
'iteration of dir w/ three nested dirs w/ file, second w/o perms' '

	cat >expected-out <<-EOF &&
	[d] (a) [a] ./dir7/a
	[d] (a/b) [b] ./dir7/a/b
	EOF

	chmod 0 dir7/a/b &&

	test-tool dir-iterator ./dir7 >actual-out &&
	test_cmp expected-out actual-out &&

	chmod 755 dir7/a/b
'
test_expect_success POSIXPERM,SANITY \
'pedantic iteration of dir w/ three nested dirs w/ file, second w/o perms' '

	cat >expected-out <<-EOF &&
	[d] (a) [a] ./dir7/a
	[d] (a/b) [b] ./dir7/a/b
	dir_iterator_advance failure: EACCES
	EOF

	chmod 0 dir7/a/b &&

	test_must_fail test-tool dir-iterator --pedantic ./dir7 >actual-out &&
	test_cmp expected-out actual-out &&

	chmod 755 dir7/a/b
'

test_expect_success 'setup -- dir w/ two dirs each w/ file' '
	mkdir -p dir8/a &&
	>dir8/a/b &&
	mkdir dir8/c &&
	>dir8/c/d
'
test_expect_success 'iteration of dir w/ two dirs each w/ file' '
	cat >expected-out1 <<-EOF &&
	[d] (a) [a] ./dir8/a
	[f] (a/b) [b] ./dir8/a/b
	[d] (c) [c] ./dir8/c
	[f] (c/d) [d] ./dir8/c/d
	EOF
	cat >expected-out2 <<-EOF &&
	[d] (c) [c] ./dir8/c
	[f] (c/d) [d] ./dir8/c/d
	[d] (a) [a] ./dir8/a
	[f] (a/b) [b] ./dir8/a/b
	EOF

	test-tool dir-iterator ./dir8 >actual-out &&
	(
		test_cmp expected-out1 actual-out ||
		test_cmp expected-out2 actual-out
	)
'

test_expect_success 'setup -- dir w/ two dirs, one w/ two and one w/ one files' '
	mkdir -p dir9/a &&
	>dir9/a/b &&
	>dir9/a/c &&
	mkdir dir9/d &&
	>dir9/d/e
'
test_expect_success \
'iteration of dir w/ two dirs, one w/ two and one w/ one files' '

	cat >expected-out1 <<-EOF &&
	[d] (a) [a] ./dir9/a
	[f] (a/b) [b] ./dir9/a/b
	[f] (a/c) [c] ./dir9/a/c
	[d] (d) [d] ./dir9/d
	[f] (d/e) [e] ./dir9/d/e
	EOF
	cat >expected-out2 <<-EOF &&
	[d] (a) [a] ./dir9/a
	[f] (a/c) [c] ./dir9/a/c
	[f] (a/b) [b] ./dir9/a/b
	[d] (d) [d] ./dir9/d
	[f] (d/e) [e] ./dir9/d/e
	EOF
	cat >expected-out3 <<-EOF &&
	[d] (d) [d] ./dir9/d
	[f] (d/e) [e] ./dir9/d/e
	[d] (a) [a] ./dir9/a
	[f] (a/b) [b] ./dir9/a/b
	[f] (a/c) [c] ./dir9/a/c
	EOF
	cat >expected-out4 <<-EOF &&
	[d] (d) [d] ./dir9/d
	[f] (d/e) [e] ./dir9/d/e
	[d] (a) [a] ./dir9/a
	[f] (a/c) [c] ./dir9/a/c
	[f] (a/b) [b] ./dir9/a/b
	EOF

	test-tool dir-iterator ./dir9 >actual-out &&
	(
		test_cmp expected-out1 actual-out ||
		test_cmp expected-out2 actual-out ||
		test_cmp expected-out3 actual-out ||
		test_cmp expected-out4 actual-out
	)
'

test_expect_success 'setup -- dir w/ two nested dirs, each w/ file' '
	mkdir -p dir10/a &&
	>dir10/a/b &&
	mkdir dir10/a/c &&
	>dir10/a/c/d
'
test_expect_success 'iteration of dir w/ two nested dirs, each w/ file' '
	cat >expected-out1 <<-EOF &&
	[d] (a) [a] ./dir10/a
	[f] (a/b) [b] ./dir10/a/b
	[d] (a/c) [c] ./dir10/a/c
	[f] (a/c/d) [d] ./dir10/a/c/d
	EOF
	cat >expected-out2 <<-EOF &&
	[d] (a) [a] ./dir10/a
	[d] (a/c) [c] ./dir10/a/c
	[f] (a/c/d) [d] ./dir10/a/c/d
	[f] (a/b) [b] ./dir10/a/b
	EOF

	test-tool dir-iterator ./dir10/ >actual-out &&
	(
		test_cmp expected-out1 actual-out ||
		test_cmp expected-out2 actual-out
	)
'

test_expect_success 'setup -- dir w/ complex structure' '
	mkdir -p dir11 &&
	mkdir -p dir11/a/b/c/ &&
	>dir11/b &&
	>dir11/c &&
	mkdir -p dir11/d/e/d/ &&
	>dir11/a/b/c/d &&
	>dir11/a/e &&
	>dir11/d/e/d/a
'
test_expect_success 'dir-iterator should iterate through all files' '
	cat >expected-sorted-out <<-EOF &&
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

	test-tool dir-iterator ./dir11 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-sorted-out actual-sorted-out
'

test_expect_success POSIXPERM,SANITY 'setup -- dir w/o perms' '
	mkdir -p dir12/a &&
	>dir12/a/b
'
test_expect_success POSIXPERM,SANITY 'iteration of root dir w/o perms' '
	cat >expected-out <<-EOF &&
	dir_iterator_advance failure: EACCES
	EOF

	chmod 0 dir12 &&

	test_must_fail test-tool dir-iterator ./dir12 >actual-out &&
	test_cmp expected-out actual-out &&

	chmod 755 dir12
'
test_expect_success POSIXPERM,SANITY 'pedantic iteration of root dir w/o perms' '
	cat >expected-out <<-EOF &&
	dir_iterator_advance failure: EACCES
	EOF

	chmod 0 dir12 &&

	test_must_fail test-tool dir-iterator --pedantic ./dir12 >actual-out &&
	test_cmp expected-out actual-out &&

	chmod 755 dir12
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
	mkdir -p dir13/a &&
	>dir13/a/b
'
test_expect_success POSIXPERM,SANITY 'advance should not fail on errors by default' '
	cat >expected-out <<-EOF &&
	[d] (a) [a] ./dir13/a
	EOF

	chmod 0 dir13/a &&

	test-tool dir-iterator ./dir13 >actual-out &&
	test_cmp expected-out actual-out &&

	chmod 755 dir13/a
'
test_expect_success POSIXPERM,SANITY 'advance should fail on errors, w/ pedantic flag' '
	cat >expected-out <<-EOF &&
	[d] (a) [a] ./dir13/a
	dir_iterator_advance failure: EACCES
	EOF

	chmod 0 dir13/a &&

	test_must_fail test-tool dir-iterator --pedantic ./dir13 >actual-out &&
	test_cmp expected-out actual-out &&

	chmod 755 dir13/a
'

test_expect_success SYMLINKS 'setup -- dir w/ symlinks, w/o cycle' '
	mkdir -p dir14/a &&
	mkdir -p dir14/b/c &&
	>dir14/a/d &&
	ln -s d dir14/a/e &&
	ln -s ../b dir14/a/f
'
test_expect_success SYMLINKS 'dir-iterator should not follow symlinks by default' '
	cat >expected-sorted-out <<-EOF &&
	[d] (a) [a] ./dir14/a
	[d] (b) [b] ./dir14/b
	[d] (b/c) [c] ./dir14/b/c
	[f] (a/d) [d] ./dir14/a/d
	[s] (a/e) [e] ./dir14/a/e
	[s] (a/f) [f] ./dir14/a/f
	EOF

	test-tool dir-iterator ./dir14 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-sorted-out actual-sorted-out
'
test_expect_success SYMLINKS 'dir-iterator should follow symlinks w/ follow flag' '
	cat >expected-sorted-out <<-EOF &&
	[d] (a) [a] ./dir14/a
	[d] (a/f) [f] ./dir14/a/f
	[d] (a/f/c) [c] ./dir14/a/f/c
	[d] (b) [b] ./dir14/b
	[d] (b/c) [c] ./dir14/b/c
	[f] (a/d) [d] ./dir14/a/d
	[f] (a/e) [e] ./dir14/a/e
	EOF

	test-tool dir-iterator --follow-symlinks ./dir14 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-sorted-out actual-sorted-out
'

test_expect_success SYMLINKS 'setup -- dir w/ symlinks, w/ cycle' '
	mkdir -p dir15/a/b &&
	mkdir -p dir15/a/c &&
	ln -s ../c dir15/a/b/d &&
	ln -s ../ dir15/a/b/e &&
	ln -s ../../ dir15/a/b/f
'
test_expect_success SYMLINKS 'iteration of dir w/ symlinks w/ cycle' '

	cat >expected-sorted-out <<-EOF &&
	[d] (a) [a] ./dir15/a
	[d] (a/b) [b] ./dir15/a/b
	[d] (a/c) [c] ./dir15/a/c
	[s] (a/b/d) [d] ./dir15/a/b/d
	[s] (a/b/e) [e] ./dir15/a/b/e
	[s] (a/b/f) [f] ./dir15/a/b/f
	EOF

	test-tool dir-iterator ./dir15 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-sorted-out actual-sorted-out
'
test_expect_success SYMLINKS \
'pedantic follow-symlinks iteration of dir w/ symlinks w/ cycle' '

	cat >expected-tailed-out <<-EOF &&
	dir_iterator_advance failure: ELOOP
	EOF

	test_must_fail test-tool dir-iterator \
		--pedantic --follow-symlinks ./dir15 >actual-out &&
	tail -n 1 actual-out >actual-tailed-out &&

	test_cmp expected-tailed-out actual-tailed-out
'

test_done
