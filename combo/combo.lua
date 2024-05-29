-- I wanted to learn about parser combinators so I'm trying to build one

local utils = require "utils"

---@generic T
---@class ComboInput
---@field next fun(): `T`

---@alias Token { type: string, literal: string }
---@alias Result { success: boolean, value: any[], rest: string, captures: table}
---@alias ComboPiece fun(val: Array): Result

local exports = {}

---Matches one of the target
---@param target any Must implement __eq
---@return ComboPiece
function exports.one(target)
   return function(val)
      if val[1] ~= nil and target == val[1] then
         return {
            success = true,
            value = { val[1] },
            rest = { table.unpack(val, 2) },
            captures = {},
         }
      end

      return { success = false }
   end
end

---Returns the result of the first combo that successfully matches
---@param ... ComboPiece
---@return ComboPiece
function exports.any(...)
   local combos = table.pack(...)

   return function(val)
      local res

      for _, combo in ipairs(combos) do
         res = combo(val)
         if res.success then
            return res
         end
      end

      return { success = false }
   end
end

---Returns successfully even if the wrapped combo doesn't match
---@param combo ComboPiece
---@return ComboPiece
function exports.optional(combo)
   return function(val)
      local res = combo(val)

      if res.success then
         return res
      end

      return { success = true, value = val, rest = {}, captures = {} }
   end
end

---Succeeds if it can match the combo at least n times
---@param n integer
---@param combo ComboPiece
---@return ComboPiece
function exports.atLeast(n, combo)
   return function(val)
      local res = { success = false, value = {}, captures = {} }

      local step = combo(val)

      res.success = step.success

      while step.success do
         res.value = utils.concatArrays(res.value, step.value)
         res.rest = step.rest
         res.captures = utils.merge(res.captures, step.captures)
         step = combo(step.rest)
      end

      if not res.success or #res.value < n then
         return { success = false }
      else
         return res
      end
   end
end

---Matches an exact sequence of combos
---@param ... ComboPiece
---@return ComboPiece
function exports.sequence(...)
   local combos = table.pack(...)

   return function(val)
      local res = { success = true, rest = val }

      for _, combo in ipairs(combos) do
         local step = combo(res.rest)

         if not step.success then
            return { success = false }
         end

         res.value = utils.concatArrays(res.value or {}, step.value)
         res.rest = step.rest
         res.captures = utils.merge(res.captures or {}, step.captures)
      end

      return res
   end
end

---Transforms the result of a combo using the provided function
---@param combo ComboPiece
---@param transform fun(res: Result): Result
---@param onFail boolean? Apply the transformation regardless of success status (true)
---@return ComboPiece
function exports.mapRes(combo, transform, onFail)
   if onFail == nil or onFail == true then
      -- Always applies the transformation even on a failure (default)
      return function(val)
         return transform(combo(val))
      end
   else
      -- Only applies the transformation on a success
      return function(val)
         local res = combo(val)
         if res.success then
            return transform(res)
         end
         return res
      end
   end
end

---Transforms the value of a combo using the provided function
---@param combo ComboPiece
---@param transform fun(val: any): any
---@return ComboPiece
function exports.mapVal(combo, transform)
   return function(val)
      local res = combo(val)
      if res.success then
         res.value = transform(res.value)
         return res
      end
      return res
   end
end

---Wraps a combo with a small function that converts
---string input into an array of characters, allowing
---combos to work with string input
---@param combo ComboPiece
---@return fun(str: string): Result
function exports.takeStr(combo)
   return function(str)
      return combo(utils.strToArr(str))
   end
end

return exports
