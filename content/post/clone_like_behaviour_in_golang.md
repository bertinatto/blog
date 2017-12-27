---
title: "Fork-like behaviour in Go"
date: 2017-12-27T09:06:40+01:00
draft: false
---

Recently, I have been looking into how to implement Linux Namespaces in Go.

In C, the way we isolate a process in certain Namespaces is by specifying them in the `tags` parameter of `clone(2)`. For instance, `user_namespaces(7)` provides the following example to illustrate this.

{{< highlight c >}}
(...)

while ((opt = getopt(argc, argv, "+imnpuUM:G:zv")) != -1) {
        switch (opt) {
        case 'i': flags |= CLONE_NEWIPC;        break;
        case 'm': flags |= CLONE_NEWNS;         break;
        case 'n': flags |= CLONE_NEWNET;        break;
        case 'p': flags |= CLONE_NEWPID;        break;
        case 'u': flags |= CLONE_NEWUTS;        break;
        case 'v': verbose = 1;                  break;
        case 'z': map_zero = 1;                 break;
        case 'M': uid_map = optarg;             break;
        case 'G': gid_map = optarg;             break;
        case 'U': flags |= CLONE_NEWUSER;       break;
        default:  usage(argv[0]);
        }
    }

(...)

/* Create the child in new namespace(s) */

child_pid = clone(childFunc, child_stack + STACK_SIZE,
                 flags | SIGCHLD, &args);
if (child_pid == -1)
   errExit("clone");

(...)
{{< /highlight >}}

## The problem

Everything looks well and good, so I wanted to do the same in Go. However, I soon found out that `fork(2)` (i.e., `clone(2)`) isn't the right way to do so. The problem lies on the fact that `fork(2)` creates the new child by copying **only** the main thread of execution. Even if a Go program is single-threaded, under the hood there might be many other threads executing in the Go runtime. As a result, `fork(2)` isn't really a nice way of creating a child process in Go.

## Possible workarounds

The first solution that comes to mind is to use the `os/exec` package. Plus, with this package it's possible to define the Namespaces of the child process by setting the attributes of the command:

{{< highlight go >}}
c := exec.Command("ls", "-l")
c.SysProcAttr = syscall.SysProcAttr{
    Cloneflats: syscall.CLONE_NEWIPC,
}
if err := c.Run(); err != nil {
    (...)
{{< /highlight >}}

Everything looks great, but if a process call itself, wouldn't the resulting process call itself again? Wouldn't I get into an infinite loop?

When I came accross this problem I promply split my program into two: a parent and a child. The former would simply call the latter with the appropriate flags set.  However, for practical reasons, I wanted to have all my code in a single program, so I started looking for alternatives.

Another possible solution would have been to have different arguments in the command to alternate between parent and child. For example, when executed, `program` would start in parent mode and then it would call itself by doing `program child`. That sounded a bit sloppy for me, though. For exampmle, what if the user call `program child` directly?

## My choice

I wondered how [Moby](https://github.com/moby/moby) addresses this issue, so looking at its codebase I found the `reexec` package that does exactly what I wanted.

The solution is very interesting. First, to call itself a process could simple execute `/proc/self/exe`, which is a in-memory representation of the process. Because of that, it's OK to overwrite the command's arguments, including `os.Args[0]`. No harm will be made, as the executable is not read from the disk.

With that in mind, it's possible to re-execute a Go program by doing:

{{< highlight go >}}
c := exec.Cmd{
    Path: "/proc/self/exe",
    Args: []string{"child"},
    (...)
}
if err := c.Run(); err != nil {
    (...)
}
{{< /highlight >}}

And in `main()` we can check if the program running was re-executed by doing someting like this:

{{< highlight go >}}
func main() {
	switch os.Args[0] {
    case "parent":
        (...)
    case "child":
        (...)
     }
{{< /highlight >}}

Yes, that's right! We overwrote `os.Args[0]`!

Again, this was only possible because we are executing `/proc/self/exe` instead of loading the executable from disk again. The kernel already has open file descriptors for all running processes, so the child process will be based on the in-memory representation of the parent. The executable could even be removed from the disk and the child would still be executed.

This still smells like a hack, but I found it to be a nice way to re-execute a process in Go.
