
# IterTools

This module provides tools for using Lua arrays with chainable iteration functions.

Currently IterTools provides the following functions:

 - `map`
 - `filter`
 - `reduce`
 - `fold`

## Usage

To use itertools functions, use `it` to attach the methods to any table

```lua
local it = require("lutils").itertools

local arr = it {} -- Here we attach the itertools functions to the table with the `it` function
for i = 1, 100 do
   table.insert(arr, i)
end

local conditions = it { { val = 3, str = "fizz" }, { val = 5, str = "buzz" } }

-- Now we can chain together functions easily!

local result = arr:map(function(_, val)
   local res = conditions:fold("", function(acc, _, cond)
      if val % cond.val == 0 then
         return acc .. cond.str
      end
      return acc
   end)
   if res == "" then
      return val
   end
   return res
end):reduce(function(acc, _, val)
   return acc .. "\n" .. val
end)

print(result)
```

