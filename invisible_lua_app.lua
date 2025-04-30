-- invisible_lua_app.lua
-- Lua script to hide process, mask root environment, simulate virtual environment, and add stealth features

local ffi = require("ffi")
local bit = require("bit")

-- FFI declarations for Linux prctl and setproctitle
ffi.cdef[[
int prctl(int option, unsigned long arg2, unsigned long arg3, unsigned long arg4, unsigned long arg5);
int setproctitle(const char *title);
]]

local PR_SET_NAME = 15

-- Function to set process name (visible in ps, top, etc)
local function set_process_name(name)
    -- Try prctl first
    local res = ffi.C.prctl(PR_SET_NAME, ffi.cast("unsigned long", ffi.cast("const char *", name)), 0, 0, 0)
    if res ~= 0 then
        -- fallback: try setproctitle if available
        if ffi.C.setproctitle then
            ffi.C.setproctitle(name)
        end
    end
end

-- Set process name to innocuous string
set_process_name("systemd")  -- common system process name to blend in

-- Override os.getenv to hide root-related environment variables and simulate virtual env
local original_getenv = os.getenv
local fake_env = {
    USER = "user",
    LOGNAME = "user",
    HOME = "/home/user",
    VIRTUAL_ENV = "/home/user/.virtualenvs/fakeenv",
    PATH = "/home/user/.virtualenvs/fakeenv/bin:" .. (original_getenv("PATH") or ""),
    -- Mask root indicators
    SUDO_USER = nil,
    SUDO_UID = nil,
    SUDO_GID = nil,
    USERNAME = "user",
    -- Add other env vars as needed
}

os.getenv = function(key)
    if fake_env[key] ~= nil then
        return fake_env[key]
    else
        return original_getenv(key)
    end
end

-- Modify package paths to simulate virtual environment
local fake_venv_path = "/home/user/.virtualenvs/fakeenv/lib/lua/5.1/?.lua;/home/user/.virtualenvs/fakeenv/lib/lua/5.1/?/init.lua;"
package.path = fake_venv_path .. package.path
package.cpath = "/home/user/.virtualenvs/fakeenv/lib/lua/5.1/?.so;" .. package.cpath

-- Hook debug.getinfo to hide this script's internals
local original_getinfo = debug.getinfo
debug.getinfo = function(thread, f, what)
    if type(thread) == "number" or type(thread) == "string" then
        what = f
        f = thread
        thread = nil
    end
    local info = original_getinfo(thread, f, what)
    if info and info.source and info.source:match("invisible_lua_app.lua") then
        return nil -- hide info about this script
    end
    return info
end

-- Self-monitoring: simple watchdog to restart if killed (dummy example)
local function watchdog()
    while true do
        -- In real scenario, check if process is alive or fork a child to monitor
        -- Here just sleep to simulate
        os.execute("sleep 60")
    end
end

-- Start watchdog in coroutine
local co = coroutine.create(watchdog)
coroutine.resume(co)

-- Function to toggle invisibility dynamically
local invisible = true
local function toggle_invisibility()
    if invisible then
        set_process_name("systemd")
        invisible = false
    else
        set_process_name("invisible_lua_app")
        invisible = true
    end
end

-- Mask file system traces by cleaning temp files (dummy example)
local function clean_temp_files()
    os.execute("rm -rf /tmp/invisible_lua_app_*")
end

-- Main app logic (dummy loop)
local function main()
    clean_temp_files()
    while true do
        -- Your app code here
        -- For demo, just sleep
        os.execute("sleep 10")
    end
end

main()
