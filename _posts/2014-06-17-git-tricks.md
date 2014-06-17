---
layout: post
title: "GIT tricks"
date: "2014-06-17 19:30:12"
categories: git
abstract: "This is a small but useful collection of not so often needed git commands also acting as my personal memory aid."
---

Git is a super powerful source code management system that allows to to pretty handy things. This posts is a list of some useful git commands that I use from time to time. But since I don't use them very often I always forget about them again. So this post also acts as my personal memory aid.

### Replace a password in the whole git history

The `filter-branch --tree-filter` allows you to iterate over all commits in all branches and execute an arbitrary unix command. This example replaces the string `originalpassword` with the string `newpassword` in all files in all commits in all branches.

~~~ bash
$ git filter-branch --tree-filter "find . -type f -exec sed -i -e 's/originalpassword/newpassword/g' {} \;"
~~~

### Copy a repository completely to a new destination

If you want to completely copy a remote repository to another remote location (for example from your custom server to GitHub), then you can use the `push --mirror` command to ensure that all refs and therefor all branches and tags are transfered.

~~~ bash
$ git clone --bare https://git.mydomain.com/myrepo.git
$ cd myrepo
$ git push --mirror https://github.com/myaccount/mynewrepo.git
$ cd ..
$ rm -rf myrepo.git
~~~

### Change the author

~~~ bash
$ git filter-branch --commit-filter '
    if [ "$GIT_COMMITTER_NAME" = "alexbeta" ];
    then
      GIT_COMMITTER_NAME="Alex Beta";
      GIT_AUTHOR_NAME="Alex Beta";
      GIT_COMMITTER_EMAIL="alex.beta@invalid.domain.tld";
      GIT_AUTHOR_EMAIL="alex.beta@invalid.domain.tld";
      git commit-tree "$@";
    else
      git commit-tree "$@";
    fi' -- --all
~~~

### Remove certain files

When there is the need to complete wipe some files from the repository history (for example because a secret file has been commited or to cleanup a converterted SVN repository) then the following commands can be used:

~~~ bash
# folder temp/
$ git filter-branch \
    --tree-filter 'rm -rf temp \;' \
    --prune-empty \
    --tag-name-filter cat \
    -- --all

# all files ending with .class extension
$ git filter-branch \
    --tree-filter 'find . -iname *.class -type f -exec rm {} \;' \
    --prune-empty \
    --tag-name-filter cat \
    -- --all
~~~

### To be continued...

I will update this post from time to time when I again stumple upon some useful commands.
