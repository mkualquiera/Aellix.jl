# == KERNEL STUFF == 

linux-6.3.1.tar.xz:
	wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.3.1.tar.xz

linux-6.3.1: linux-6.3.1.tar.xz
	tar xf linux-6.3.1.tar.xz

linux-6.3.1/.config: linux-6.3.1
	cp linux-config linux-6.3.1/.config

# Utils for quality of life
linux-config: linux-6.3.1/.config
	cp linux-6.3.1/.config linux-config

$menuconfig: 
	make -C linux-6.3.1 menuconfig
	cp linux-6.3.1/.config linux-config

$clean-kernel:
	rm -rf linux-6.3.1 linux-6.3.1.tar.xz

linux-6.3.1/arch/x86/boot/bzImage: linux-6.3.1/.config linux-6.3.1
	cd linux-6.3.1 && make -j8

# == GLIBC STUFF ==

glibc-2.37.tar.gz:
	wget https://ftp.gnu.org/gnu/glibc/glibc-2.37.tar.gz

glibc-2.37: glibc-2.37.tar.gz
	tar xf glibc-2.37.tar.gz

glibc-build: glibc-2.37 
	mkdir -p glibc-build
	cd glibc-build && ../glibc-2.37/configure --prefix=$(pwd)/../usr && make -j8

$clean-glibc:
	rm -rf glibc-2.37 glibc-2.37.tar.gz glibc-build

julia:
	git clone https://github.com/JuliaLang/julia.git
	cd julia && git checkout v1.8.5 && make -j8 prefix=$(pwd)/../usr JULIA_CPU_TARGET=generic

$clean-julia:
	rm -rf julia

# == INIT ==

init/bootstrap: init/bootstrap.c
	cd init && gcc -static -o bootstrap bootstrap.c

$clean-init:
	rm -rf init/bootstrap

# == BOOTABLE ISO DIR ==

usr: glibc-build julia
	cd glibc-build && make install
	cd julia && make install prefix=$(pwd)/../usr JULIA_CPU_TARGET=generic

$clean-usr:
	rm -rf usr

bootable_iso: init/bootstrap linux-6.3.1/arch/x86/boot/bzImage usr ^workspace
	rm -rf bootable_iso
	mkdir -p bootable_iso/bin
	cp -a workspace/. bootable_iso
	cp linux-6.3.1/arch/x86/boot/bzImage bootable_iso/boot/bzImage
	cp init/bootstrap bootable_iso/bin/bootstrap
	cp -a usr bootable_iso
	cd bootable_iso && ln -s usr/lib lib64

bootable_iso.iso: bootable_iso
	grub-mkrescue -o bootable_iso.iso bootable_iso

$all: bootable_iso.iso

$run: 
	./run.sh

$clean: $clean-init $clean-kernel $clean-glibc $clean-julia $clean-usr
