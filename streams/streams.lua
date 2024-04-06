---- Experiments on using coroutines to implement streams

---@class Stream
---@field co thread Iterable coroutine
local Stream = {}

---@alias streamable any[] | string | fun(): any

---Creates a stream object from a sequential array
---@param streamable streamable
---@return Stream
local function stream(streamable)
   local obj = {}

   local t = type(streamable)
   if t == "table" then
      obj.co = coroutine.create(function()
         for i = 1, #streamable do
            coroutine.yield(streamable[i])
         end
      end)
   elseif t == "string" then
      obj.co = coroutine.create(function()
         for i = 1, #streamable do
            coroutine.yield(string.sub(streamable, i, i))
         end
      end)
   elseif t == "function" then
      obj.co = coroutine.create(function()
         local val = streamable()
         while val ~= nil do
            coroutine.yield(val)
            val = streamable()
         end
      end)
   else
      error("Expected streamable type of table, string, or function, but got: " .. t)
   end

   setmetatable(obj, { __index = Stream })
   return obj
end

---Returns the next element from the stream. Return nil when the stream has been exhausted
---@return any value
---@return boolean status
function Stream:next()
   local status, value = coroutine.resume(self.co)
   return value, status
end

---Creates an iterator function for use in for loops
---@return fun(): any, boolean
--
--Ex.
--```lua
--for item, ok in my_stream:iter() do
--   print(item, ok)
--end
--```
function Stream:iter()
   return function()
      return self:next()
   end
end

---Converts the remaining items of the stream into a normal array
---@return any[]
function Stream:to_arr()
   local result = {}

   local _, item = self:next()
   while item ~= nil do
      table.insert(result, item)
   end

   return result
end

---Maps a function to each element of the stream
---@param fn fun(item: any): any
---@return Stream
function Stream:map(fn)
   local prev = self.co
   self.co = coroutine.create(function()
      local _, item = coroutine.resume(prev)
      while item ~= nil do
         coroutine.yield(fn(item))
         _, item = coroutine.resume(prev)
      end
   end)
   return self
end

---Filters stream values using a function
---@param fn fun(item: any): boolean
---@return Stream
function Stream:filter(fn)
   local prev = self.co
   self.co = coroutine.create(function()
      local _, item = coroutine.resume(prev)
      while item ~= nil do
         -- If the current value satisfies the passed function, yield that value
         if fn(item) == true then
            coroutine.yield(item)
         end
         -- Otherwise exhuast the stream until we find one
         _, item = coroutine.resume(prev)
      end
   end)
   return self
end

---Filters repeat values from the stream
---@return Stream
function Stream:distinct()
   local prev = self.co

   -- Keep track of previously seen values
   local present = {}

   self.co = coroutine.create(function()
      local _, item = coroutine.resume(prev)
      while item ~= nil do
         -- Check if we've already seen this value
         if present[item] == nil then
            present[item] = true
            coroutine.yield(item)
         end

         -- Otherwise continue to exhaust the stream until we find something unseen
         _, item = coroutine.resume(prev)
      end
   end)
   return self
end

---Reduces a stream to a single value using a function
---@param fn fun(accumulator: any, item: any): any
---@return any accumulator
function Stream:reduce(fn)
   local item = self:next()

   local acc = item

   item = self:next()
   while item ~= nil do
      acc = fn(acc, item)
      item = self:next()
   end
   return acc
end

---Reduces a stream to a single value using a function, allows setting the initial accumulator value
---@param start any
---@param fn fun(accumulator: any, item: any): any
---@return any
function Stream:fold(start, fn)
   local acc = start

   local item = self:next()
   while item ~= nil do
      acc = fn(acc, item)
      item = self:next()
   end
   return acc
end

return stream
