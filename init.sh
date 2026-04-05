#!/system/bin/sh

# =============================
# 🔥 BASE PATH
# =============================
FILES_DIR="/data/user/0/com.rootfs.android/files"
ALPINE_DIR="$FILES_DIR/alpine"
BIN_DIR="$FILES_DIR/bin"
LIB_DIR="$FILES_DIR/lib"

mkdir -p "$ALPINE_DIR" "$BIN_DIR" "$LIB_DIR"

# =============================
# 🔥 ENV (DARI JAVA)
# =============================

export PATH="/system/bin:/system/xbin:$BIN_DIR:/sbin:/vendor/bin"

export HOME="/root"
export TERM="xterm-256color"
export LANG="C.UTF-8"
export COLORTERM="truecolor"

export BIN="$BIN_DIR"
export PREFIX="$FILES_DIR"

# TMP
TMPDIR="$FILES_DIR/tmp"
mkdir -p "$TMPDIR"
export TMPDIR="$TMPDIR"

# PROOT TMP
PROOT_TMP_DIR="$TMPDIR/proot"
mkdir -p "$PROOT_TMP_DIR"
export PROOT_TMP_DIR

# LIB FIX
export LD_LIBRARY_PATH="$LIB_DIR:/system/lib64:/system/lib"

# LINKER FIX
if [ -f "/system/bin/linker64" ]; then
    LINKER="/system/bin/linker64"
else
    LINKER="/system/bin/linker"
fi
export LINKER

# APP INFO
export PKG="com.rootfs.android"
export PKG_PATH="/data/app/com.rootfs.android/base.apk"
export NATIVE_LIB_DIR="/data/app/~~0Tn4vBdxW8FT4LdF__Ideg==/com.rootfs.android-rDSqyUiIVOZPixdhSG-wyA==/lib/arm64"

export DEBUG="false"

# =============================
# 🔥 PROOT LOADER
# =============================

if [ -f "$NATIVE_LIB_DIR/libproot-loader.so" ]; then
    export PROOT_LOADER="$NATIVE_LIB_DIR/libproot-loader.so"
fi



# SECCOMP (optional)
# export SECCOMP=1

# =============================
# 🔥 EXTRACT ROOTFS
# =============================
if [ -z "$(ls -A "$ALPINE_DIR" 2>/dev/null)" ]; then
    echo "[*] Extract rootfs..."
    tar -xzf "$FILES_DIR/alpine.tar.gz" -C "$ALPINE_DIR"
fi

# =============================
# 🔥 COPY PROOT
# =============================
if [ ! -f "$BIN_DIR/proot" ]; then
    cp "$FILES_DIR/proot" "$BIN_DIR/proot"
    chmod 755 "$BIN_DIR/proot"
fi

# =============================
# 🔥 COPY LIB
# =============================
for sofile in "$FILES_DIR/"*.so*; do
    dest="$LIB_DIR/$(basename "$sofile")"
    if [ ! -f "$dest" ]; then
        cp "$sofile" "$dest"
        chmod 644 "$dest"
    fi
done

# =============================
# 🔥 PROOT ARGS
# =============================
ARGS="--kill-on-exit"
ARGS="$ARGS -w /root"

ARGS="$ARGS -b /dev"
ARGS="$ARGS -b /proc"
ARGS="$ARGS -b /sys"
ARGS="$ARGS -b /sdcard"
ARGS="$ARGS -b /storage"
ARGS="$ARGS -b /data"

# STDIO FIX
ARGS="$ARGS -b /proc/self/fd:/dev/fd"
ARGS="$ARGS -b /proc/self/fd/0:/dev/stdin"
ARGS="$ARGS -b /proc/self/fd/1:/dev/stdout"
ARGS="$ARGS -b /proc/self/fd/2:/dev/stderr"

# SHM FIX
mkdir -p "$ALPINE_DIR/tmp"
chmod 1777 "$ALPINE_DIR/tmp"
ARGS="$ARGS -b $ALPINE_DIR/tmp:/dev/shm"

# ROOTFS
ARGS="$ARGS -r $ALPINE_DIR"
ARGS="$ARGS -0"
ARGS="$ARGS --link2symlink"
ARGS="$ARGS --sysvipc"

echo "[*] Starting Alpine..."

# =============================
# 🔥 EXEC PROOT + LOADER
# =============================
exec $LINKER "$BIN_DIR/proot" $ARGS /bin/sh -l
