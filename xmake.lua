#!/bin/bash
# wget2 build script for Windows environment
# Author: rzhy1
# 2024/6/30

# 设置环境变量
export PREFIX="x86_64-w64-mingw32"
export INSTALLDIR="$HOME/usr/local/$PREFIX"
export PKG_CONFIG_PATH="$INSTALLDIR/lib/pkgconfig:/usr/$PREFIX/lib/pkgconfig"
export PKG_CONFIG_LIBDIR="$INSTALLDIR/lib/pkgconfig"
export PKG_CONFIG="/usr/bin/${PREFIX}-pkg-config"
export CPPFLAGS="-I$INSTALLDIR/include"
export LDFLAGS="-L$INSTALLDIR/lib"
export CFLAGS="-O2 -g"
export WINEPATH="$INSTALLDIR/bin;$INSTALLDIR/lib;/usr/$PREFIX/bin;/usr/$PREFIX/lib"

mkdir -p $INSTALLDIR
cd $INSTALLDIR

build_xz() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build xz⭐⭐⭐⭐⭐⭐" 
  local start_time=$(date +%s.%N)
  sudo apt-get purge xz-utils
  git clone -j$(nproc) https://github.com/tukaani-project/xz.git || { echo "Git clone failed"; exit 1; }
  cd xz || { echo "cd xz failed"; exit 1; }
  mkdir build
  cd build
  sudo cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=Release -DXZ_NLS=ON -DBUILD_SHARED_LIBS=OFF || { echo "CMake failed"; exit 1; }
  sudo cmake --build . -- -j$(nproc) || { echo "Build failed"; exit 1; }
  sudo cmake --install . || { echo "Install failed"; exit 1; }
  xz --version
  cd ../.. && rm -rf xz
  local end_time=$(date +%s.%N)
  local duration=$(echo "$end_time - $start_time" | bc | xargs printf "%.1f")
  echo "$duration" > "$INSTALLDIR/xz_duration.txt"
}

build_zstd() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build zstd⭐⭐⭐⭐⭐⭐" 
  local start_time=$(date +%s.%N)
  # 创建 Python 虚拟环境并安装meson
  python3 -m venv /tmp/venv
  source /tmp/venv/bin/activate
  pip3 install meson pytest

  # 编译 zstd
  git clone -j$(nproc) https://github.com/facebook/zstd.git || exit 1
  cd zstd || exit 1
  LDFLAGS=-static \
  meson setup \
    --cross-file=${GITHUB_WORKSPACE}/cross_file.txt \
    --backend=ninja \
    --prefix=$INSTALLDIR \
    --libdir=$INSTALLDIR/lib \
    --bindir=$INSTALLDIR/bin \
    --pkg-config-path="$INSTALLDIR/lib/pkgconfig" \
    -Dbin_programs=true \
    -Dstatic_runtime=true \
    -Ddefault_library=static \
    -Db_lto=true --optimization=2 \
    build/meson builddir-st || exit 1
  sudo rm -f /usr/local/bin/zstd*
  sudo rm -f /usr/local/bin/*zstd
  meson compile -C builddir-st || exit 1
  meson install -C builddir-st || exit 1
  zstd --version
  cd .. && rm -rf zstd
  local end_time=$(date +%s.%N)
  local duration=$(echo "$end_time - $start_time" | bc | xargs printf "%.1f")
  echo "$duration" > "$INSTALLDIR/zstd_duration.txt"
}

# 省略部分函数内容（build_zlib-ng, build_gmp 等与前述相同）...

build_wget2() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build wget2⭐⭐⭐⭐⭐⭐" 
  local start_time=$(date +%s.%N)
  git clone -j$(nproc) https://github.com/rockdaboot/wget2.git || exit 1
  cd wget2 || exit 1
  ./bootstrap --skip-po || exit 1
  export LDFLAGS="-Wl,-Bstatic,--whole-archive -lwinpthread -Wl,--no-whole-archive"
  export CFLAGS="-O2 -g"
  ./configure --host=$PREFIX --prefix=$INSTALLDIR || exit 1
  make -j$(nproc) || exit 1
  make install || exit 1
  wget2 --version
  cd .. && rm -rf wget2
  local end_time=$(date +%s.%N)
  local duration=$(echo "$end_time - $start_time" | bc | xargs printf "%.1f")
  echo "$duration" > "$INSTALLDIR/wget2_duration.txt"
}

# 调用所有构建函数
build_xz
build_zstd
build_zlib-ng
build_gmp
build_gnulibmirror
build_libiconv
build_libunistring
build_libidn2
build_libtasn1
build_PCRE2
build_nghttp2
build_dlfcn-win32
build_libmicrohttpd
build_libpsl
build_nettle
build_gnutls
build_wget2
