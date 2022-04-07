#!/bin/sh

test_description='Test the dir-iterator functionality'

TEST_PASSES_SANITIZE_LEAK=true
. ./test-lib.sh

test_expect_success 'setup -- dir with a single file' '
	mkdir dir1 &&
	>dir1/a &&


	cat >expected-out <<-EOF
	[f] (a) [a] ./dir1/a
	EOF
'
test_expect_success 'dirs-ignore of dir with a file' '
	test-tool dir-iterator ./dir1 >actual-out &&
	test_cmp expected-out actual-out
'
test_expect_success 'dirs-before of dir with a file' '
	test-tool dir-iterator --dirs-before ./dir1 >actual-out &&
	test_cmp expected-out actual-out
'
test_expect_success 'dirs-after of dir with a file' '
	test-tool dir-iterator --dirs-after ./dir1 >actual-out &&
	test_cmp expected-out actual-out
'
test_expect_success 'dirs-before/dirs-after of dir with a file' '
	test-tool dir-iterator --dirs-before --dirs-after ./dir1 >actual-out &&
	test_cmp expected-out actual-out
'

test_expect_success 'setup -- dir with a single dir' '
	mkdir -p dir2/a &&


	cat >expected-ignore-out <<-EOF &&
	EOF

	cat >expected-before-out <<-EOF &&
	[d] (a) [a] ./dir2/a
	EOF

	cat expected-before-out >expected-after-out &&

	cat >expected-before-after-out <<-EOF
	[d] (a) [a] ./dir2/a
	[d] (a) [a] ./dir2/a
	EOF
'
test_expect_success 'dirs-ignore of dir with a single dir' '
	test-tool dir-iterator ./dir2 >actual-out &&
	test_cmp expected-ignore-out actual-out
'
test_expect_success 'dirs-before of dir with a single dir' '
	test-tool dir-iterator --dirs-before ./dir2 >actual-out &&
	test_cmp expected-before-out actual-out
'
test_expect_success 'dirs-after of dir with a single dir' '
	test-tool dir-iterator --dirs-after ./dir2 >actual-out &&
	test_cmp expected-after-out actual-out
'
test_expect_success 'dirs-before/dirs-after of dir with a single dir' '
	test-tool dir-iterator --dirs-before --dirs-after ./dir2 >actual-out &&
	test_cmp expected-before-after-out actual-out
'

test_expect_success POSIXPERM,SANITY 'setup -- dir w/ single dir w/o perms' '
	mkdir -p dir3/a &&


	cat >expected-ignore-out <<-EOF &&
	EOF
	cat >expected-pedantic-ignore-out <<-EOF &&
	dir_iterator_advance failure
	EOF

	cat >expected-before-out <<-EOF &&
	[d] (a) [a] ./dir3/a
	EOF
	cat >expected-pedantic-before-out <<-EOF &&
	[d] (a) [a] ./dir3/a
	dir_iterator_advance failure
	EOF

	cat expected-before-out >expected-after-out &&
	cat >expected-pedantic-after-out <<-EOF &&
	dir_iterator_advance failure
	EOF

	cat >expected-before-after-out <<-EOF &&
	[d] (a) [a] ./dir3/a
	[d] (a) [a] ./dir3/a
	EOF
	cat expected-pedantic-before-out >expected-pedantic-before-after-out
'
test_expect_success POSIXPERM,SANITY 'dirs-ignore of dir w/ dir w/o perms' '
	chmod 0 dir3/a &&

	test-tool dir-iterator ./dir3/ >actual-out &&
	test_cmp expected-ignore-out actual-out &&

	chmod 755 dir3/a
'
test_expect_success POSIXPERM,SANITY 'pedantic dirs-ignore of dir w/ dir w/o perms' '
	chmod 0 dir3/a &&

	test_must_fail test-tool dir-iterator --pedantic ./dir3/ >actual-out &&
	test_cmp expected-pedantic-ignore-out actual-out &&

	chmod 755 dir3/a
'
test_expect_success POSIXPERM,SANITY 'dirs-before of dir w/ dir w/o perms' '
	chmod 0 dir3/a &&

	test-tool dir-iterator --dirs-before ./dir3/ >actual-out &&
	test_cmp expected-before-out actual-out &&

	chmod 755 dir3/a
'
test_expect_success POSIXPERM,SANITY 'pedantic dirs-before of dir w/ dir w/o perms' '
	chmod 0 dir3/a &&

	test_must_fail test-tool dir-iterator --dirs-before \
		--pedantic ./dir3/ >actual-out &&
	test_cmp expected-pedantic-before-out actual-out &&

	chmod 755 dir3/a
'
test_expect_success POSIXPERM,SANITY 'dirs-after of dir w/ dir w/o perms' '
	chmod 0 dir3/a &&

	test-tool dir-iterator --dirs-after ./dir3/ >actual-out &&
	test_cmp expected-after-out actual-out &&

	chmod 755 dir3/a
'
test_expect_success POSIXPERM,SANITY 'pedantic dirs-after of dir w/ dir w/o perms' '
	chmod 0 dir3/a &&

	test_must_fail test-tool dir-iterator --dirs-after \
		--pedantic ./dir3/ >actual-out &&
	test_cmp expected-pedantic-after-out actual-out &&

	chmod 755 dir3/a
'
test_expect_success POSIXPERM,SANITY \
'dirs-before/dirs-after of dir w/ dir w/o perms' '

	chmod 0 dir3/a &&

	test-tool dir-iterator --dirs-before --dirs-after ./dir3/ >actual-out &&
	test_cmp expected-before-after-out actual-out &&

	chmod 755 dir3/a
'
test_expect_success POSIXPERM,SANITY \
'pedantic dirs-before/dirs-after of dir w/ dir w/o perms' '

	chmod 0 dir3/a &&

	test_must_fail test-tool dir-iterator --dirs-before --dirs-after \
		--pedantic ./dir3/ >actual-out &&
	test_cmp expected-pedantic-before-after-out actual-out &&

	chmod 755 dir3/a
'

test_expect_success 'setup -- dir w/ five files' '
	mkdir dir4 &&
	>dir4/a &&
	>dir4/b &&
	>dir4/c &&
	>dir4/d &&
	>dir4/e &&


	cat >expected-sorted-out <<-EOF
	[f] (a) [a] ./dir4/a
	[f] (b) [b] ./dir4/b
	[f] (c) [c] ./dir4/c
	[f] (d) [d] ./dir4/d
	[f] (e) [e] ./dir4/e
	EOF
'
test_expect_success 'dirs-ignore of dir w/ five files' '
	test-tool dir-iterator ./dir4 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-sorted-out actual-sorted-out
'
test_expect_success 'dirs-before of dir w/ five files' '
	test-tool dir-iterator --dirs-before ./dir4 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-sorted-out actual-sorted-out
'
test_expect_success 'dirs-after of dir w/ five files' '
	test-tool dir-iterator --dirs-after ./dir4 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-sorted-out actual-sorted-out
'
test_expect_success 'dirs-before/dirs-after of dir w/ five files' '
	test-tool dir-iterator --dirs-before --dirs-after ./dir4 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-sorted-out actual-sorted-out
'

test_expect_success 'setup -- dir w/ dir w/ a file' '
	mkdir -p dir5/a &&
	>dir5/a/b &&


	cat >expected-ignore-out <<-EOF &&
	[f] (a/b) [b] ./dir5/a/b
	EOF

	cat >expected-before-out <<-EOF &&
	[d] (a) [a] ./dir5/a
	[f] (a/b) [b] ./dir5/a/b
	EOF

	cat >expected-after-out <<-EOF &&
	[f] (a/b) [b] ./dir5/a/b
	[d] (a) [a] ./dir5/a
	EOF

	cat >expected-before-after-out <<-EOF
	[d] (a) [a] ./dir5/a
	[f] (a/b) [b] ./dir5/a/b
	[d] (a) [a] ./dir5/a
	EOF
'
test_expect_success 'dirs-ignore of dir w/ dir w/ a file' '
	test-tool dir-iterator ./dir5 >actual-out &&
	test_cmp expected-ignore-out actual-out
'
test_expect_success 'dirs-before of dir w/ dir w/ a file' '
	test-tool dir-iterator --dirs-before ./dir5 >actual-out &&
	test_cmp expected-before-out actual-out
'
test_expect_success 'dirs-after of dir w/ dir w/ a file' '
	test-tool dir-iterator --dirs-after ./dir5 >actual-out &&
	test_cmp expected-after-out actual-out
'
test_expect_success 'dirs-before/dirs-after of dir w/ dir w/ a file' '
	test-tool dir-iterator --dirs-before --dirs-after ./dir5 >actual-out &&
	test_cmp expected-before-after-out actual-out
'

test_expect_success 'setup -- dir w/ three nested dirs w/ file' '
	mkdir -p dir6/a/b/c &&
	>dir6/a/b/c/d &&


	cat >expected-ignore-out <<-EOF &&
	[f] (a/b/c/d) [d] ./dir6/a/b/c/d
	EOF

	cat >expected-before-out <<-EOF &&
	[d] (a) [a] ./dir6/a
	[d] (a/b) [b] ./dir6/a/b
	[d] (a/b/c) [c] ./dir6/a/b/c
	[f] (a/b/c/d) [d] ./dir6/a/b/c/d
	EOF

	cat >expected-after-out <<-EOF &&
	[f] (a/b/c/d) [d] ./dir6/a/b/c/d
	[d] (a/b/c) [c] ./dir6/a/b/c
	[d] (a/b) [b] ./dir6/a/b
	[d] (a) [a] ./dir6/a
	EOF

	cat >expected-before-after-out <<-EOF
	[d] (a) [a] ./dir6/a
	[d] (a/b) [b] ./dir6/a/b
	[d] (a/b/c) [c] ./dir6/a/b/c
	[f] (a/b/c/d) [d] ./dir6/a/b/c/d
	[d] (a/b/c) [c] ./dir6/a/b/c
	[d] (a/b) [b] ./dir6/a/b
	[d] (a) [a] ./dir6/a
	EOF
'
test_expect_success 'dirs-ignore of dir w/ three nested dirs w/ file' '
	test-tool dir-iterator ./dir6 >actual-out &&
	test_cmp expected-ignore-out actual-out
'
test_expect_success 'dirs-before of dir w/ three nested dirs w/ file' '
	test-tool dir-iterator --dirs-before ./dir6 >actual-out &&
	test_cmp expected-before-out actual-out
'
test_expect_success 'dirs-after of dir w/ three nested dirs w/ file' '
	test-tool dir-iterator --dirs-after ./dir6 >actual-out &&
	test_cmp expected-after-out actual-out
'
test_expect_success 'dirs-before/dirs-after of dir w/ three nested dirs w/ file' '
	test-tool dir-iterator --dirs-before --dirs-after ./dir6 >actual-out &&
	test_cmp expected-before-after-out actual-out
'

test_expect_success POSIXPERM,SANITY \
'setup -- dir w/ three nested dirs w/ file, second nested dir w/o perms' '

	mkdir -p dir7/a/b/c &&
	>dir7/a/b/c/d &&


	cat >expected-ignore-out <<-EOF &&
	EOF
	cat >expected-pedantic-ignore-out <<-EOF &&
	dir_iterator_advance failure
	EOF

	cat >expected-before-out <<-EOF &&
	[d] (a) [a] ./dir7/a
	[d] (a/b) [b] ./dir7/a/b
	EOF
	cat >expected-pedantic-before-out <<-EOF &&
	[d] (a) [a] ./dir7/a
	[d] (a/b) [b] ./dir7/a/b
	dir_iterator_advance failure
	EOF

	cat >expected-after-out <<-EOF &&
	[d] (a/b) [b] ./dir7/a/b
	[d] (a) [a] ./dir7/a
	EOF
	cat >expected-pedantic-after-out <<-EOF &&
	dir_iterator_advance failure
	EOF

	cat >expected-before-after-out <<-EOF &&
	[d] (a) [a] ./dir7/a
	[d] (a/b) [b] ./dir7/a/b
	[d] (a/b) [b] ./dir7/a/b
	[d] (a) [a] ./dir7/a
	EOF
	cat >expected-pedantic-before-after-out <<-EOF
	[d] (a) [a] ./dir7/a
	[d] (a/b) [b] ./dir7/a/b
	dir_iterator_advance failure
	EOF
'
test_expect_success POSIXPERM,SANITY \
'dirs-ignore of dir w/ three nested dirs w/ file, second w/o perms' '

	chmod 0 dir7/a/b &&

	test-tool dir-iterator ./dir7 >actual-out &&
	test_cmp expected-ignore-out actual-out &&

	chmod 755 dir7/a/b
'
test_expect_success POSIXPERM,SANITY \
'pedantic dirs-ignore of dir w/ three nested dirs w/ file, second w/o perms' '

	chmod 0 dir7/a/b &&

	test_must_fail test-tool dir-iterator --pedantic ./dir7 >actual-out &&
	test_cmp expected-pedantic-ignore-out actual-out &&

	chmod 755 dir7/a/b
'
test_expect_success POSIXPERM,SANITY \
'dirs-before of dir w/ three nested dirs w/ file, second w/o perms' '

	chmod 0 dir7/a/b &&

	test-tool dir-iterator --dirs-before ./dir7 >actual-out &&
	test_cmp expected-before-out actual-out &&

	chmod 755 dir7/a/b
'
test_expect_success POSIXPERM,SANITY \
'pedantic dirs-before of dir w/ three nested dirs w/ file, second w/o perms' '

	chmod 0 dir7/a/b &&

	test_must_fail test-tool dir-iterator --dirs-before \
		--pedantic ./dir7 >actual-out &&
	test_cmp expected-pedantic-before-out actual-out &&

	chmod 755 dir7/a/b
'
test_expect_success POSIXPERM,SANITY \
'dirs-after of dir w/ three nested dirs w/ file, second w/o perms' '

	chmod 0 dir7/a/b &&

	test-tool dir-iterator --dirs-after ./dir7 >actual-out &&
	test_cmp expected-after-out actual-out &&

	chmod 755 dir7/a/b
'
test_expect_success POSIXPERM,SANITY \
'pedantic dirs-after of dir w/ three nested dirs w/ file, second w/o perms' '

	chmod 0 dir7/a/b &&

	test_must_fail test-tool dir-iterator --dirs-after \
		--pedantic ./dir7 >actual-out &&
	test_cmp expected-pedantic-after-out actual-out &&

	chmod 755 dir7/a/b
'
test_expect_success POSIXPERM,SANITY \
'dirs-before/dirs-after of dir w/ three nested dirs w/ file, second w/o perms' '

	chmod 0 dir7/a/b &&

	test-tool dir-iterator --dirs-before --dirs-after ./dir7 >actual-out &&
	test_cmp expected-before-after-out actual-out &&

	chmod 755 dir7/a/b
'
test_expect_success POSIXPERM,SANITY \
'pedantic dirs-before/dirs-after of dir w/ three nested dirs w/ file, second w/o perms' '

	chmod 0 dir7/a/b &&

	test_must_fail test-tool dir-iterator --dirs-before --dirs-after \
		--pedantic ./dir7 >actual-out &&
	test_cmp expected-pedantic-before-after-out actual-out &&

	chmod 755 dir7/a/b
'

test_expect_success 'setup -- dir w/ two dirs each w/ file' '
	mkdir -p dir8/a &&
	>dir8/a/b &&
	mkdir dir8/c &&
	>dir8/c/d &&


	cat >expected-ignore-out1 <<-EOF &&
	[f] (a/b) [b] ./dir8/a/b
	[f] (c/d) [d] ./dir8/c/d
	EOF
	cat >expected-ignore-out2 <<-EOF &&
	[f] (c/d) [d] ./dir8/c/d
	[f] (a/b) [b] ./dir8/a/b
	EOF

	cat >expected-before-out1 <<-EOF &&
	[d] (a) [a] ./dir8/a
	[f] (a/b) [b] ./dir8/a/b
	[d] (c) [c] ./dir8/c
	[f] (c/d) [d] ./dir8/c/d
	EOF
	cat >expected-before-out2 <<-EOF &&
	[d] (c) [c] ./dir8/c
	[f] (c/d) [d] ./dir8/c/d
	[d] (a) [a] ./dir8/a
	[f] (a/b) [b] ./dir8/a/b
	EOF

	cat >expected-after-out1 <<-EOF &&
	[f] (a/b) [b] ./dir8/a/b
	[d] (a) [a] ./dir8/a
	[f] (c/d) [d] ./dir8/c/d
	[d] (c) [c] ./dir8/c
	EOF
	cat >expected-after-out2 <<-EOF &&
	[f] (c/d) [d] ./dir8/c/d
	[d] (c) [c] ./dir8/c
	[f] (a/b) [b] ./dir8/a/b
	[d] (a) [a] ./dir8/a
	EOF

	cat >expected-before-after-out1 <<-EOF &&
	[d] (a) [a] ./dir8/a
	[f] (a/b) [b] ./dir8/a/b
	[d] (a) [a] ./dir8/a
	[d] (c) [c] ./dir8/c
	[f] (c/d) [d] ./dir8/c/d
	[d] (c) [c] ./dir8/c
	EOF
	cat >expected-before-after-out2 <<-EOF
	[d] (c) [c] ./dir8/c
	[f] (c/d) [d] ./dir8/c/d
	[d] (c) [c] ./dir8/c
	[d] (a) [a] ./dir8/a
	[f] (a/b) [b] ./dir8/a/b
	[d] (a) [a] ./dir8/a
	EOF
'
test_expect_success 'dirs-ignore of dir w/ two dirs each w/ file' '
	test-tool dir-iterator ./dir8 >actual-out &&
	(
		test_cmp expected-ignore-out1 actual-out ||
		test_cmp expected-ignore-out2 actual-out
	)
'
test_expect_success 'dirs-before of dir w/ two dirs each w/ file' '
	test-tool dir-iterator --dirs-before ./dir8 >actual-out &&
	(
		test_cmp expected-before-out1 actual-out ||
		test_cmp expected-before-out2 actual-out
	)
'
test_expect_success 'dirs-after of dir w/ two dirs each w/ file' '
	test-tool dir-iterator --dirs-after ./dir8 >actual-out &&
	(
		test_cmp expected-after-out1 actual-out ||
		test_cmp expected-after-out2 actual-out
	)
'
test_expect_success 'dirs-before/dirs-after of dir w/ two dirs each w/ file' '
	test-tool dir-iterator --dirs-before --dirs-after ./dir8 >actual-out &&
	(
		test_cmp expected-before-after-out1 actual-out ||
		test_cmp expected-before-after-out2 actual-out
	)
'

test_expect_success 'setup -- dir w/ two dirs, one w/ two and one w/ one files' '
	mkdir -p dir9/a &&
	>dir9/a/b &&
	>dir9/a/c &&
	mkdir dir9/d &&
	>dir9/d/e &&


	cat >expected-ignore-out1 <<-EOF &&
	[f] (a/b) [b] ./dir9/a/b
	[f] (a/c) [c] ./dir9/a/c
	[f] (d/e) [e] ./dir9/d/e
	EOF
	cat >expected-ignore-out2 <<-EOF &&
	[f] (a/c) [c] ./dir9/a/c
	[f] (a/b) [b] ./dir9/a/b
	[f] (d/e) [e] ./dir9/d/e
	EOF
	cat >expected-ignore-out3 <<-EOF &&
	[f] (d/e) [e] ./dir9/d/e
	[f] (a/b) [b] ./dir9/a/b
	[f] (a/c) [c] ./dir9/a/c
	EOF
	cat >expected-ignore-out4 <<-EOF &&
	[f] (d/e) [e] ./dir9/d/e
	[f] (a/c) [c] ./dir9/a/c
	[f] (a/b) [b] ./dir9/a/b
	EOF

	cat >expected-before-out1 <<-EOF &&
	[d] (a) [a] ./dir9/a
	[f] (a/b) [b] ./dir9/a/b
	[f] (a/c) [c] ./dir9/a/c
	[d] (d) [d] ./dir9/d
	[f] (d/e) [e] ./dir9/d/e
	EOF
	cat >expected-before-out2 <<-EOF &&
	[d] (a) [a] ./dir9/a
	[f] (a/c) [c] ./dir9/a/c
	[f] (a/b) [b] ./dir9/a/b
	[d] (d) [d] ./dir9/d
	[f] (d/e) [e] ./dir9/d/e
	EOF
	cat >expected-before-out3 <<-EOF &&
	[d] (d) [d] ./dir9/d
	[f] (d/e) [e] ./dir9/d/e
	[d] (a) [a] ./dir9/a
	[f] (a/b) [b] ./dir9/a/b
	[f] (a/c) [c] ./dir9/a/c
	EOF
	cat >expected-before-out4 <<-EOF &&
	[d] (d) [d] ./dir9/d
	[f] (d/e) [e] ./dir9/d/e
	[d] (a) [a] ./dir9/a
	[f] (a/c) [c] ./dir9/a/c
	[f] (a/b) [b] ./dir9/a/b
	EOF

	cat >expected-after-out1 <<-EOF &&
	[f] (a/b) [b] ./dir9/a/b
	[f] (a/c) [c] ./dir9/a/c
	[d] (a) [a] ./dir9/a
	[f] (d/e) [e] ./dir9/d/e
	[d] (d) [d] ./dir9/d
	EOF
	cat >expected-after-out2 <<-EOF &&
	[f] (a/c) [c] ./dir9/a/c
	[f] (a/b) [b] ./dir9/a/b
	[d] (a) [a] ./dir9/a
	[f] (d/e) [e] ./dir9/d/e
	[d] (d) [d] ./dir9/d
	EOF
	cat >expected-after-out3 <<-EOF &&
	[f] (d/e) [e] ./dir9/d/e
	[d] (d) [d] ./dir9/d
	[f] (a/b) [b] ./dir9/a/b
	[f] (a/c) [c] ./dir9/a/c
	[d] (a) [a] ./dir9/a
	EOF
	cat >expected-after-out4 <<-EOF &&
	[f] (d/e) [e] ./dir9/d/e
	[d] (d) [d] ./dir9/d
	[f] (a/c) [c] ./dir9/a/c
	[f] (a/b) [b] ./dir9/a/b
	[d] (a) [a] ./dir9/a
	EOF

	cat >expected-before-after-out1 <<-EOF &&
	[d] (a) [a] ./dir9/a
	[f] (a/b) [b] ./dir9/a/b
	[f] (a/c) [c] ./dir9/a/c
	[d] (a) [a] ./dir9/a
	[d] (d) [d] ./dir9/d
	[f] (d/e) [e] ./dir9/d/e
	[d] (d) [d] ./dir9/d
	EOF
	cat >expected-before-after-out2 <<-EOF &&
	[d] (a) [a] ./dir9/a
	[f] (a/c) [c] ./dir9/a/c
	[f] (a/b) [b] ./dir9/a/b
	[d] (a) [a] ./dir9/a
	[d] (d) [d] ./dir9/d
	[f] (d/e) [e] ./dir9/d/e
	[d] (d) [d] ./dir9/d
	EOF
	cat >expected-before-after-out3 <<-EOF &&
	[d] (d) [d] ./dir9/d
	[f] (d/e) [e] ./dir9/d/e
	[d] (d) [d] ./dir9/d
	[d] (a) [a] ./dir9/a
	[f] (a/b) [b] ./dir9/a/b
	[f] (a/c) [c] ./dir9/a/c
	[d] (a) [a] ./dir9/a
	EOF
	cat >expected-before-after-out4 <<-EOF
	[d] (d) [d] ./dir9/d
	[f] (d/e) [e] ./dir9/d/e
	[d] (d) [d] ./dir9/d
	[d] (a) [a] ./dir9/a
	[f] (a/c) [c] ./dir9/a/c
	[f] (a/b) [b] ./dir9/a/b
	[d] (a) [a] ./dir9/a
	EOF
'
test_expect_success \
'dirs-ignore of dir w/ three dirs, one w/ two, one w/ one and one w/ none files' '

	test-tool dir-iterator ./dir9 >actual-out &&
	(
		test_cmp expected-ignore-out1 actual-out ||
		test_cmp expected-ignore-out2 actual-out ||
		test_cmp expected-ignore-out3 actual-out ||
		test_cmp expected-ignore-out4 actual-out
	)
'
test_expect_success \
'dirs-before of dir w/ three dirs, one w/ two, one w/ one and one w/ none files' '

	test-tool dir-iterator --dirs-before ./dir9 >actual-out &&
	(
		test_cmp expected-before-out1 actual-out ||
		test_cmp expected-before-out2 actual-out ||
		test_cmp expected-before-out3 actual-out ||
		test_cmp expected-before-out4 actual-out
	)
'
test_expect_success \
'dirs-after of dir w/ three dirs, one w/ two, one w/ one and one w/ none files' '

	test-tool dir-iterator --dirs-after ./dir9 >actual-out &&
	(
		test_cmp expected-after-out1 actual-out ||
		test_cmp expected-after-out2 actual-out ||
		test_cmp expected-after-out3 actual-out ||
		test_cmp expected-after-out4 actual-out
	)
'
test_expect_success \
'dirs-before/dirs-after of dir w/ three dirs, one w/ two, one w/ one and one w/ none files' '

	test-tool dir-iterator --dirs-before --dirs-after ./dir9 >actual-out &&
	(
		test_cmp expected-before-after-out1 actual-out ||
		test_cmp expected-before-after-out2 actual-out ||
		test_cmp expected-before-after-out3 actual-out ||
		test_cmp expected-before-after-out4 actual-out
	)
'

test_expect_success 'setup -- dir w/ two nested dirs, each w/ file' '
	mkdir -p dir10/a &&
	>dir10/a/b &&
	mkdir dir10/a/c &&
	>dir10/a/c/d &&


	cat >expected-ignore-out1 <<-EOF &&
	[f] (a/b) [b] ./dir10/a/b
	[f] (a/c/d) [d] ./dir10/a/c/d
	EOF
	cat >expected-ignore-out2 <<-EOF &&
	[f] (a/c/d) [d] ./dir10/a/c/d
	[f] (a/b) [b] ./dir10/a/b
	EOF

	cat >expected-before-out1 <<-EOF &&
	[d] (a) [a] ./dir10/a
	[f] (a/b) [b] ./dir10/a/b
	[d] (a/c) [c] ./dir10/a/c
	[f] (a/c/d) [d] ./dir10/a/c/d
	EOF
	cat >expected-before-out2 <<-EOF &&
	[d] (a) [a] ./dir10/a
	[d] (a/c) [c] ./dir10/a/c
	[f] (a/c/d) [d] ./dir10/a/c/d
	[f] (a/b) [b] ./dir10/a/b
	EOF

	cat >expected-after-out1 <<-EOF &&
	[f] (a/b) [b] ./dir10/a/b
	[f] (a/c/d) [d] ./dir10/a/c/d
	[d] (a/c) [c] ./dir10/a/c
	[d] (a) [a] ./dir10/a
	EOF
	cat >expected-after-out2 <<-EOF &&
	[f] (a/c/d) [d] ./dir10/a/c/d
	[d] (a/c) [c] ./dir10/a/c
	[f] (a/b) [b] ./dir10/a/b
	[d] (a) [a] ./dir10/a
	EOF

	cat >expected-before-after-out1 <<-EOF &&
	[d] (a) [a] ./dir10/a
	[f] (a/b) [b] ./dir10/a/b
	[d] (a/c) [c] ./dir10/a/c
	[f] (a/c/d) [d] ./dir10/a/c/d
	[d] (a/c) [c] ./dir10/a/c
	[d] (a) [a] ./dir10/a
	EOF
	cat >expected-before-after-out2 <<-EOF
	[d] (a) [a] ./dir10/a
	[d] (a/c) [c] ./dir10/a/c
	[f] (a/c/d) [d] ./dir10/a/c/d
	[d] (a/c) [c] ./dir10/a/c
	[f] (a/b) [b] ./dir10/a/b
	[d] (a) [a] ./dir10/a
	EOF
'
test_expect_success 'dirs-ignore of dir w/ two nested dirs, each w/ file' '
	test-tool dir-iterator ./dir10/ >actual-out &&
	(
		test_cmp expected-ignore-out1 actual-out ||
		test_cmp expected-ignore-out2 actual-out
	)
'
test_expect_success 'dirs-before of dir w/ two nested dirs, each w/ file' '
	test-tool dir-iterator --dirs-before ./dir10/ >actual-out &&
	(
		test_cmp expected-before-out1 actual-out ||
		test_cmp expected-before-out2 actual-out
	)
'
test_expect_success 'dirs-after of dir w/ two nested dirs, each w/ file' '
	test-tool dir-iterator --dirs-after ./dir10/ >actual-out &&
	(
		test_cmp expected-after-out1 actual-out ||
		test_cmp expected-after-out2 actual-out
	)
'
test_expect_success 'dirs-before/dirs-after of dir w/ two nested dirs, each w/ file' '
	test-tool dir-iterator --dirs-before --dirs-after ./dir10 >actual-out &&
	(
		test_cmp expected-before-after-out1 actual-out ||
		test_cmp expected-before-after-out2 actual-out
	)
'

test_expect_success 'setup -- dir w/ complex structure w/o symlinks' '
	mkdir -p dir11/a/b/c/ &&
	>dir11/b &&
	>dir11/c &&
	>dir11/a/e &&
	>dir11/a/b/c/d &&
	mkdir -p dir11/d/e/d/ &&
	>dir11/d/e/d/a &&


	cat >expected-ignore-sorted-out <<-EOF &&
	[f] (a/b/c/d) [d] ./dir11/a/b/c/d
	[f] (a/e) [e] ./dir11/a/e
	[f] (b) [b] ./dir11/b
	[f] (c) [c] ./dir11/c
	[f] (d/e/d/a) [a] ./dir11/d/e/d/a
	EOF

	cat >expected-before-sorted-out <<-EOF &&
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

	cat expected-before-sorted-out >expected-after-sorted-out &&

	cat >expected-before-after-sorted-out <<-EOF
	[d] (a) [a] ./dir11/a
	[d] (a) [a] ./dir11/a
	[d] (a/b) [b] ./dir11/a/b
	[d] (a/b) [b] ./dir11/a/b
	[d] (a/b/c) [c] ./dir11/a/b/c
	[d] (a/b/c) [c] ./dir11/a/b/c
	[d] (d) [d] ./dir11/d
	[d] (d) [d] ./dir11/d
	[d] (d/e) [e] ./dir11/d/e
	[d] (d/e) [e] ./dir11/d/e
	[d] (d/e/d) [d] ./dir11/d/e/d
	[d] (d/e/d) [d] ./dir11/d/e/d
	[f] (a/b/c/d) [d] ./dir11/a/b/c/d
	[f] (a/e) [e] ./dir11/a/e
	[f] (b) [b] ./dir11/b
	[f] (c) [c] ./dir11/c
	[f] (d/e/d/a) [a] ./dir11/d/e/d/a
	EOF
'
test_expect_success 'dirs-ignore of dir w/ complex structure w/o symlinks' '
	test-tool dir-iterator ./dir11 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-ignore-sorted-out actual-sorted-out
'
test_expect_success 'dirs-before of dir w/ complex structure w/o symlinks' '
	test-tool dir-iterator --dirs-before ./dir11 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-before-sorted-out actual-sorted-out
'
test_expect_success 'dirs-after of dir w/ complex structure w/o symlinks' '
	test-tool dir-iterator --dirs-after ./dir11 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-after-sorted-out actual-sorted-out
'
test_expect_success 'dirs-before/dirs-after of dir w/ complex structure w/o symlinks' '
	test-tool dir-iterator --dirs-before --dirs-after ./dir11 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-before-after-sorted-out actual-sorted-out
'

test_expect_success POSIXPERM,SANITY \
'dir_iterator_begin() should fail on root dir w/o perms' '

	mkdir -p dir12/a &&
	>dir12/a/b &&
	chmod 0 dir12 &&


	cat >expected-no-permissions-out <<-EOF &&
	dir_iterator_begin failure: EACCES
	EOF

	test_must_fail test-tool dir-iterator ./dir12 >actual-out &&
	test_cmp expected-no-permissions-out actual-out &&

	test_must_fail test-tool dir-iterator --pedantic ./dir12 >actual-out &&
	test_cmp expected-no-permissions-out actual-out &&

	chmod 755 dir12 &&
	rm -rf dir12
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

test_expect_success SYMLINKS 'setup -- dir w/ symlinks w/o cycle' '
	mkdir -p dir14/a &&
	mkdir -p dir14/b/c &&
	>dir14/a/d &&
	ln -s d dir14/a/e &&
	ln -s ../b dir14/a/f &&


	cat >expected-dont-follow-ignore-sorted-out <<-EOF &&
	[f] (a/d) [d] ./dir14/a/d
	[s] (a/e) [e] ./dir14/a/e
	[s] (a/f) [f] ./dir14/a/f
	EOF
	cat >expected-follow-ignore-sorted-out <<-EOF &&
	[f] (a/d) [d] ./dir14/a/d
	[f] (a/e) [e] ./dir14/a/e
	EOF

	cat >expected-dont-follow-before-sorted-out <<-EOF &&
	[d] (a) [a] ./dir14/a
	[d] (b) [b] ./dir14/b
	[d] (b/c) [c] ./dir14/b/c
	[f] (a/d) [d] ./dir14/a/d
	[s] (a/e) [e] ./dir14/a/e
	[s] (a/f) [f] ./dir14/a/f
	EOF
	cat >expected-follow-before-sorted-out <<-EOF &&
	[d] (a) [a] ./dir14/a
	[d] (a/f) [f] ./dir14/a/f
	[d] (a/f/c) [c] ./dir14/a/f/c
	[d] (b) [b] ./dir14/b
	[d] (b/c) [c] ./dir14/b/c
	[f] (a/d) [d] ./dir14/a/d
	[f] (a/e) [e] ./dir14/a/e
	EOF

	cat expected-dont-follow-before-sorted-out >expected-dont-follow-after-sorted-out &&
	cat expected-follow-before-sorted-out >expected-follow-after-sorted-out &&

	cat >expected-dont-follow-before-after-sorted-out <<-EOF &&
	[d] (a) [a] ./dir14/a
	[d] (a) [a] ./dir14/a
	[d] (b) [b] ./dir14/b
	[d] (b) [b] ./dir14/b
	[d] (b/c) [c] ./dir14/b/c
	[d] (b/c) [c] ./dir14/b/c
	[f] (a/d) [d] ./dir14/a/d
	[s] (a/e) [e] ./dir14/a/e
	[s] (a/f) [f] ./dir14/a/f
	EOF
	cat >expected-follow-before-after-sorted-out <<-EOF
	[d] (a) [a] ./dir14/a
	[d] (a) [a] ./dir14/a
	[d] (a/f) [f] ./dir14/a/f
	[d] (a/f) [f] ./dir14/a/f
	[d] (a/f/c) [c] ./dir14/a/f/c
	[d] (a/f/c) [c] ./dir14/a/f/c
	[d] (b) [b] ./dir14/b
	[d] (b) [b] ./dir14/b
	[d] (b/c) [c] ./dir14/b/c
	[d] (b/c) [c] ./dir14/b/c
	[f] (a/d) [d] ./dir14/a/d
	[f] (a/e) [e] ./dir14/a/e
	EOF
'
test_expect_success SYMLINKS \
'dont-follow-symlinks dirs-ignore of dir w/ symlinks w/o cycle' '

	test-tool dir-iterator ./dir14 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-dont-follow-ignore-sorted-out actual-sorted-out
'
test_expect_success SYMLINKS \
'follow-symlinks dirs-ignore of dir w/ symlinks w/o cycle' '

	test-tool dir-iterator --follow-symlinks ./dir14 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-follow-ignore-sorted-out actual-sorted-out
'
test_expect_success SYMLINKS \
'dont-follow-symlinks dirs-before of dir w/ symlinks w/o cycle' '

	test-tool dir-iterator --dirs-before ./dir14 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-dont-follow-before-sorted-out actual-sorted-out
'
test_expect_success SYMLINKS \
'follow-symlinks dirs-before of dir w/ symlinks w/o cycle' '

	test-tool dir-iterator --dirs-before --follow-symlinks ./dir14 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-follow-before-sorted-out actual-sorted-out
'
test_expect_success SYMLINKS \
'dont-follow-symlinks dirs-after of dir w/ symlinks w/o cycle' '

	test-tool dir-iterator --dirs-after ./dir14 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-dont-follow-after-sorted-out actual-sorted-out
'
test_expect_success SYMLINKS \
'follow-symlinks dirs-after of dir w/ symlinks w/o cycle' '

	test-tool dir-iterator --dirs-after --follow-symlinks ./dir14 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-follow-after-sorted-out actual-sorted-out
'
test_expect_success SYMLINKS \
'dont-follow-symlinks dirs-before/dirs-after of dir w/ symlinks w/o cycle' '

	test-tool dir-iterator --dirs-before --dirs-after ./dir14 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-dont-follow-before-after-sorted-out actual-sorted-out
'
test_expect_success SYMLINKS \
'follow-symlinks dirs-before/dirs-after of dir w/ symlinks w/o cycle' '

	test-tool dir-iterator --dirs-before --dirs-after --follow-symlinks ./dir14 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-follow-before-after-sorted-out actual-sorted-out
'

test_expect_success SYMLINKS 'setup -- dir w/ symlinks w/ cycle' '
	mkdir -p dir15/a/b &&
	mkdir -p dir15/a/c &&
	ln -s ../c dir15/a/b/d &&
	ln -s ../ dir15/a/b/e &&
	ln -s ../../ dir15/a/b/f &&


	cat >expected-dont-follow-ignore-sorted-out <<-EOF &&
	[s] (a/b/d) [d] ./dir15/a/b/d
	[s] (a/b/e) [e] ./dir15/a/b/e
	[s] (a/b/f) [f] ./dir15/a/b/f
	EOF

	cat >expected-dont-follow-before-sorted-out <<-EOF &&
	[d] (a) [a] ./dir15/a
	[d] (a/b) [b] ./dir15/a/b
	[d] (a/c) [c] ./dir15/a/c
	[s] (a/b/d) [d] ./dir15/a/b/d
	[s] (a/b/e) [e] ./dir15/a/b/e
	[s] (a/b/f) [f] ./dir15/a/b/f
	EOF

	cat expected-dont-follow-before-sorted-out >expected-dont-follow-after-sorted-out &&

	cat >expected-dont-follow-before-after-sorted-out <<-EOF &&
	[d] (a) [a] ./dir15/a
	[d] (a) [a] ./dir15/a
	[d] (a/b) [b] ./dir15/a/b
	[d] (a/b) [b] ./dir15/a/b
	[d] (a/c) [c] ./dir15/a/c
	[d] (a/c) [c] ./dir15/a/c
	[s] (a/b/d) [d] ./dir15/a/b/d
	[s] (a/b/e) [e] ./dir15/a/b/e
	[s] (a/b/f) [f] ./dir15/a/b/f
	EOF

	cat >expected-pedantic-follow-tailed-out <<-EOF
	dir_iterator_advance failure
	EOF
'
test_expect_success SYMLINKS \
'dont-follow-symlinks dirs-ignore of dir w/ symlinks w/ cycle' '

	test-tool dir-iterator ./dir15 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-dont-follow-ignore-sorted-out actual-sorted-out
'
test_expect_success SYMLINKS \
'pedantic follow-symlinks dirs-ignore of dir w/ symlinks w/ cycle' '

	test_must_fail test-tool dir-iterator \
		--follow-symlinks --pedantic ./dir15 >actual-out &&
	tail -n 1 actual-out >actual-tailed-out &&

	test_cmp expected-pedantic-follow-tailed-out actual-tailed-out
'
test_expect_success SYMLINKS \
'dont-follow-symlinks dirs-before of dir w/ symlinks w/ cycle' '

	test-tool dir-iterator --dirs-before ./dir15 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-dont-follow-before-sorted-out actual-sorted-out
'
test_expect_success SYMLINKS \
'pedantic follow-symlinks dirs-before of dir w/ symlinks w/ cycle' '

	test_must_fail test-tool dir-iterator --dirs-before \
		--pedantic --follow-symlinks ./dir15 >actual-out &&
	tail -n 1 actual-out >actual-tailed-out &&

	test_cmp expected-pedantic-follow-tailed-out actual-tailed-out
'
test_expect_success SYMLINKS \
'dont-follow-symlinks dirs-after of dir w/ symlinks w/ cycle' '

	test-tool dir-iterator --dirs-after ./dir15 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-dont-follow-after-sorted-out actual-sorted-out
'
test_expect_success SYMLINKS \
'pedantic follow-symlinks dirs-after of dir w/ symlinks w/ cycle' '

	test_must_fail test-tool dir-iterator --dirs-after \
		--pedantic --follow-symlinks ./dir15 >actual-out &&
	tail -n 1 actual-out >actual-tailed-out &&

	test_cmp expected-pedantic-follow-tailed-out actual-tailed-out
'
test_expect_success SYMLINKS \
'dont-follow-symlinks dirs-before/dirs-after of dir w/ symlinks w/ cycle' '

	test-tool dir-iterator --dirs-before --dirs-after ./dir15 >actual-out &&
	sort actual-out >actual-sorted-out &&

	test_cmp expected-dont-follow-before-after-sorted-out actual-sorted-out
'
test_expect_success SYMLINKS \
'pedantic follow-symlinks dirs-before/dirs-after of dir w/ symlinks w/ cycle' '

	test_must_fail test-tool dir-iterator --dirs-before --dirs-after \
		--pedantic --follow-symlinks ./dir15 >actual-out &&
	tail -n 1 actual-out >actual-tailed-out &&

	test_cmp expected-pedantic-follow-tailed-out actual-tailed-out
'

test_done
