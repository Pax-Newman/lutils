-- I wanted to learn about parser combinators so I'm trying to build one

---@alias result { success: boolean, value: any?, rest: any?, captures?: table<string, string> }
---@alias combinator fun(...: string): result
---@alias atom fun(str: string): result

local function map(arr, fun)
   local res = {}
   for item in arr do
      table.insert(res, fun(item))
   end

   return table.unpack(res)
end

local function merge(t1, t2)
   for key, value in pairs(t2) do
      t1[key] = value
   end
   return t1
end

---Specifies a capture group
---@param name string
---@param combo combinator
---@param transform? fun(res: string): string
---@return combinator
local function capture(name, combo, transform)
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

---Transforms the result of a combo using the provided function
---@param combo combinator
---@param func fun(res: result): result
---@return combinator
local function transform(combo, func)
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

---Specifies an exact sequence of combos to be matched
---@param ... combinator
local function sequence(...)
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

         result.captures = merge(result.captures, step.captures)
      end

      return result
   end
end

---Succeeds and consumes if the combo is matched at least n times
---@param n integer
---@param combo combinator
---@return combinator
local function atLeast(n, combo)
   return function(str)
      local result = { success = false, value = "", captures = {} }

      local step = combo(str)

      result.success = step.success

      while step.success do
         result.value = result.value .. step.value
         result.rest = step.rest
         result.captures = merge(result.captures, step.captures)
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
            captures = {},
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
            captures = {},
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

local digit = anyOf "0123456789"

local number = atLeast(1, digit)
local hex = sequence(strSequence "0x", atLeast(1, any(number, anyOf "abcdefABCDEF")))
local octal = sequence(strSequence "0o", atLeast(1, anyOf "01234567"))
local binary = sequence(strSequence "0b", atLeast(1, anyOf "01"))

local parseKeyword = any(strSequence "let", strSequence "import")

local parseTime = sequence(
   capture("hour", any(sequence(anyOf "01", anyOf "0123456"), anyOf "123456")),
   char ":",
   capture("minute", sequence(digit, anyOf "123456")),
   char ":",
   capture("second", sequence(digit, anyOf "123456"))
)

print(parseTime("4:54:23").captures.minute)

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
