includes("@builtin/check")
add_rules("mode.debug", "mode.release")

-- 这里我们不需要aria2的依赖，但保留一些常用的
add_requires(
    "zlib"  -- 你可以根据你的需求添加其他依赖
)
set_policy("package.install_only", true)

set_languages("c++14")
set_encodings("utf-8")
set_rundir(".")
add_defines("CXX11_OVERRIDE=override")
set_configdir("$(buildir)/config")
add_includedirs("$(buildir)/config")
if is_plat("windows") then
    add_cxxflags("/EHsc")
end

-- 这里只保留wget2可能需要的头文件
local common_headers = {
    "argz.h",
    "arpa/inet.h",
    "fcntl.h",
    "float.h",
    "inttypes.h",
    "langinfo.h",
    "libintl.h",
    "limits.h",
    "libgen.h",
    "locale.h",
    "malloc.h",
    "math.h",
    "memory.h",
    "netdb.h",
    "netinet/in.h",
    "netinet/tcp.h",
    "poll.h",
    "signal.h",
    "stddef.h",
    "stdint.h",
    "stdio.h",
    "stdlib.h",
    "string.h",
    "strings.h",
    "sys/epoll.h",
    "sys/ioctl.h",
    "sys/mman.h",
    "sys/param.h",
    "sys/stat.h",
    "sys/socket.h",
    "sys/time.h",
    "sys/types.h",
    "unistd.h",
    "ifaddrs.h",
    "pwd.h",
    "pthread.h",
    "getopt.h",
    "windows.h",
    "winsock2.h",
    "ws2tcpip.h",
    {"iphlpapi.h", {"winsock2.h", "windows.h", "ws2tcpip.h", "iphlpapi.h"}},
}

for _, common_header in ipairs(common_headers) do
    local k = common_header
    local v = common_header
    if type(common_header) == 'table' then
        k = common_header[1]
        v = common_header[2]
    end
    local name = 'HAVE_'..k:gsub("/", "_"):gsub("%.", "_"):gsub("-", "_"):upper()
    configvar_check_cincludes(name, v)
end

if is_plat("windows", "mingw") then
    add_defines("_POSIX_C_SOURCE=1")
else
    add_defines("_GNU_SOURCE=1")
    set_configvar("ENABLE_PTHREAD", 1)
end

-- wget2 specific
local PROJECT_NAME = "wget2"
local PROJECT_VERSION = "2.0.0" -- 根据实际情况修改
set_configvar("PACKAGE", PROJECT_NAME)
set_configvar("PACKAGE_NAME", PROJECT_NAME)
set_configvar("PACKAGE_STRING", PROJECT_NAME .. " " .. PROJECT_VERSION)
set_configvar("PACKAGE_TARNAME", PROJECT_NAME)
set_configvar("PACKAGE_VERSION", PROJECT_VERSION)
set_configvar("VERSION", PROJECT_VERSION)

-- 设置交叉编译工具链和安装目录
local prefix = "x86_64-w64-mingw32"
local installdir = path.join(os.getenv("HOME"), "usr", "local", prefix)
local pkg_config_path = path.join(installdir, "lib", "pkgconfig") .. ":" .. path.join("/usr", prefix, "lib", "pkgconfig")
local pkg_config_libdir = path.join(installdir, "lib", "pkgconfig")
local pkg_config = path.join("/usr", "bin", prefix .. "-pkg-config")
local cppflags = "-I" .. path.join(installdir, "include")
local ldflags = "-L" .. path.join(installdir, "lib")
local cflags = "-O2 -g"
local winepath = path.join(installdir, "bin") .. ";" .. path.join(installdir, "lib") .. ";" .. path.join("/usr", prefix, "bin") .. ";" .. path.join("/usr", prefix, "lib")

-- Helper function to get duration string
local function get_duration_str(start_time)
    local end_time = os.time() + os.difftime()
    local duration = string.format("%.1f", end_time - start_time)
    return duration
end

target("wget2")
    set_kind("$(kind)")

    -- 添加编译依赖的逻辑
    on_load(function(target)
        -- 设置环境变量
        os.setenv("PKG_CONFIG_PATH", pkg_config_path)
        os.setenv("PKG_CONFIG_LIBDIR", pkg_config_libdir)
        os.setenv("PKG_CONFIG", pkg_config)
        os.setenv("CPPFLAGS", cppflags)
        os.setenv("LDFLAGS", ldflags)
        os.setenv("CFLAGS", cflags)
        os.setenv("WINEPATH", winepath)

        -- 创建安装目录，如果不存在
        if not os.isdir(installdir) then
            xmake.os.mkdir(installdir)
            xmake.os.cd(installdir)

            local start_time = os.time() + os.difftime()

            -- 安装 zlib-ng
            print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build zlib-ng⭐⭐⭐⭐⭐⭐")
            start_time = os.time() + os.difftime()
            os.execv({"git", "clone", "-j" .. tostring(os.nproc()), "https://github.com/zlib-ng/zlib-ng"})
            xmake.os.cd("zlib-ng")
            os.setenv("CROSS_PREFIX", "x86_64-w64-mingw32-")
            os.setenv("ARCH", "x86_64")
            os.setenv("CFLAGS", "-O2")
            os.setenv("CC", "x86_64-w64-mingw32-gcc")
            os.execv({"./configure", "--prefix=" .. installdir, "--static", "--64", "--zlib-compat"})
            os.execv({"make", "-j" .. tostring(os.nproc())})
            os.execv({"make", "install"})
            xmake.os.cd("..")
            xmake.os.rmdir("zlib-ng")
            local duration = get_duration_str(start_time)
            io.writefile(path.join(installdir, "zlib-ng_duration.txt"), duration)

            -- 安装 libiconv
            print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build libiconv⭐⭐⭐⭐⭐⭐")
            start_time = os.time() + os.difftime()
            os.execv({"wget", "-O-", "https://ftp.gnu.org/gnu/libiconv/libiconv-1.18.tar.gz", "|", "tar", "xz"})
            local libiconv_dir = "libiconv-" .. string.match("libiconv-1.18.tar.gz", "libiconv%-(%d+%.%d+)")
            xmake.os.cd(libiconv_dir)
            os.execv({"./configure", "--build=x86_64-pc-linux-gnu", "--host=" .. prefix, "--disable-shared", "--enable-static", "--prefix=" .. installdir})
            os.execv({"make", "-j" .. tostring(os.nproc())})
            os.execv({"make", "install"})
            xmake.os.cd("..")
            xmake.os.rmdir(libiconv_dir)
            duration = get_duration_str(start_time)
            io.writefile(path.join(installdir, "libiconv_duration.txt"), duration)

            -- 安装 libunistring
            print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build libunistring⭐⭐⭐⭐⭐⭐")
            start_time = os.time() + os.difftime()
            os.execv({"wget", "-O-", "https://ftp.gnu.org/gnu/libunistring/libunistring-1.3.tar.gz", "|", "tar", "xz"})
            local libunistring_dir = "libunistring-" .. string.match("libunistring-1.3.tar.gz", "libunistring%-(%d+%.%d+)")
            xmake.os.cd(libunistring_dir)
            os.execv({"./configure", "CFLAGS=-O2", "--build=x86_64-pc-linux-gnu", "--host=" .. prefix, "--prefix=" .. installdir, "--disable-shared", "--enable-static"})
            os.execv({"make", "-j" .. tostring(os.nproc())})
            os.execv({"make", "install"})
            xmake.os.cd("..")
            xmake.os.rmdir(libunistring_dir)
            duration = get_duration_str(start_time)
            io.writefile(path.join(installdir, "libunistring_duration.txt"), duration)

            -- 安装 libidn2
            print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build libidn2⭐⭐⭐⭐⭐⭐")
            start_time = os.time() + os.difftime()
            os.execv({"wget", "-O-", "https://ftp.gnu.org/gnu/libidn/libidn2-2.3.7.tar.gz", "|", "tar", "xz"})
            local libidn2_dir = "libidn2-" .. string.match("libidn2-2.3.7.tar.gz", "libidn2%-(%d+%.%d+%.%d+)")
            xmake.os.cd(libidn2_dir)
            os.execv({"./configure", "--build=x86_64-pc-linux-gnu", "--host=" .. prefix, "--disable-shared", "--enable-static", "--with-included-unistring", "--disable-doc", "--disable-gcc-warnings", "--prefix=" .. installdir})
            os.execv({"make", "-j" .. tostring(os.nproc())})
            os.execv({"make", "install"})
            xmake.os.cd("..")
            xmake.os.rmdir(libidn2_dir)
            duration = get_duration_str(start_time)
            io.writefile(path.join(installdir, "libidn2_duration.txt"), duration)

           -- 安装 libtasn1
            print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build libtasn1⭐⭐⭐⭐⭐⭐")
           start_time = os.time() + os.difftime()
           os.execv({"wget", "-O-", "https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.19.0.tar.gz", "|", "tar", "xz"})
           local libtasn1_dir = "libtasn1-" .. string.match("libtasn1-4.19.0.tar.gz", "libtasn1%-(%d+%.%d+%.%d+)")
           xmake.os.cd(libtasn1_dir)
           os.execv({"./configure", "--host=" .. prefix, "--disable-shared", "--disable-doc", "--prefix=" .. installdir})
            os.execv({"make", "-j" .. tostring(os.nproc())})
            os.execv({"make", "install"})
            xmake.os.cd("..")
            xmake.os.rmdir(libtasn1_dir)
            duration = get_duration_str(start_time)
           io.writefile(path.join(installdir, "libtasn1_duration.txt"), duration)

            -- 安装 PCRE2
            print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build PCRE2⭐⭐⭐⭐⭐⭐")
            start_time = os.time() + os.difftime()
            os.execv({"git", "clone", "-j" .. tostring(os.nproc()), "https://github.com/PCRE2Project/pcre2"})
            xmake.os.cd("pcre2")
            os.execv({"./autogen.sh"})
            os.execv({"./configure", "--host=" .. prefix, "--prefix=" .. installdir, "--disable-shared", "--enable-static"})
            os.execv({"make", "-j" .. tostring(os.nproc())})
            os.execv({"make", "install"})
            xmake.os.cd("..")
            xmake.os.rmdir("pcre2")
            duration = get_duration_str(start_time)
           io.writefile(path.join(installdir, "pcre2_duration.txt"), duration)

            -- 安装 nghttp2
            print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build nghttp2⭐⭐⭐⭐⭐⭐")
            start_time = os.time() + os.difftime()
            os.execv({"wget", "-O-", "https://github.com/nghttp2/nghttp2/releases/download/v1.64.0/nghttp2-1.64.0.tar.gz", "|", "tar", "xz"})
            local nghttp2_dir = "nghttp2-" .. string.match("nghttp2-1.64.0.tar.gz", "nghttp2%-(%d+%.%d+%.%d+)")
            xmake.os.cd(nghttp2_dir)
            os.execv({"./configure", "--build=x86_64-pc-linux-gnu", "--host=" .. prefix, "--prefix=" .. installdir, "--disable-shared", "--enable-static", "--disable-python-bindings", "--disable-examples", "--disable-app", "--disable-failmalloc", "--disable-hpack-tools"})
            os.execv({"make", "-j" .. tostring(os.nproc())})
           os.execv({"make", "install"})
            xmake.os.cd("..")
           xmake.os.rmdir(nghttp2_dir)
            duration = get_duration_str(start_time)
           io.writefile(path.join(installdir, "nghttp2_duration.txt"), duration)

           -- 安装 gmp
           print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build gmp⭐⭐⭐⭐⭐⭐")
            start_time = os.time() + os.difftime()
            os.execv({"wget", "-nv", "-O-", "https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz", "|", "tar", "x", "--xz"})
            local gmp_dir = "gmp-" .. string.match("gmp-6.3.0.tar.xz", "gmp%-(%d+%.%d+%.%d+)")
            xmake.os.cd(gmp_dir)
            os.execv({"./configure", "--host=" .. prefix, "--disable-shared", "--prefix=" .. installdir})
            os.execv({"make", "-j" .. tostring(os.nproc())})
            os.execv({"make", "install"})
           xmake.os.cd("..")
          xmake.os.rmdir(gmp_dir)
           duration = get_duration_str(start_time)
            io.writefile(path.join(installdir, "gmp_duration.txt"), duration)

            -- 安装 libpsl
             print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build libpsl⭐⭐⭐⭐⭐⭐")
           start_time = os.time() + os.difftime()
            os.execv({"git", "clone", "-j" .. tostring(os.nproc()), "--recursive", "https://github.com/rockdaboot/libpsl.git"})
           xmake.os.cd("libpsl")
            os.execv({"./autogen.sh"})
            os.execv({"./configure", "--build=x86_64-pc-linux-gnu", "--host=" .. prefix, "--disable-shared", "--enable-static", "--enable-runtime=libidn2", "--enable-builtin", "--with-included-unistring", "--prefix=" .. installdir})
           os.execv({"make", "-j" .. tostring(os.nproc())})
           os.execv({"make", "install"})
           xmake.os.cd("..")
            xmake.os.rmdir("libpsl")
            duration = get_duration_str(start_time)
           io.writefile(path.join(installdir, "libpsl_duration.txt"), duration)

           -- 安装 nettle
            print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build nettle⭐⭐⭐⭐⭐⭐")
            start_time = os.time() + os.difftime()
            os.execv({"git", "clone", "-j" .. tostring(os.nproc()), "https://github.com/sailfishos-mirror/nettle.git"})
           xmake.os.cd("nettle")
            os.execv({"bash", ".bootstrap"})
           os.execv({"./configure", "--build=x86_64-pc-linux-gnu", "--host=" .. prefix, "--enable-mini-gmp", "--disable-shared", "--enable-static", "--disable-documentation", "--prefix=" .. installdir})
           os.execv({"make", "-j" .. tostring(os.nproc())})
           os.execv({"make", "install"})
            xmake.os.cd("..")
           xmake.os.rmdir("nettle")
            duration = get_duration_str(start_time)
            io.writefile(path.join(installdir, "nettle_duration.txt"), duration)

             -- 安装 gnutls
            print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build gnutls⭐⭐⭐⭐⭐⭐")
            start_time = os.time() + os.difftime()
            os.execv({"wget", "-O-", "https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/gnutls-3.8.8.tar.xz", "|", "tar", "x", "--xz"})
           local gnutls_dir = "gnutls-" .. string.match("gnutls-3.8.8.tar.xz", "gnutls%-(%d+%.%d+%.%d+)")
           xmake.os.cd(gnutls_dir)
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
           xmake.os.cd("..")
            xmake.os.rmdir(gnutls_dir)
            duration = get_duration_str(start_time)
           io.writefile(path.join(installdir, "gnutls_duration.txt"), duration)
          end

          -- 安装 wget2
            print("⭐⭐⭐⭐⭐⭐" .. os.date("%Y/%m/%d %a %H:%M:%S") .. " - build wget2⭐⭐⭐⭐⭐⭐")
            start_time = os.time() + os.difftime()
            os.execv({"git", "clone", "-j" .. tostring(os.nproc()), "https://github.com/rockdaboot/wget2.git"})
           xmake.os.cd("wget2")
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
            xmake.os.cd("..")
           duration = get_duration_str(start_time)
            io.writefile(path.join(installdir, "wget2_duration.txt"), duration)

            -- 读取并输出编译时间
            local duration1 = io.readfile(path.join(installdir, "zlib-ng_duration.txt"))
            local duration2 = io.readfile(path.join(installdir, "libiconv_duration.txt"))
            local duration3 = io.readfile(path.join(installdir, "libunistring_duration.txt"))
           local duration4 = io.readfile(path.join(installdir, "libidn2_duration.txt"))
            local duration5 = io.readfile(path.join(installdir, "libtasn1_duration.txt"))
            local duration6 = io.readfile(path.join(installdir, "pcre2_duration.txt"))
           local duration7 = io.readfile(path.join(installdir, "nghttp2_duration.txt"))
           local duration8 = io.readfile(path.join(installdir, "gmp_duration.txt"))
            local duration9 = io.readfile(path.join(installdir, "libpsl_duration.txt"))
            local duration10 = io.readfile(path.join(installdir, "nettle_duration.txt"))
            local duration11 = io.readfile(path.join(installdir, "gnutls_duration.txt"))
           local duration12 = io.readfile(path.join(installdir, "wget2_duration.txt"))

            print("编译 zlib-ng 用时：" .. duration1 .. "s")
            print("编译 libiconv 用时：" .. duration2 .. "s")
            print("编译 libunistring 用时：" .. duration3 .. "s")
            print("编译 libidn2 用时：" .. duration4 .. "s")
           print("编译 libtasn1 用时：" .. duration5 .. "s")
           print("编译 PCRE2 用时：" .. duration6 .. "s")
            print("编译 nghttp2 用时：" .. duration7 .. "s")
             print("编译 gmp 用时：" .. duration8 .. "s")
           print("编译 libpsl 用时：" .. duration9 .. "s")
            print("编译 nettle 用时：" .. duration10 .. "s")
           print("编译 gnutls 用时：" .. duration11 .. "s")
            print("编译 wget2 用时：" .. duration12 .. "s")

            -- 添加链接目录和头文件目录
           target:add("linkdirs", path.join(installdir, "lib"))
            target:add("includedirs", path.join(installdir, "include"))

    end)

    on_config(function (target)
        local variables = target:get("configvar") or {}
        for _, opt in ipairs(target:orderopts()) do
            for name, value in pairs(opt:get("configvar")) do
                if variables[name] == nil then
                    variables[name] = table.unwrap(value)
                    variables["__extraconf_" .. name] = opt:extraconf("configvar." .. name, value)
                end
            end
        end
        local set_configvar = function(k, v)
            if v == nil then
                return
            end
            target:set("configvar", k, v)
            variables[k] = v
        end
        set_configvar("HOST", vformat("$(host)"))
        set_configvar("BUILD", vformat("$(arch)-$(os)"))
        set_configvar("TARGET", vformat("$(arch)-$(os)"))
    end)

    -- 添加 wget2 的源文件和头文件目录
    add_files("src/*.c", "src/*.cc")
    add_includedirs("src")
    add_ldflags(ldflags) -- 添加链接器标志
    if is_plat("windows", "mingw") then
          add_syslinks("ws2_32", "shell32", "iphlpapi")
         add_ldflags("-static")
    end
