#ifndef DIR_ITERATOR_H
#define DIR_ITERATOR_H

#include "strbuf.h"

/*
 * Iterate over a directory tree.
 *
 * Iterate over a directory tree, recursively, including paths of all
 * types and hidden paths. Skip "." and ".." entries and don't follow
 * symlinks except when DIR_ITERATOR_FOLLOW_SYMLINKS is set.
 * Note that the original path is not included in the iteration.
 *
 * Every time dir_iterator_advance() is called, update the members of
 * the dir_iterator structure to reflect the next path in the
 * iteration. The order that paths are iterated over within a
 * directory is undefined. Directory paths are given before
 * their contents when DIR_ITERATOR_DIRS_BEFORE is set and after when
 * DIR_ITERATOR_DIRS_AFTER is set. Failure to set any of them results
 * in directories themselves not being exposed. Instead, only their
 * contents will be exposed.
 *
 * A typical iteration looks like this:
 *
 *     int ok;
 *     unsigned int flags = DIR_ITERATOR_PEDANTIC | DIR_ITERATOR_DIRS_BEFORE;
 *     struct dir_iterator *iter = dir_iterator_begin(path, flags);
 *
 *     if (!iter)
 *             goto error_handler;
 *
 *     while ((ok = dir_iterator_advance(iter)) == ITER_OK) {
 *             if (want_to_stop_iteration()) {
 *                     ok = dir_iterator_abort(iter);
 *                     break;
 *             }
 *
 *             // Access information about the current path:
 *             if (S_ISDIR(iter->st.st_mode))
 *                     printf("%s is a directory\n", iter->relative_path);
 *     }
 *
 *     if (ok != ITER_DONE)
 *             handle_error();
 *
 * Callers are allowed to modify iter->path while they are working,
 * but they must restore it to its original contents before calling
 * dir_iterator_advance() again.
 */

/*
 * Flags for dir_iterator_begin:
 *
 * - DIR_ITERATOR_PEDANTIC: override dir-iterator's default behavior
 *   in case of an error at dir_iterator_advance(), which is to keep
 *   looking for a next valid entry. With this flag, resources are freed
 *   and ITER_ERROR is returned immediately. In both cases, a meaningful
 *   warning is emitted. Note: ENOENT errors are always ignored so that
 *   the API users may remove files during iteration.
 *
 * - DIR_ITERATOR_FOLLOW_SYMLINKS: make dir-iterator follow symlinks.
 *   i.e., linked directories' contents will be iterated over and
 *   iter->base.st will contain information on the referred files,
 *   not the symlinks themselves, which is the default behavior. Broken
 *   symlinks are ignored.
 *
 * - DIR_ITERATOR_DIRS_BEFORE: make dir-iterator expose a directory path
 *   before iterating through that directory's contents.
 *
 * - DIR_ITERATOR_DIRS_AFTER: make dir-iterator expose a directory path after
 *   iterating through that directory's contents.
 *
 * Note: any combination of DIR_ITERATOR_BEFORE and DIR_ITERATOR_AFTER works.
 * Activating both of them will expose directories when descending into one and
 * when it's been exhausted. Activating none will iterate through directories'
 * contents but won't expose the directories themselves.
 *
 * Warning: circular symlinks are also followed when
 * DIR_ITERATOR_FOLLOW_SYMLINKS is set. The iteration may end up with
 * an ELOOP if they happen and DIR_ITERATOR_PEDANTIC is set.
 */
#define DIR_ITERATOR_PEDANTIC (1 << 0)
#define DIR_ITERATOR_FOLLOW_SYMLINKS (1 << 1)
#define DIR_ITERATOR_DIRS_BEFORE (1 << 2)
#define DIR_ITERATOR_DIRS_AFTER (1 << 3)

struct dir_iterator {
	/* The current path: */
	struct strbuf path;

	/*
	 * The current path relative to the starting path. This part
	 * of the path always uses "/" characters to separate path
	 * components:
	 */
	const char *relative_path;

	/* The current basename: */
	const char *basename;

	/*
	 * The result of calling lstat() on path; or stat(), if the
	 * DIR_ITERATOR_FOLLOW_SYMLINKS flag was set at
	 * dir_iterator's initialization.
	 */
	struct stat st;
};

/*
 * Start a directory iteration over path with the combination of
 * options specified by flags. On success, return a dir_iterator
 * that holds the internal state of the iteration. In case of
 * failure, return NULL and set errno accordingly.
 *
 * The iteration includes all paths under path, not including path
 * itself, "." or ".." entries and directories according to specified flags.
 *
 * Parameters are:
 *  - path is the starting directory. An internal copy will be made.
 *  - flags is a combination of the possible flags to initialize a
 *    dir-iterator or 0 for default behavior which will ignore directory
 *    paths, but will include the rest directory contents.
 */
struct dir_iterator *dir_iterator_begin(const char *path, unsigned int flags);

/*
 * Advance the iterator to the first or next item and return ITER_OK.
 * If the iteration is exhausted, free the dir_iterator and any
 * resources associated with it and return ITER_DONE.
 * On error, free dir_iterator memory and return ITER_ERROR.
 *
 * It is a bug to use iterator or call this function again after it
 * has returned ITER_DONE or ITER_ERROR (which may be returned iff
 * the DIR_ITERATOR_PEDANTIC flag was set).
 */
int dir_iterator_advance(struct dir_iterator *iterator);

/*
 * End the iteration before it has been exhausted. Free the
 * dir_iterator and any associated resources and return ITER_DONE.
 */
int dir_iterator_abort(struct dir_iterator *iterator);

#endif
