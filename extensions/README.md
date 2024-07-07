
# Extensions

A small library for mimicking the `extension` keyword from Swift using Lua's metatables.

## Usage

This simple utility offers just a single function, `extension`.
This let's us extend the capabilities of tables and types in Lua in a simple fashion.

```lua

local extension = require("lutils").extensions

extension {
   -- The object whose metatable we want to extend
   -- This needs to come first
   "",

   -- After that we can add as many extensions as we'd like!

   -- We can extend the object with new metamethods
   __mod = function(self, arr)
      return self:format(table.unpack(arr))
   end,

   -- We can also add new values to the metatable's __index
   has = function(self, target)
      for i in #self - #target do
         if self:sub(i, i + #target) == target then
            return true
         end
      end
      return false
   end,
}

-- Since we modified the string type's metatable,
-- all of our strings will have access to the extensions we defined
local val = "Hello, %s!" % { "world" }

print(val) --> Hello, world!

print(val:has "world" ) --> true

```

Due to `extension` modifying the metatable, we can even use it to create custom objects quickly.

```lua

local MyObj = extension {
   {},

   val = 0,

   __tostring = function(self)
      return self.val
   end,

   __add = function(a, b)
      return a.val + b
   end,
}

print(MyObj.val) --> 0

print(MyObj + 1) --> 1

print(MyObj) --> 0

```

Or even create classes (sorta)

```lua

-- Here we can define a function that uses extension to create a class instance
function NewUser(name)
   -- Let's define a variable that we can use internally to the class
   local uuid = ""
   for _ = 1, 16 do
      uuid = uuid .. string.format("%x", math.random(0, 15))
   end

   -- Now we can use extension to simplify making a class by just a bit
   return extension {
      -- We'll just create an empty table to use as a base
      {},

      -- This is like a public field that can be freely changed
      name = name,

      -- We can use closures to mimick private or restricted fields
      GetId = function()
         -- We can't access uuid through normal table indexing, but we can use closures to
         -- define how the property can be accessed
         return uuid
      end,
   }
end

local john = NewUser "John"

print(john:GetId()) --> ac54e584a4867c4b
print(john.name) --> John
john.name = "Steve"
print(john.name) --> Steve

```

Keep in mind that this isn't necessarily the best way to define a class in all scenarios.
In fact it's likely that it'll be worse than the usual methods for many scenarios.
It's just something I noticed about `extension` and thought was interesting enough to include here.

