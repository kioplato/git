#include "cache.h"
#include "dir.h"
#include "iterator.h"
#include "dir-iterator.h"

struct dir_iterator_level {
	DIR *dir;

	/*
	 * The length of the directory part of path at this level.
	 */
	size_t prefix_len;
};

/*
 * The full data structure used to manage the internal directory
 * iteration state. It includes members that are not part of the
 * public interface.
 */
struct dir_iterator_int {
	struct dir_iterator base;

	/*
	 * The number of levels currently on the stack. After the first
	 * call to dir_iterator_begin(), if it succeeds to open the
	 * first level's dir, this will always be at least 1. Then,
	 * when it comes to zero the iteration is ended and this
	 * struct is freed.
	 */
	size_t levels_nr;

	/* The number of levels that have been allocated on the stack */
	size_t levels_alloc;

	/*
	 * A stack of levels. levels[0] is the root directory.
	 * It won't be included in the iteration, but iteration will happen
	 * inside it's subdirectories.
	 */
	struct dir_iterator_level *levels;

	/* Combination of flags for this dir-iterator */
	unsigned int flags;
};

enum {
	OK,
	FAIL_ENOENT,
	FAIL_NOT_ENOENT,
};

/*
 * Push a level in the iter stack and initialize it with information from
 * the directory pointed by iter->base->path. Don't open the directory.
 *
 * Return 1 on success.
 * Return 0 when `iter->base->path` isn't a directory.
 */
static int push_level(struct dir_iterator_int *iter)
{
	struct dir_iterator_level *level;

	if (!S_ISDIR(iter->base.st.st_mode))
		return 0;

	ALLOC_GROW(iter->levels, iter->levels_nr + 1, iter->levels_alloc);
	level = &iter->levels[iter->levels_nr++];

	level->dir = NULL;

	level->prefix_len = iter->base.path.len;

	return 1;
}

/*
 * Activate most recent pushed level. Stack is unchanged.
 *
 * Return values:
 * OK on success.
 * FAIL_ENOENT on failed exposure because entry does not exist.
 * FAIL_NOT_ENOENT on failed exposure because of errno other than ENOENT.
 */
static int activate_level(struct dir_iterator_int *iter)
{
	struct dir_iterator_level *level = &iter->levels[iter->levels_nr - 1];
	int saved_errno;

	if (level->dir)
		return OK;

	if ((level->dir = opendir(iter->base.path.buf)) != NULL)
		return OK;

	saved_errno = errno;
	if (errno != ENOENT) {
		warning_errno("error opening directory '%s'", iter->base.path.buf);
		errno = saved_errno;
		return FAIL_NOT_ENOENT;
	}
	errno = saved_errno;
	return FAIL_ENOENT;
}

/*
 * Pop the top level on the iter stack, releasing any resources associated
 * with it. Return the new value of iter->levels_nr.
 */
static int pop_level(struct dir_iterator_int *iter)
{
	struct dir_iterator_level *level = &iter->levels[iter->levels_nr - 1];

	if (level->dir && closedir(level->dir))
		warning_errno("error closing directory '%s'", iter->base.path.buf);
	level->dir = NULL;

	return --iter->levels_nr;
}

/*
 * Populate iter->base with the necessary information on the next iteration
 * entry, represented by the given relative path to the lowermost directory,
 * d_name.
 *
 * Return values:
 * OK on successful exposure of the provided entry.
 * FAIL_ENOENT on failed exposure because entry does not exist.
 * FAIL_NOT_ENOENT on failed exposure because of errno other than ENOENT.
 */
static int expose_entry(struct dir_iterator_int *iter, char *d_name)
{
	int stat_err;

	strbuf_addch(&iter->base.path, '/');
	strbuf_addstr(&iter->base.path, d_name);

	if (iter->flags & DIR_ITERATOR_FOLLOW_SYMLINKS)
		stat_err = stat(iter->base.path.buf, &iter->base.st);
	else
		stat_err = lstat(iter->base.path.buf, &iter->base.st);

	if (stat_err && errno != ENOENT) {
		warning_errno("failed to stat '%s'", iter->base.path.buf);
		return FAIL_NOT_ENOENT;
	} else if (stat_err && errno == ENOENT) {
		return FAIL_ENOENT;
	}

	/*
	 * We have to reset relative path and basename because the path strbuf
	 * might have been realloc()'ed at the previous strbuf_addstr().
	 */

	iter->base.relative_path =
		iter->base.path.buf + iter->levels[0].prefix_len + 1;
	iter->base.basename =
		iter->base.path.buf + iter->levels[iter->levels_nr - 1].prefix_len + 1;

	return OK;
}

int dir_iterator_advance(struct dir_iterator *dir_iterator)
{
	struct dir_iterator_int *iter = (struct dir_iterator_int *)dir_iterator;
	struct dir_iterator_level *level = &iter->levels[iter->levels_nr - 1];
	struct dirent *dir_entry = NULL;
	int expose_err, activate_err;
	/* For shorter code width-wise, more readable */
	unsigned int PEDANTIC = iter->flags & DIR_ITERATOR_PEDANTIC;

	/*
	 * Attempt to open the directory of the last level if not opened yet.
	 *
	 * Remember that we ignore ENOENT errors so that the user of this API
	 * can remove entries between calls to `dir_iterator_advance()`.
	 * We care for errors other than ENOENT only when PEDANTIC is enabled.
	 */

	activate_err = activate_level(iter);

	if (activate_err == FAIL_NOT_ENOENT && PEDANTIC) {
		goto error_out;
	} else if (activate_err != OK) {
		/*
		 * We activate the root level at `dir_iterator_begin()`.
		 * Therefore, there isn't any case to run out of levels.
		 */

		--iter->levels_nr;

		return dir_iterator_advance(dir_iterator);
	}

	strbuf_setlen(&iter->base.path, level->prefix_len);

	errno = 0;
	dir_entry = readdir(level->dir);

	if (!dir_entry) {
		if (errno) {
			warning_errno("errno reading dir '%s'", iter->base.path.buf);
			if (PEDANTIC)
				goto error_out;

			return dir_iterator_advance(dir_iterator);
		} else {
			/*
			 * Current directory has been iterated through.
			 */

			if (pop_level(iter) == 0)
				return dir_iterator_abort(dir_iterator);

			return dir_iterator_advance(dir_iterator);
		}
	}

	if (is_dot_or_dotdot(dir_entry->d_name))
		return dir_iterator_advance(dir_iterator);

	/*
	 * Successfully read entry from current directory level.
	 */

	expose_err = expose_entry(iter, dir_entry->d_name);

	if (expose_err == FAIL_NOT_ENOENT && PEDANTIC)
		goto error_out;

	if (expose_err == OK)
		push_level(iter);

	if (expose_err != OK)
		return dir_iterator_advance(dir_iterator);

	return ITER_OK;

error_out:
	dir_iterator_abort(dir_iterator);
	return ITER_ERROR;
}

int dir_iterator_abort(struct dir_iterator *dir_iterator)
{
	struct dir_iterator_int *iter = (struct dir_iterator_int *)dir_iterator;

	for (; iter->levels_nr; iter->levels_nr--) {
		struct dir_iterator_level *level =
			&iter->levels[iter->levels_nr - 1];

		if (level->dir && closedir(level->dir)) {
			int saved_errno = errno;
			strbuf_setlen(&iter->base.path, level->prefix_len);
			errno = saved_errno;
			warning_errno("error closing directory '%s'",
				      iter->base.path.buf);
		}
	}

	free(iter->levels);
	strbuf_release(&iter->base.path);
	free(iter);
	return ITER_DONE;
}

struct dir_iterator *dir_iterator_begin(const char *path, unsigned int flags)
{
	struct dir_iterator_int *iter = xcalloc(1, sizeof(*iter));
	struct dir_iterator *dir_iterator = &iter->base;
	int saved_errno;

	strbuf_init(&iter->base.path, PATH_MAX);
	strbuf_addstr(&iter->base.path, path);
	/* expose_entry() appends dir seperator before exposing an entry */
	strbuf_trim_trailing_dir_sep(&iter->base.path);

	ALLOC_GROW(iter->levels, 10, iter->levels_alloc);
	iter->levels_nr = 0;
	iter->flags = flags;

	/*
	 * Note: stat already checks for NULL or empty strings and
	 * inexistent paths.
	 */
	if (stat(iter->base.path.buf, &iter->base.st) < 0) {
		saved_errno = errno;
		goto error_out;
	}

	if (!S_ISDIR(iter->base.st.st_mode)) {
		saved_errno = ENOTDIR;
		goto error_out;
	}

	if (!push_level(iter)) {
		saved_errno = ENOTDIR;
		goto error_out;
	}

	if (activate_level(iter) != OK) {
		saved_errno = errno;
		goto error_out;
	}

	return dir_iterator;

error_out:
	dir_iterator_abort(dir_iterator);
	errno = saved_errno;
	return NULL;
}
