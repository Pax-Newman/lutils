---Handles string parser combinators

local utils = require "utils"

local exports = {}

---@alias result { success: boolean, value: any?, rest: any?, captures?: table<string, string> }
---@alias combinator fun(string): result
---@alias atom fun(str: string): result

---Specifies a capture group
---@param name string
---@param combo combinator
---@param transform? fun(res: string): string
---@return combinator
function exports.capture(name, combo, transform)
   return function(str)
      local result = combo(str)

      transform = transform or function(x)
         return x
      end

      if result.success then
         result.captures[name] = transform(result.value)

         return {
            success = true,
            value = result.value,
            rest = result.rest,
            captures = result.captures,
         }
      end
      return { success = false }
   end
end

---Specifies a node for nesting capture groups
---@param name string
---@param combo combinator
---@param transform? fun(res: string): string
---@return combinator
function exports.node(name, combo, transform)
   return function(str)
      local result = combo(str)

      transform = transform or function(x)
         return x
      end

      if result.success then
         return {
            success = true,
            value = result.value,
            rest = result.rest,
            captures = { [name] = result.captures },
         }
      end
      return { success = false }
   end
end

---Transforms the result of a combo using the provided function
---@param combo combinator
---@param func fun(res: result): result
---@return combinator
function exports.transform(combo, func)
   return function(str)
      local result = combo(str)
      if result.success then
         return func(result)
      end
      return result
   end
end

---Returns the result of the first successful combo, or a failure if none succeed
---@param ... combinator
---@return combinator
function exports.any(...)
   local arr = table.pack(...)
   return function(str)
      for _, combo in ipairs(arr) do
         local res = combo(str)
         if res.success then
            return res
         end
      end
      return { success = false }
   end
end

---Specifies an exact sequence of combos to be matched
---@param ... combinator
function exports.sequence(...)
   ---@type combinator[]
   local combos = table.pack(...)

   return function(str)
      local result = { success = true, value = "", rest = str, captures = {} }

      for _, combo in ipairs(combos) do
         local step = combo(result.rest)

         if not step.success then
            return { success = false }
         end

         result.value = result.value .. step.value
         result.rest = step.rest

         result.captures = utils.merge(result.captures, step.captures)
      end

      return result
   end
end

---Succeeds and consumes if the combo is matched at least n times
---@param n integer
---@param combo combinator
---@return combinator
function exports.atLeast(n, combo)
   return function(str)
      local result = { success = false, value = "", captures = {} }

      local step = combo(str)

      result.success = step.success

      while step.success do
         result.value = result.value .. step.value
         result.rest = step.rest
         result.captures = utils.merge(result.captures, step.captures)
         step = combo(step.rest)
      end

      if not result.success or #result.value < n then
         return { success = false }
      else
         return result
      end
   end
end

---Attempts to parse the combo, on a failure it still returns a successful result without consuming
---@param combo any
---@return function
function exports.optional(combo)
   return function(str)
      local result = combo(str)

      if result.success then
         return result
      else
         return {
            success = true,
            value = "",
            rest = str,
            captures = {},
         }
      end
   end
end

---Creates a combo that returns true if the first char of the string matches the target char
---@param target string
---@return atom
function exports.char(target)
   assert(type(target) == "string", "Target must be a string")
   return function(str)
      local c = str:sub(1, 1)
      if c == target then
         return {
            success = true,
            value = c,
            rest = str:sub(2),
            captures = {},
         }
      end
      return { success = false }
   end
end

return exports
