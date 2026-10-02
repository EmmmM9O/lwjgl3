set_project("lwjgl")
set_languages("c11")

local NDK = get_config("ndk")

local LIBFFI_VER = "3.8.0"
local API = 24

local LWJGL = path.join(os.projectdir(), "modules/lwjgl")
local LWJGL_CORE = path.join(LWJGL, "core")

local ABI = get_config("abi") or "arm64-v8a"

local LIBFFI_BUILD_DIR = path.join(os.projectdir(), "libffi-build", ABI)

local function ensure_libffi() end

target("lwjgl")
do
	set_kind("shared")

	add_files(path.join(LWJGL_CORE, "src/generated/c/*.c"))
	add_files(path.join(LWJGL_CORE, "src/generated/c/**.c"))
	remove_files(path.join(LWJGL_CORE, "src/generated/c/windows/*.c"))
	remove_files(path.join(LWJGL_CORE, "src/generated/c/macos/*.c"))
	remove_files(path.join(LWJGL_CORE, "src/generated/c/freebsd/*.c"))
	remove_files(path.join(LWJGL_CORE, "src/generated/c/liburing/*.c"))
	remove_files(path.join(LWJGL_CORE, "src/generated/c/UIO/*.c"))
	remove_files(path.join(LWJGL_CORE, "src/generated/c/**/*UIO*"))
	remove_files(path.join(LWJGL_CORE, "src/generated/c/**/*liburing*"))

	add_files(path.join(LWJGL_CORE, "src/main/c/*.c"))
	add_files(path.join(LWJGL_CORE, "src/main/c/**.c"))
	remove_files(path.join(LWJGL_CORE, "src/main/c/**/liburing/*.c"))

	add_includedirs(
		path.join(LWJGL_CORE, "src/main/c"),
		path.join(LWJGL_CORE, "src/main/c/linux"),
		path.join(LWJGL_CORE, "src/main/c/libffi"),
		path.join(LWJGL_CORE, "src/generated/c/linux"),
		path.join(LIBFFI_BUILD_DIR, "include")
	)

	add_files(path.join(LWJGL, "opengles/src/generated/c/*.c"))

	add_includedirs(
		path.join(LWJGL, "opengles/src/main/c")
	)

	add_files(path.join(LWJGL, "stb/src/generated/c/*.c"))

	add_includedirs(
		path.join(LWJGL, "stb/src/main/c")
	)

	set_targetdir("$(builddir)/android/arm64/org/lwjgl")

	add_defines("LWJGL_LINUX")
	add_linkdirs(path.join(LIBFFI_BUILD_DIR, ".libs"))
	add_links("ffi", "dl")
	before_build(function(target)
		local src = path.join(os.projectdir(), "libffi-" .. LIBFFI_VER)
		if not os.isdir(src) then
			local tarball = "libffi-" .. LIBFFI_VER .. ".tar.gz"
			local url = "https://gh-proxy.com/https://github.com/libffi/libffi/releases/download/v"
					.. LIBFFI_VER
					.. "/"
					.. tarball
			os.execv("wget", { url, "-O", path.join(os.projectdir(), tarball) })
			os.execv("tar", { "xf", path.join(os.projectdir(), tarball), "-C", os.projectdir() })
		end
		if os.isdir(LIBFFI_BUILD_DIR) and os.isfile(path.join(LIBFFI_BUILD_DIR, ".libs/libffi.a")) then
			return
		end

		local host_map = {
			["arm64-v8a"] = "aarch64-linux-android",
			["armeabi-v7a"] = "armv7a-linux-androideabi",
			["x86_64"] = "x86_64-linux-android",
			["x86"] = "i686-linux-android",
		}
		local host = host_map[ABI] or "aarch64-linux-android"
		local toolchain = path.join(NDK, "toolchains/llvm/prebuilt/linux-x86_64")
		local cc = path.join(toolchain, "bin", host .. API .. "-clang")

		os.mkdir(LIBFFI_BUILD_DIR)
		local olddir = os.cd(LIBFFI_BUILD_DIR)
		os.execv(path.join(src, "configure"), {
			"--host=" .. host,
			"--disable-shared",
			"--enable-static",
			"--with-sysroot=" .. path.join(toolchain, "sysroot"),
			"CC=" .. cc,
			"AR=" .. path.join(toolchain, "bin/llvm-ar"),
			"RANLIB=" .. path.join(toolchain, "bin/llvm-ranlib"),
		})
		os.execv("make", { "-j" .. os.cpuinfo().ncpu })
		os.cd(olddir)
	end)
end

--[[
target("lwjgl_opengl")
do
	set_kind("shared")

	add_files(path.join(LWJGL, "opengl/src/generated/c/*.c"))
	add_files(path.join(LWJGL, "opengl/src/generated/c/**/*.c"))
	remove_files(path.join(LWJGL, "opengl/src/generated/c/*WGL*.c"))
	remove_files(path.join(LWJGL, "opengl/src/generated/c/*GLX*.c"))
	remove_files(path.join(LWJGL, "opengl/src/generated/c/*CGL*.c"))

	add_includedirs(
		path.join(LWJGL_CORE, "src/main/c"),
		path.join(LWJGL_CORE, "src/main/c/linux"),
		path.join(LWJGL, "opengl/src/main/c")
	)
	add_defines("LWJGL_LINUX")
	add_deps("lwjgl")
end]]
