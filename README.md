# Aellix

An operating system written in Julia. (Technically it's just the userland, the 
kernel is Linux.)

# Building

Building this requires my own "make" implementation, which is written in rust. 
You can install it like so:

```bash
cargo install --git https://github.com/mkualquiera/mk.git
```

Do make sure your cargo bin directory is in your PATH.

You must also have the grub-mkrescue command, which comes with grub2. 
Then, you can build the iso like so

```bash
mk
```

This will pull in the Linux kernel, the glibc source code, the julia source
code, and build it all. It will then create a directory that represents the 
root of the iso, and copy the built files into it, as well as the ``workspace``
directory, which contains all of the Julia things. Finally, it will create an
iso image from that directory.

You can then run it using 

```bash
mk run
```

# Hacking 

Feel free to mess with all the things in the ``workspace`` directory. Some particularly
interesting things are:

* ``workspace/etc/init.d``: Any Julia files you put here will be run on startup.

* ``workspace/lib``: Contains system libraries written in Julia. This includes the
shell (Aell) as well as the text editor (Acorn) and other things.

* ``workspace/boot/grub.cfg``: Contains the grub configuration. You can customize 
the colors and the kernel command line here.