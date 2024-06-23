-- Experiment on creating pull iterators with closures

---@class Iterator
local Iterator = {}

---@alias iterable any[] | string | fun(): any

---Creates an iterator from an iterable object
---@param iterable iterable
---@return Iter
local function new(iterable)
   ---@type Iter
   local obj = {}
   local next

   ---- Initialize base iterator function

   if type(iterable) == "table" then
      local idx, len = 1, #iterable

      next = function()
         if idx > len then
            return nil, false
         end

         local result = iterable[idx]
         idx = idx + 1

         return result, true
      end
   elseif type(iterable) == "function" then
      next = function()
         local result = iterable()

         if result == nil then
            return nil, false
         else
            return result, true
         end
      end
   elseif type(iterable) == "string" then
      local idx, len = 1, #iterable

      next = function()
         if idx > len then
            return nil, false
         end

         local result = iterable:sub(idx, idx)

         idx = idx + 1
         return result, true
      end
   end

   setmetatable(obj, {
      __call = next,
      __index = Iterator,
   })

   ---- Finish

   return obj
end

---- Methods

---Apply a function to each value in the iterator
---@param fn fun(item: any): any
---@return Iterator
function Iterator:map(fn)
   local previous = getmetatable(self).__call

   setmetatable(self, {
      __index = Iterator,
      __call = function()
         local result, ok = previous()

         if not ok then
            return nil, false
         end

         return fn(result), true
      end,
   })

   return self
end

---Filters out values that don't return true
---@param fn fun(value: any): boolean
---@return Iterator
function Iterator:filter(fn)
   local previous = getmetatable(self).__call

   setmetatable(self, {
      __index = Iterator,
      __call = function()
         while true do
            local result, ok = previous()

            if not ok then
               return nil, false
            end

            if fn(result) then
               return result, ok
            end
         end
      end,
   })

   return self
end

---Reduces the iterator to a single value
---@param fn fun(accumulator: any, value: any): any
---@param initial? any The initial value of the accumulator
---@return any accumulated
function Iterator:reduce(fn, initial)
   local acc = initial

   while true do
      local result, ok = self()

      if not ok then
         break
      end

      acc = fn(acc, result)
   end

   return acc
end

local arr_iter = new { 1, 2, 3 }

arr_iter:map(print)

return new
