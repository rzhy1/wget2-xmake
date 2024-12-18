-- wget2 build script for Windows environment
-- Author: rzhy1
-- 2024/6/30

local posix = require("posix") -- POSIX 库，用于操作系统命令
local os = require("os")

local PREFIX = "x86_64-w64-mingw32"
local INSTALLDIR = os.getenv("HOME") .. "/usr/local/" .. PREFIX
local PKG_CONFIG_PATH = INSTALLDIR .. "/lib/pkgconfig:/usr/" .. PREFIX .. "/lib/pkgconfig"
local PKG_CONFIG_LIBDIR = INSTALLDIR .. "/lib/pkgconfig"
local PKG_CONFIG = "/usr/bin/" .. PREFIX .. "-pkg-config"
local CPPFLAGS = "-I" .. INSTALLDIR .. "/include"
local LDFLAGS = "-L" .. INSTALLDIR .. "/lib"
local CFLAGS = "-O2 -g"
local WINEPATH = INSTALLDIR .. "/bin;" .. INSTALLDIR .. "/lib;/usr/" .. PREFIX .. "/bin;/usr/" .. PREFIX .. "/lib"

-- 创建安装目录
posix.mkdir(INSTALLDIR)

local function run_command(cmd)
    local success, reason, code = os.execute(cmd)
    if not success then
        error("Command failed: " .. cmd .. "\nReason: " .. tostring(reason) .. ", Exit code: " .. tostring(code))
    end
end

local function build_xz()
    print(string.format("⭐⭐⭐⭐⭐⭐%s - build xz⭐⭐⭐⭐⭐⭐", os.date('%Y/%m/%d %a %H:%M:%S.%N')))
    local start_time = os.clock()
    run_command("sudo apt-get purge xz-utils")
    run_command("git clone -j$(nproc) https://github.com/tukaani-project/xz.git")
    posix.chdir("xz")
    posix.mkdir("build")
    posix.chdir("build")
    run_command("sudo cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=Release -DXZ_NLS=ON -DBUILD_SHARED_LIBS=OFF")
    run_command("sudo cmake --build . -- -j$(nproc)")
    run_command("sudo cmake --install .")
    run_command("xz --version")
    posix.chdir("../..")
    run_command("rm -rf xz")
    local end_time = os.clock()
    local duration = string.format("%.1f", end_time - start_time)
    local duration_file = io.open(INSTALLDIR .. "/xz_duration.txt", "w")
    duration_file:write(duration)
    duration_file:close()
end

local function build_wget2()
    print(string.format("⭐⭐⭐⭐⭐⭐%s - build wget2⭐⭐⭐⭐⭐⭐", os.date('%Y/%m/%d %a %H:%M:%S.%N')))
    local start_time = os.clock()
    run_command("git clone -j$(nproc) https://github.com/rockdaboot/wget2.git")
    posix.chdir("wget2")
    run_command("./bootstrap --skip-po")
    run_command("export LDFLAGS='-Wl,-Bstatic,--whole-archive -lwinpthread -Wl,--no-whole-archive'")
    run_command("export CFLAGS='-O2 -g'")
    run_command("./configure --host=" .. PREFIX .. " --prefix=" .. INSTALLDIR)
    run_command("make -j$(nproc)")
    run_command("make install")
    run_command("wget2 --version")
    posix.chdir("..")
    run_command("rm -rf wget2")
    local end_time = os.clock()
    local duration = string.format("%.1f", end_time - start_time)
    local duration_file = io.open(INSTALLDIR .. "/wget2_duration.txt", "w")
    duration_file:write(duration)
    duration_file:close()
end

-- 调用所有构建函数
build_xz()
-- build_zstd()
-- build_zlib_ng()
-- build_gmp()
-- 等等...
build_wget2()
