#!/bin/bash
qemu-system-x86_64 -drive file=bootable_iso.iso,media=disk,if=virtio,format=raw -m 512 -enable-kvm -audiodev pa,id=pa,server=unix:${XDG_RUNTIME_DIR}/pulse/native,out.stream-name=foobar2,in.stream-name=foobar2 -device intel-hda -device hda-duplex,audiodev=pa,mixer=off 
