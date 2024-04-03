
# Function Environment

This is a small, simple module that provides tools for getting and setting `_ENV` for functions, allowing you to run functions in custom environments.

## Usage

This module provides two functions `setfenv` and `getfenv`. `setfenv` lets us specify a table of values for the function to run with

```lua
local fenv = require("lutils").fenv

function runtime()
    local a = 2
    local b = 5
    print("Got: ", a + b)
end

function logger(...)
    local stamp = string.format("[%s]", os.date("%X"))
    local logf = io.open("bean.log", "a")

    local out = stamp .. " " .. table.concat(..., " ")
    logf:write(out)
    print(out)
end

runtime() --> 5

fenv.setfenv(runtime, { print = logger })

runtime() --> "[15:32:56] Got: 5"
```

Keep in mind that `setfenv` completely overwrites `_ENV`. If there's anything in the global scope we want to keep we could also utilize `getfenv`.

```lua
-- ...

local function add_logger(fn)
   local log_env = { print = logger }
   local fn_env = fenv.getfenv(fn)

   for key, value in pairs(fn_env) do
      log_env[key] = log_env[key] or value
   end

   return fenv.setfenv(fn, log_env)
end

add_logger(runtime)
```

Using `setfenv` and `getfenv` together we can overwrite and add parts of a function's environment while leaving the rest intact!

## Credits

This module is entirely based on this great [blog post](https://leafo.net/guides/setfenv-in-lua52-and-above.html) by [Leafo](https://github.com/leafo)

