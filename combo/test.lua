local utils = require "utils"

local cb = require "combo"

---Match an exact sequence of characters
local function strSequence(str)
   return cb.sequence(utils.map(str:gmatch ".", cb.one))
end

---Match one of any of the characters in the string
local function anyOf(str)
   return cb.any(utils.map(str:gmatch ".", cb.one))
end

---Match one alphabet character
local alpha = anyOf "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

---Match one numerical character
local digit = anyOf "0123456789"

---Match one alphanumeric character
local alphaNum = cb.any(alpha, digit)

---Match an integer of any length
local integer = cb.atLeast(1, digit)

---Match a floating point number of any length
local float = cb.sequence(integer, cb.one ".", integer)

---Match a hexadecimal number of any length of the form `0xFFFF`
local hex = cb.mapVal(
   cb.sequence(strSequence "0x", cb.capture("num", cb.atLeast(1, cb.any(integer, anyOf "abcdefABCDEF")))),
   -- Use `transform` to change the hex number into an integer
   function(val)
      return tostring(tonumber(val.captures.num, 16))
   end
)

---Match an octal number of any length of the form `0o7777`
local octal = cb.mapVal(cb.sequence(strSequence "0o", cb.capture("num", cb.atLeast(1, anyOf "01234567"))), function(res)
   return tostring(tonumber(res.captures.num, 8))
end)

---Match a binary number of any length of the form `0b1111`
local binary = cb.mapVal(cb.sequence(strSequence "0b", cb.capture("num", cb.atLeast(1, anyOf "01"))), function(val)
   return tostring(tonumber(val.captures.num, 2))
end)

---Match a number of any length and any valid format
local number = cb.any(float, hex, octal, binary, integer)

---Match any amount of whitespace
local space = cb.optional(cb.atLeast(1, anyOf " \n\r"))

local identifier = cb.sequence(alpha, cb.optional(cb.atLeast(1, cb.any(alpha, integer))))

local parseLetStatement = cb.mapRes(
   cb.sequence(
      strSequence "let",
      space,
      cb.capture("name", identifier),
      space,
      cb.one "=",
      space,
      cb.capture("value", cb.any(identifier, number))
   ),
   function(res)
      res.value = {
         {
            token = { type = "LetStatement", literal = "let" },
            name = table.concat(res.captures.name),
            value = table.concat(res.captures.value),
         },
      }
      res.captures = {}

      return res
   end,
   false
)

local parseImportStatement = cb.mapRes(
   cb.sequence(
      strSequence "import",
      space,
      cb.capture("module", identifier),
      -- Optionally set an alias for the module
      -- Ex. import foo as f
      cb.optional(cb.sequence(space, strSequence "as", space, cb.capture("alias", identifier)))
   ),
   function(res)
      res.value = {
         {
            token = { type = "ImportStatement", literal = "import" },
            module = table.concat(res.captures.module),
            alias = table.concat(res.captures.alias or {}),
         },
      }
      res.captures = {}

      return res
   end
)

local parseStatement = cb.takeStr(cb.any(parseLetStatement, parseImportStatement))

utils.prettytable(parseStatement "let foo = 0.1")
utils.prettytable(parseStatement "import utils")
utils.prettytable(parseStatement "import utils as ut")

---Match a 12hour time of the form `HH(am|pm)`, `HH:MM(am|pm)`, or `HH:MM:SS(am|pm)`
local parseTime = cb.sequence(
   cb.capture("hour", cb.any(cb.sequence(anyOf "01", anyOf "0123456"), anyOf "123456")),
   cb.optional(
      cb.sequence(
         cb.one ":",
         cb.capture("minute", cb.sequence(digit, anyOf "0123456")),
         cb.optional(cb.sequence(cb.one ":", cb.capture("second", cb.sequence(digit, anyOf "0123456"))))
      )
   ),
   cb.capture("period", cb.optional(cb.sequence(anyOf "aApP", anyOf "mM")))
)

---Tests a combinator
---@param name string
---@param combo ComboPiece
---@param val any
---@param expected Result
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

test("integer", integer, "0987654321", { success = true, value = "0987654321", rest = "" })
test("integer", integer, "a1bc", { success = false })

test("hex", hex, "0x0123456789abcdefABCDEF", { success = true, value = "7460683158693596655", rest = "" })
test("hex", hex, "0xz123456789abcdefABCDEF", { success = false })

test("octal", octal, "0o01234567", { success = true, value = "342391", rest = "" })
test("octal", octal, "0x123456789abcdefABCDEF", { success = false })

test("binary", binary, "0b1111", { success = true, value = "15", rest = "" })
test("binary", binary, "0b20101110", { success = false })
