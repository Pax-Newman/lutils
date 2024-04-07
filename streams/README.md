
# Streams

This module provides a simple and fast api for processing arrays, strings, and functions as streams.
Streams are lazily evaluated, so they can be useful in situations where you don't necessarily want to process everything at once.

## Usage

```lua
local stream = require("lutils").streams

local arr_stream = stream { 1, 2, 3, 4, 5 }

local str_stream = stream "Hey I'm a stream now!"

local i = 0
local limit = 100
local fun_stream = stream(function()
    i = i + 1
    if i < limit then
        return i
    else
        return nil
    end
end)

```

After creating a string you can start processing the stream.

```lua

local fizzbuzz = stream { 1, 2, 3, 4, 5 }
   :map(function(val)
      local result = ""
      if val % 3 == 0 then
         result = result .. "fizz"
      end
      if val % 5 == 0 then
         result = result .. "buzz"
      end
      return val
   end)
   :reduce(function(acc, val)
      return acc .. "\n" .. val
   end)

```

We can also use streams in loops

```lua

local str = stream "Hello World!"
   :filter(function(char)
      if string.gmatch("aeiou", char) then
         return false
      end
      return true
   end)

for char in str:iter() do
   print(char)
end

-- Prints out:
-- H
-- l
-- l
-- 
-- W
-- r
-- l
-- d
-- !
```

