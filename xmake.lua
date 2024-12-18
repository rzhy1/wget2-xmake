-- xmake.lua
add_requires("cmake >= 3.16.0", "meson >= 1.2.0")

-- 设置环境变量
local prefix = "x86_64-w64-mingw32"
local installdir = path.join(os.getenv("HOME"), "usr", "local", prefix)
local pkg_config_path = path.join(installdir, "lib", "pkgconfig") .. ":" .. path.join("/usr", prefix, "lib", "pkgconfig")
local pkg_config_libdir = path.join(installdir, "lib", "pkgconfig")
local pkg_config = path.join("/usr", "bin", prefix .. "-pkg-config")
local cppflags = "-I" .. path.join(installdir, "include")
local ldflags = "-L" .. path.join(installdir, "lib")
local cflags = "-O2 -g"
local winepath = path.join(installdir, "bin") .. ";" .. path.join(installdir, "lib") .. ";" .. path.join("/usr", prefix, "bin") .. ";" .. path.join("/usr", prefix, "lib")

os.mkdir(installdir)  -- 这里已经修复了
os.cd(installdir)   -- 这里也修复了

function get_duration_str(start_time)
    local end_time = os.time() + os.difftime()
    local duration = string.format("%.1f", end_time - start_time)
    return duration
end

function build_xz()
  print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build xz⭐⭐⭐⭐⭐⭐")
  local start_time = os.time() + os.difftime()
    os.execv({"sudo", "apt-get", "purge", "xz-utils"})
  os.execv({"git", "clone", "-j" .. tostring(os.nproc()), "https://github.com/tukaani-project/xz.git"})
  os.cd("xz")
  os.mkdir("build")
  os.cd("build")
    os.execv({"sudo", "cmake", "..", "-DCMAKE_INSTALL_PREFIX=/usr/local", "-DCMAKE_BUILD_TYPE=Release", "-DXZ_NLS=ON", "-DBUILD_SHARED_LIBS=OFF"})
    os.execv({"sudo", "cmake", "--build", ".", "--", "-j" .. tostring(os.nproc())})
    os.execv({"sudo", "cmake", "--install", "."})
    os.execv({"xz", "--version"})
  os.cd("../..")
  os.rmdir("xz")
  local duration = get_duration_str(start_time)
  io.writefile(path.join(installdir, "xz_duration.txt"), duration)
end

function build_zstd()
  print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build zstd⭐⭐⭐⭐⭐⭐")
  local start_time = os.time() + os.difftime()
  -- 创建 Python 虚拟环境并安装meson
  os.execv({"python3", "-m", "venv", "/tmp/venv"})
  os.execv({"source", "/tmp/venv/bin/activate"})
  os.execv({"pip3", "install", "meson", "pytest"})

  -- 编译 zstd
  os.execv({"git", "clone", "-j" .. tostring(os.nproc()), "https://github.com/facebook/zstd.git"})
  os.cd("zstd")
  os.setenv("LDFLAGS", "-static")
  os.execv({"meson", "setup",
        "--cross-file=" .. path.join(os.getenv("GITHUB_WORKSPACE"), "cross_file.txt"),
        "--backend=ninja",
        "--prefix=" .. installdir,
        "--libdir=" .. path.join(installdir, "lib"),
        "--bindir=" .. path.join(installdir, "bin"),
        "--pkg-config-path=" .. path.join(installdir, "lib", "pkgconfig"),
        "-Dbin_programs=true",
        "-Dstatic_runtime=true",
        "-Ddefault_library=static",
        "-Db_lto=true", "--optimization=2",
        "build/meson", "builddir-st"})

  os.execv({"sudo", "rm", "-f", "/usr/local/bin/zstd*"})
    os.execv({"sudo", "rm", "-f", "/usr/local/bin/*zstd"})
    os.execv({"meson", "compile", "-C", "builddir-st"})
    os.execv({"meson", "install", "-C", "builddir-st"})
    os.execv({"zstd", "--version"})
  os.cd("..")
    os.rmdir("zstd")

  local duration = get_duration_str(start_time)
  io.writefile(path.join(installdir, "zstd_duration.txt"), duration)
end

function build_zlib_ng()
  print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build zlib-ng⭐⭐⭐⭐⭐⭐")
  local start_time = os.time() + os.difftime()
  os.execv({"git", "clone", "-j" .. tostring(os.nproc()), "https://github.com/zlib-ng/zlib-ng"})
    os.cd("zlib-ng")
    os.setenv("CROSS_PREFIX", "x86_64-w64-mingw32-")
    os.setenv("ARCH", "x86_64")
    os.setenv("CFLAGS", "-O2")
    os.setenv("CC", "x86_64-w64-mingw32-gcc")
    os.execv({"./configure", "--prefix=" .. installdir, "--static", "--64", "--zlib-compat"})
    os.execv({"make", "-j" .. tostring(os.nproc())})
    os.execv({"make", "install"})
    os.cd("..")
    os.rmdir("zlib-ng")
  local duration = get_duration_str(start_time)
  io.writefile(path.join(installdir, "zlib-ng_duration.txt"), duration)
end

function build_gmp()
  print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build gmp⭐⭐⭐⭐⭐⭐")
  local start_time = os.time() + os.difftime()
  os.execv({"wget", "-nv", "-O-", "https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz", "|", "tar", "x", "--xz"})
    local gmp_dir = "gmp-" .. string.match("gmp-6.3.0.tar.xz", "gmp%-(%d+%.%d+%.%d+)")
  os.cd(gmp_dir)
    os.execv({"./configure", "--host=" .. prefix, "--disable-shared", "--prefix=" .. installdir})
    os.execv({"make", "-j" .. tostring(os.nproc())})
    os.execv({"make", "install"})
   os.cd("..")
    os.rmdir(gmp_dir)
  local duration = get_duration_str(start_time)
  io.writefile(path.join(installdir, "gmp_duration.txt"), duration)
end

function build_gnulibmirror()
  print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build gnulib-mirror⭐⭐⭐⭐⭐⭐")
    local start_time = os.time() + os.difftime()
  os.execv({"git", "clone", "--recursive", "-j" .. tostring(os.nproc()), "https://gitlab.com/gnuwget/gnulib-mirror.git", "gnulib"})
  os.setenv("GNULIB_REFDIR", path.join(installdir, "gnulib"))
  local duration = get_duration_str(start_time)
    io.writefile(path.join(installdir, "gnulibmirror_duration.txt"), duration)
end

function build_libiconv()
  print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build libiconv⭐⭐⭐⭐⭐⭐")
  local start_time = os.time() + os.difftime()
  os.execv({"wget", "-O-", "https://ftp.gnu.org/gnu/libiconv/libiconv-1.18.tar.gz", "|", "tar", "xz"})
   local libiconv_dir = "libiconv-" .. string.match("libiconv-1.18.tar.gz", "libiconv%-(%d+%.%d+)")
  os.cd(libiconv_dir)
    os.execv({"./configure", "--build=x86_64-pc-linux-gnu", "--host=" .. prefix, "--disable-shared", "--enable-static", "--prefix=" .. installdir})
    os.execv({"make", "-j" .. tostring(os.nproc())})
    os.execv({"make", "install"})
    os.cd("..")
    os.rmdir(libiconv_dir)
  local duration = get_duration_str(start_time)
    io.writefile(path.join(installdir, "libiconv_duration.txt"), duration)
end

function build_libunistring()
    print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build libunistring⭐⭐⭐⭐⭐⭐")
    local start_time = os.time() + os.difftime()
    os.execv({"wget", "-O-", "https://ftp.gnu.org/gnu/libunistring/libunistring-1.3.tar.gz", "|", "tar", "xz"})
     local libunistring_dir = "libunistring-" .. string.match("libunistring-1.3.tar.gz", "libunistring%-(%d+%.%d+)")
    os.cd(libunistring_dir)
    os.execv({"./configure", "CFLAGS=-O2", "--build=x86_64-pc-linux-gnu", "--host=" .. prefix, "--prefix=" .. installdir, "--disable-shared", "--enable-static"})
    os.execv({"make", "-j" .. tostring(os.nproc())})
    os.execv({"make", "install"})
    os.cd("..")
    os.rmdir(libunistring_dir)
  local duration = get_duration_str(start_time)
    io.writefile(path.join(installdir, "libunistring_duration.txt"), duration)
end

function build_libidn2()
  print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build libidn2⭐⭐⭐⭐⭐⭐")
  local start_time = os.time() + os.difftime()
    os.execv({"wget", "-O-", "https://ftp.gnu.org/gnu/libidn/libidn2-2.3.7.tar.gz", "|", "tar", "xz"})
    local libidn2_dir = "libidn2-" .. string.match("libidn2-2.3.7.tar.gz", "libidn2%-(%d+%.%d+%.%d+)")
    os.cd(libidn2_dir)
    os.execv({"./configure", "--build=x86_64-pc-linux-gnu", "--host=" .. prefix, "--disable-shared", "--enable-static", "--with-included-unistring", "--disable-doc", "--disable-gcc-warnings", "--prefix=" .. installdir})
    os.execv({"make", "-j" .. tostring(os.nproc())})
    os.execv({"make", "install"})
   os.cd("..")
    os.rmdir(libidn2_dir)
  local duration = get_duration_str(start_time)
    io.writefile(path.join(installdir, "libidn2_duration.txt"), duration)
end

function build_libtasn1()
  print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build libtasn1⭐⭐⭐⭐⭐⭐")
  local start_time = os.time() + os.difftime()
  os.execv({"wget", "-O-", "https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.19.0.tar.gz", "|", "tar", "xz"})
  local libtasn1_dir = "libtasn1-" .. string.match("libtasn1-4.19.0.tar.gz", "libtasn1%-(%d+%.%d+%.%d+)")
  os.cd(libtasn1_dir)
    os.execv({"./configure", "--host=" .. prefix, "--disable-shared", "--disable-doc", "--prefix=" .. installdir})
    os.execv({"make", "-j" .. tostring(os.nproc())})
    os.execv({"make", "install"})
   os.cd("..")
    os.rmdir(libtasn1_dir)
  local duration = get_duration_str(start_time)
    io.writefile(path.join(installdir, "libtasn1_duration.txt"), duration)
end

function build_PCRE2()
  print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build PCRE2⭐⭐⭐⭐⭐⭐")
    local start_time = os.time() + os.difftime()
    os.execv({"git", "clone", "-j" .. tostring(os.nproc()), "https://github.com/PCRE2Project/pcre2"})
    os.cd("pcre2")
    os.execv({"./autogen.sh"})
    os.execv({"./configure", "--host=" .. prefix, "--prefix=" .. installdir, "--disable-shared", "--enable-static"})
    os.execv({"make", "-j" .. tostring(os.nproc())})
    os.execv({"make", "install"})
   os.cd("..")
    os.rmdir("pcre2")
  local duration = get_duration_str(start_time)
    io.writefile(path.join(installdir, "pcre2_duration.txt"), duration)
end

function build_nghttp2()
  print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build nghttp2⭐⭐⭐⭐⭐⭐")
  local start_time = os.time() + os.difftime()
  os.execv({"wget", "-O-", "https://github.com/nghttp2/nghttp2/releases/download/v1.64.0/nghttp2-1.64.0.tar.gz", "|", "tar", "xz"})
    local nghttp2_dir = "nghttp2-" .. string.match("nghttp2-1.64.0.tar.gz", "nghttp2%-(%d+%.%d+%.%d+)")
  os.cd(nghttp2_dir)
    os.execv({"./configure", "--build=x86_64-pc-linux-gnu", "--host=" .. prefix, "--prefix=" .. installdir, "--disable-shared", "--enable-static", "--disable-python-bindings", "--disable-examples", "--disable-app", "--disable-failmalloc", "--disable-hpack-tools"})
    os.execv({"make", "-j" .. tostring(os.nproc())})
    os.execv({"make", "install"})
   os.cd("..")
    os.rmdir(nghttp2_dir)
  local duration = get_duration_str(start_time)
    io.writefile(path.join(installdir, "nghttp2_duration.txt"), duration)
end

function build_dlfcn_win32()
  print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build dlfcn-win32⭐⭐⭐⭐⭐⭐")
  local start_time = os.time() + os.difftime()
    os.execv({"git", "clone", "-j" .. tostring(os.nproc()), "https://github.com/dlfcn-win32/dlfcn-win32.git"})
    os.cd("dlfcn-win32")
    os.execv({"./configure", "--prefix=" .. prefix, "--cc=" .. prefix .. "-gcc"})
    os.execv({"make", "-j" .. tostring(os.nproc())})
    os.execv({"cp", "-p", "libdl.a", path.join(installdir, "lib")})
    os.execv({"cp", "-p", "src/dlfcn.h", path.join(installdir, "include")})
    os.cd("..")
    os.rmdir("dlfcn-win32")
  local duration = get_duration_str(start_time)
    io.writefile(path.join(installdir, "dlfcn-win32_duration.txt"), duration)
end

function build_libmicrohttpd()
  print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build libmicrohttpd⭐⭐⭐⭐⭐⭐")
  local start_time = os.time() + os.difftime()
    os.execv({"wget", "-O-", "https://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-latest.tar.gz", "|", "tar", "xz"})
    local libmicrohttpd_dir = "libmicrohttpd-" .. string.match("libmicrohttpd-latest.tar.gz", "libmicrohttpd%-(%d+%.%d+)")
    os.cd(libmicrohttpd_dir)
    os.execv({"./configure", "--build=x86_64-pc-linux-gnu", "--host=" .. prefix, "--prefix=" .. installdir, "--disable-shared", "--enable-static",
            "--disable-examples", "--disable-doc", "--disable-tools"})
    os.execv({"make", "-j" .. tostring(os.nproc())})
    os.execv({"make", "install"})
    os.cd("..")
    os.rmdir(libmicrohttpd_dir)
  local duration = get_duration_str(start_time)
    io.writefile(path.join(installdir, "libmicrohttpd_duration.txt"), duration)
end

function build_libpsl()
  print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build libpsl⭐⭐⭐⭐⭐⭐")
  local start_time = os.time() + os.difftime()
  os.execv({"git", "clone", "-j" .. tostring(os.nproc()), "--recursive", "https://github.com/rockdaboot/libpsl.git"})
    os.cd("libpsl")
    os.execv({"./autogen.sh"})
    os.execv({"./configure", "--build=x86_64-pc-linux-gnu", "--host=" .. prefix, "--disable-shared", "--enable-static", "--enable-runtime=libidn2", "--enable-builtin", "--with-included-unistring", "--prefix=" .. installdir})
    os.execv({"make", "-j" .. tostring(os.nproc())})
    os.execv({"make", "install"})
    os.cd("..")
    os.rmdir("libpsl")
  local duration = get_duration_str(start_time)
    io.writefile(path.join(installdir, "libpsl_duration.txt"), duration)
end

function build_nettle()
  print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build nettle⭐⭐⭐⭐⭐⭐")
  local start_time = os.time() + os.difftime()
  os.execv({"git", "clone", "-j" .. tostring(os.nproc()), "https://github.com/sailfishos-mirror/nettle.git"})
    os.cd("nettle")
    os.execv({"bash", ".bootstrap"})
    os.execv({"./configure", "--build=x86_64-pc-linux-gnu", "--host=" .. prefix, "--enable-mini-gmp", "--disable-shared", "--enable-static", "--disable-documentation", "--prefix=" .. installdir})
    os.execv({"make", "-j" .. tostring(os.nproc())})
    os.execv({"make", "install"})
    os.cd("..")
    os.rmdir("nettle")
  local duration = get_duration_str(start_time)
    io.writefile(path.join(installdir, "nettle_duration.txt"), duration)
end

function build_gnutls()
    print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build gnutls⭐⭐⭐⭐⭐⭐")
  local start_time = os.time() + os.difftime()
  os.execv({"wget", "-O-", "https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/gnutls-3.8.8.tar.xz", "|", "tar", "x", "--xz"})
  local gnutls_dir = "gnutls-" .. string.match("gnutls-3.8.8.tar.xz", "gnutls%-(%d+%.%d+%.%d+)")
  os.cd(gnutls_dir)
    os.setenv("GMP_LIBS", "-L" .. path.join(installdir, "lib") .. " -lgmp")
    os.setenv("NETTLE_LIBS", "-L" .. path.join(installdir, "lib") .. " -lnettle -lgmp")
    os.setenv("HOGWEED_LIBS", "-L" .. path.join(installdir, "lib") .. " -lhogweed -lnettle -lgmp")
    os.setenv("LIBTASN1_LIBS", "-L" .. path.join(installdir, "lib") .. " -ltasn1")
    os.setenv("LIBIDN2_LIBS", "-L" .. path.join(installdir, "lib") .. " -lidn2")
    os.setenv("GMP_CFLAGS", cflags)
    os.setenv("LIBTASN1_CFLAGS", cflags)
    os.setenv("NETTLE_CFLAGS", cflags)
    os.setenv("HOGWEED_CFLAGS", cflags)
    os.setenv("LIBIDN2_CFLAGS", cflags)
    os.execv({"./configure", "CFLAGS=-O2", "--host=" .. prefix, "--prefix=" .. installdir, "--with-included-libtasn1", "--with-included-unistring", "--disable-openssl-compatibility", "--disable-hardware-acceleration", "--disable-shared", "--enable-static", "--without-p11-kit", "--disable-doc", "--disable-tests", "--disable-full-test-suite", "--disable-tools", "--disable-cxx", "--disable-maintainer-mode", "--disable-libdane"})
    os.execv({"make", "-j" .. tostring(os.nproc())})
    os.execv({"make", "install"})
    os.cd("..")
    os.rmdir(gnutls_dir)
  local duration = get_duration_str(start_time)
    io.writefile(path.join(installdir, "gnutls_duration.txt"), duration)
end

function build_wget2()
  print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build wget2⭐⭐⭐⭐⭐⭐")
  local start_time = os.time() + os.difftime()
  os.execv({"git", "clone", "-j" .. tostring(os.nproc()), "https://github.com/rockdaboot/wget2.git"})
    os.cd("wget2")
    os.execv({"./bootstrap", "--skip-po"})
    os.setenv("LDFLAGS", "-Wl,-Bstatic,--whole-archive -lwinpthread -Wl,--no-whole-archive")
    os.setenv("CFLAGS", "-O2 -DNGHTTP2_STATICLIB")
    os.setenv("GNUTLS_CFLAGS", cflags)
    os.setenv("GNUTLS_LIBS", "-L" .. path.join(installdir, "lib") .. " -lgnutls -lbcrypt -lncrypt")
    os.setenv("LIBPSL_CFLAGS", cflags)
    os.setenv("LIBPSL_LIBS", "-L" .. path.join(installdir, "lib") .. " -lpsl")
    os.setenv("PCRE2_CFLAGS", cflags)
    os.setenv("PCRE2_LIBS", "-L" .. path.join(installdir, "lib") .. " -lpcre2-8")
    os.execv({"./configure", "--build=x86_64-pc-linux-gnu", "--host=" .. prefix, "--with-libiconv-prefix=" .. installdir, "--with-ssl=gnutls", "--disable-shared", "--enable-static", "--with-lzma", "--with-zstd", "--without-bzip2", "--without-lzip", "--without-brotlidec", "--without-gpgme", "--enable-threads=windows"})
    os.execv({"make", "-j" .. tostring(os.nproc())})
    os.execv({"strip", path.join(installdir, "wget2", "src", "wget2.exe")})
    os.execv({"cp", "-fv", path.join(installdir, "wget2", "src", "wget2.exe"), os.getenv("GITHUB_WORKSPACE")})
    os.cd("..")
  local duration = get_duration_str(start_time)
    io.writefile(path.join(installdir, "wget2_duration.txt"), duration)
end


build_zstd()
build_zlib_ng()
build_gmp()

local p = {}
table.insert(p, function() build_libiconv() end)
table.insert(p, function() build_libidn2() end)
table.insert(p, function() build_libtasn1() end)
xmake.task.runv(p)


local p = {}
table.insert(p, function() build_PCRE2() end)
table.insert(p, function() build_nghttp2() end)
table.insert(p, function() build_libmicrohttpd() end)
table.insert(p, function() build_libunistring() end)
xmake.task.runv(p)



build_libpsl()
build_nettle()
build_gnutls()
build_wget2()


-- 读取并输出编译时间
--local duration1 = io.readfile(path.join(installdir, "xz_duration.txt"))
local duration2 = io.readfile(path.join(installdir, "zstd_duration.txt"))
local duration3 = io.readfile(path.join(installdir, "zlib-ng_duration.txt"))
local duration4 = io.readfile(path.join(installdir, "gmp_duration.txt"))
--local duration5 = io.readfile(path.join(installdir, "gnulibmirror_duration.txt"))
local duration6 = io.readfile(path.join(installdir, "libiconv_duration.txt"))
local duration7 = io.readfile(path.join(installdir, "libunistring_duration.txt"))
local duration8 = io.readfile(path.join(installdir, "libidn2_duration.txt"))
local duration9 = io.readfile(path.join(installdir, "libtasn1_duration.txt"))
local duration10 = io.readfile(path.join(installdir, "pcre2_duration.txt"))
local duration11 = io.readfile(path.join(installdir, "nghttp2_duration.txt"))
--local duration12 = io.readfile(path.join(installdir, "dlfcn-win32_duration.txt"))
local duration13 = io.readfile(path.join(installdir, "libmicrohttpd_duration.txt"))
local duration14 = io.readfile(path.join(installdir, "libpsl_duration.txt"))
local duration15 = io.readfile(path.join(installdir, "nettle_duration.txt"))
local duration16 = io.readfile(path.join(installdir, "gnutls_duration.txt"))
local duration17 = io.readfile(path.join(installdir, "wget2_duration.txt"))

-- print("编译 xz 用时：" .. duration1 .. "s")
print("编译 zstd 用时：" .. duration2 .. "s")
print("编译 zlib-ng 用时：" .. duration3 .. "s")
print("编译 gmp 用时：" .. duration4 .. "s")
-- print("编译 gnulibmirror 用时：" .. duration5 .. "s")
print("编译 libiconv 用时：" .. duration6 .. "s")
print("编译 libunistring 用时：" .. duration7 .. "s")
print("编译 libidn2 用时：" .. duration8 .. "s")
print("编译 libtasn1 用时：" .. duration9 .. "s")
print("编译 PCRE2 用时：" .. duration10 .. "s")
print("编译 nghttp2 用时：" .. duration11 .. "s")
-- print("编译 dlfcn-win32 用时：" .. duration12 .. "s")
print("编译 libmicrohttpd 用时：" .. duration13 .. "s")
print("编译 libpsl 用时：" .. duration14 .. "s")
print("编译 nettle 用时：" .. duration15 .. "s")
print("编译 gnutls 用时：" .. duration16 .. "s")
print("编译 wget2 用时：" .. duration17 .. "s")
