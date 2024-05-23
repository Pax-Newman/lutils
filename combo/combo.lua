-- I wanted to learn about parser combinators so I'm trying to build one

---@alias result { success: boolean, value: any?, rest: any?}
---@alias combinator fun(...: string): result
---@alias atom fun(any): result

local function map(arr, fun)
   local res = {}
   for item in arr do
      table.insert(res, fun(item))
   end

   return table.unpack(res)
end

---Creates a combo that succeeds if any of its combos succeed
---@param ... combinator
---@return combinator
local function any(...)
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

---Creates a combo that consumes an exact sequence of combos
---@param ... combinator
local function sequence(...)
   ---@type combinator[]
   local combos = table.pack(...)

   return function(str)
      local result = { success = true, value = "", rest = str }

      for _, combo in ipairs(combos) do
         local step = combo(result.rest)

         if not step.success then
            return { success = false }
         end

         result.value = result.value .. step.value
         result.rest = step.rest
      end

      return result
   end
end

local function atLeast(n, combo)
   return function(str)
      local result = { success = false, value = "" }

      local step = combo(str)

      result.success = step.success

      while step.success do
         result.value = result.value .. step.value
         result.rest = step.rest
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
local function optional(combo)
   return function(str)
      local result = combo(str)

      if result.success then
         return result
      else
         return {
            success = true,
            value = "",
            rest = str,
         }
      end
   end
end

---Creates a combo that returns true if the first char of the string matches the target char
---@param target string
---@return atom
local function char(target)
   assert(type(target) == "string", "Target must be a string")
   return function(str)
      local c = str:sub(1, 1)
      if c == target then
         return {
            success = true,
            value = c,
            rest = str:sub(2),
         }
      end
      return { success = false }
   end
end

local function strSequence(str)
   return sequence(map(str:gmatch ".", char))
end

local function anyOf(str)
   return any(map(str:gmatch ".", char))
end

local alpha = anyOf "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
local word = atLeast(1, alpha)

local number = atLeast(1, anyOf "1234567890")
local hex = sequence(strSequence "0x", atLeast(1, anyOf "0123456789abcdefABCDEF"))
local octal = sequence(strSequence "0o", atLeast(1, anyOf "01234567"))
local binary = sequence(strSequence "0b", atLeast(1, anyOf "01"))

local parseKeyword = any(strSequence "let", strSequence "import")

---Tests a combinator
---@param name string
---@param combo combinator
---@param val string
---@param expected result
local function test(name, combo, val, expected)
   local result = combo(val)

   local response = string.format("%s Succeeded", name)

   if result.success ~= expected.success then
      response =
         string.format("%s Failed: Success Mismatch\n   Expected %s\n   Got %s", name, expected.success, result.success)
   elseif result.value ~= expected.value then
      response =
         string.format("%s Failed: Value Mismatch\n   Expected %s\n   Got %s", name, expected.value, result.value)
   elseif result.rest ~= expected.rest then
      response = string.format("%s Failed: Rest Mismatch\n   Expected %s\n   Got %s", name, expected.rest, result.rest)
   end

   print(response)
end

test("isAlpha", alpha, "a", { success = true, value = "a", rest = "" })
test("isAlpha", alpha, "1", { success = false })

test("word", word, "abc123", { success = true, value = "abc", rest = "123" })
test("word", word, "123abc", { success = false })

test("parseKeyword (let)", parseKeyword, "let a = 1", { success = true, value = "let", rest = " a = 1" })
test("parseKeyword (module)", parseKeyword, "import module", { success = true, value = "import", rest = " module" })

test("number", number, "0987654321", { success = true, value = "0987654321", rest = "" })
test("number", number, "a1bc", { success = false })

test("hex", hex, "0x0123456789abcdefABCDEF", { success = true, value = "0x0123456789abcdefABCDEF", rest = "" })
test("hex", hex, "0xz123456789abcdefABCDEF", { success = false })

test("octal", octal, "0o01234567", { success = true, value = "0o01234567", rest = "" })
test("octal", octal, "0x123456789abcdefABCDEF", { success = false })

test("binary", binary, "0b0101110", { success = true, value = "0b0101110", rest = "" })
test("binary", binary, "0b20101110", { success = false })
