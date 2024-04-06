-- Provides iterator utilities

local iterable = {}

---Grants the table access to the itertools metamethods
---Metamethods may not work correctly for non-sequential arrays
---@param t any[]
local function iter(t)
   assert(type(t) == "table", "expected a table")
   return setmetatable(t, { __index = iterable })
end

---Returns a new array by calling fn on each element
---@param fn fun(idx: number, val: any): any
function iterable:map(fn)
   local result = {}
   for idx, val in pairs(self) do
      result[idx] = fn(idx, val)
   end
   return setmetatable(result, { __index = iterable })
end

---Applies fn to the array and returns a new array of elements that caused fn to return true
---@param fn fun(idx: number, val: any): any
function iterable:filter(fn)
   local result = {}
   for idx, val in pairs(self) do
      if fn(idx, val) then
         table.insert(result, val)
      end
   end
   return setmetatable(result, { __index = iterable })
end

---Acculates values into a single value using fn
---Initial accumulator value is the first item of the array
---@param fn fun(accumulator: any, idx: number, val: any): any
---@return any
function iterable:reduce(fn)
   if #self < 1 then
      return nil
   end

   local result = self[1]
   for i = 2, #self do
      result = fn(result, i, self[i])
   end
   return result
end

---Applies fn to the array and returns a new array of elements that caused fn to return true
---@param start any Initial accumulator value
---@param fn fun(accumulator: any, idx: any, val: any): any
---@return any
function iterable:fold(start, fn)
   if #self < 1 then
      return start
   end

   local result = start
   for idx, val in pairs(self) do
      result = fn(result, idx, val)
   end
   return result
end

return iter
