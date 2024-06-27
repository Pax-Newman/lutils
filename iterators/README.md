
# Iterators

A simple module for creating pull-iterators using strings, arrays, and functions.

## Usage

Creating an iterator is pretty simple. Just use `iter`!

```lua

local iter = require("lutils").iterators

local arr_iter = iter {1, 2, 3}

local str_iter = iter "Hello there"

local i = -1
local fun_iter = iter(function()
   i = i + 1
   if i <= 100 then
      return i
   else
      return nil
   end
)

```

Now you can call `:filter`, `:map`, and `:reduce` on your iterators.

