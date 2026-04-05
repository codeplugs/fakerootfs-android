FILES_DIR="/data/user/0/com.rootfs.android/files"
ALPINE_DIR="$FILES_DIR/alpine"
BIN_DIR="$FILES_DIR/bin"
LIB_DIR="$FILES_DIR/lib"

mkdir -p "$ALPINE_DIR" "$BIN_DIR" "$LIB_DIR"

# 🔥 Extract rootfs (kalau belum)
if [ -z "$(ls -A "$ALPINE_DIR" 2>/dev/null)" ]; then
    tar -xzf "$FILES_DIR/alpine.tar.gz" -C "$ALPINE_DIR"
fi

# 🔥 Copy proot
if [ ! -f "$BIN_DIR/proot" ]; then
    cp "$FILES_DIR/proot" "$BIN_DIR/proot"
    chmod 755 "$BIN_DIR/proot"
fi

# 🔥 Copy libtalloc
for sofile in "$FILES_DIR/"*.so.2; do
    dest="$LIB_DIR/$(basename "$sofile")"
    if [ ! -f "$dest" ]; then
        cp "$sofile" "$dest"
        chmod 644 "$dest"
    fi
done

# 🔥 FIX: linker + LD_LIBRARY_PATH
LINKER="/system/bin/linker64"
export LD_LIBRARY_PATH="$LIB_DIR:/system/lib64:/system/lib"

# 🔥 ARGS proot
ARGS="--kill-on-exit"
ARGS="$ARGS -w /root"

# bind penting Android
ARGS="$ARGS -b /dev"
ARGS="$ARGS -b /proc"
ARGS="$ARGS -b /sys"
ARGS="$ARGS -b /sdcard"
ARGS="$ARGS -b /storage"
ARGS="$ARGS -b /data"

# stdin stdout fix
ARGS="$ARGS -b /proc/self/fd:/dev/fd"
ARGS="$ARGS -b /proc/self/fd/0:/dev/stdin"
ARGS="$ARGS -b /proc/self/fd/1:/dev/stdout"
ARGS="$ARGS -b /proc/self/fd/2:/dev/stderr"

# tmp
mkdir -p "$ALPINE_DIR/tmp"
chmod 1777 "$ALPINE_DIR/tmp"
ARGS="$ARGS -b $ALPINE_DIR/tmp:/dev/shm"

# rootfs
ARGS="$ARGS -r $ALPINE_DIR"
ARGS="$ARGS -0"
ARGS="$ARGS --link2symlink"
ARGS="$ARGS --sysvipc"

# 🔥 RUN alpine langsung sh
exec $LINKER "$BIN_DIR/proot" $ARGS /bin/sh
