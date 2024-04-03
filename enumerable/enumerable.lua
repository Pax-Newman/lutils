--- Extends tables with enumerable functions
--- Credit to mikelovesrobots/lua-enumerable for the original code

---Returns true if the list contains the value
---@param list any[]
---@param value any
---@return boolean
table.includes = function(list, value)
   for i, x in ipairs(list) do
      if x == value then
         return true
      end
   end
   return false
end

---Apply a function, returning the item which causes the function to return true
---@param list any[]
---@param func fun(x: any, i: integer): boolean
---@return any
table.detect = function(list, func)
   for i, x in ipairs(list) do
      if func(x, i) then
         return x
      end
   end
   return nil
end

---Returns the list without the item
---@param list any[]
---@param item any
---@return any[]
table.without = function(list, item)
   return table.reject(list, function(x)
      return x == item
   end)
end

---Applies a function to each item in the list
---@param list any[]
---@param func fun(v: any, i: integer)
table.each = function(list, func)
   for i, v in ipairs(list) do
      func(v, i)
   end
end

---Applies a function to each item in a table
---@param list table
---@param func fun(v: any, i: any)
table.every = function(list, func)
   for i, v in pairs(list) do
      func(v, i)
   end
end

---Returns a new list of items that cause the function to return *true*
---@param list any[]
---@param func fun(x: any, i: integer): boolean
---@return any[]
table.select = function(list, func)
   local results = {}
   for i, x in ipairs(list) do
      if func(x, i) then
         table.insert(results, x)
      end
   end
   return results
end

---Returns a new list of items that cause the function to return *false*
---@param list any[]
---@param func fun(x: any, i: integer): boolean
---@return any[]
table.reject = function(list, func)
   local results = {}
   for i, x in ipairs(list) do
      if func(x, i) == false then
         table.insert(results, x)
      end
   end
   return results
end

---Split a list into two lists, one for which the function returns true, and one for which it returns false
---@param list any[]
---@param func fun(x: any, i: integer): boolean
---@return any[], any[]
table.partition = function(list, func)
   local matches = {}
   local rejects = {}

   for i, x in ipairs(list) do
      if func(x, i) then
         table.insert(matches, x)
      else
         table.insert(rejects, x)
      end
   end

   return matches, rejects
end

---Merge two tables. In the case of a conflict, the destination table's value will be used
---@param source table
---@param destination table
---@return table
table.merge = function(source, destination)
   for k, v in pairs(destination) do
      source[k] = v
   end
   return source
end

---Inserts a value at the beginning of a list
---@param list any[]
---@param val any
table.unshift = function(list, val)
   table.insert(list, 1, val)
end

---Removes the first item from a list and returns it
---@param list any[]
---@return any
table.shift = function(list)
   return table.remove(list, 1)
end

---Removes the last item from a list and returns it
---@param list any[]
---@return any
table.pop = function(list)
   return table.remove(list)
end

---Appends a value to the end of a list
---@param list any[]
---@param item any
table.push = function(list, item)
   return table.insert(list, item)
end

table.collect = function(source, func)
   local result = {}
   for _, v in ipairs(source) do
      table.insert(result, func(v))
   end
   return result
end

---Returns true if the list is empty
---@param source any[]
---@return boolean
table.empty = function(source)
   return source == nil or next(source) == nil
end

---Returns true if the list is not empty
---@param source any[]
---@return boolean
table.present = function(source)
   return not (table.empty(source))
end

---Selects a random item from the list
---@param source any[]
---@return any
table.random = function(source)
   return source[math.random(1, #source)]
end

---Run a function a number of times
---@param limit integer
---@param func fun(i: integer)
table.times = function(limit, func)
   for i = 1, limit do
      func(i)
   end
end

---Creates a new list with the items reversed
---@param source any[]
---@return any[]
table.reverse = function(source)
   local result = {}
   for i, v in ipairs(source) do
      table.unshift(result, v)
   end
   return result
end

---Duplicates a table
---@param source table
---@return table
table.dup = function(source)
   local result = {}
   for k, v in pairs(source) do
      result[k] = v
   end
   return result
end

---Fisher-Yates shuffle
---@param t any[]
---@return any[]
function table.shuffle(t)
   local n = #t
   while n > 2 do
      local k = math.random(n)
      t[n], t[k] = t[k], t[n]
      n = n - 1
   end
   return t
end

---Returns the keys of a table
---@param source table
---@return any[]
function table.keys(source)
   local result = {}
   for k, _ in pairs(source) do
      table.push(result, k)
   end
   return result
end
