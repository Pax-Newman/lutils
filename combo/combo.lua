-- I wanted to learn about parser combinators so I'm trying to build one

local utils = require "utils"
local sc = require "strings"

local function strSequence(str)
   return sc.sequence(utils.map(str:gmatch ".", sc.char))
end

local function anyOf(str)
   return sc.any(utils.map(str:gmatch ".", sc.char))
end

local function prettytable(t)
   for key, value in pairs(t) do
      if type(value) == "table" then
         print(string.format("%s: {", key))
         prettytable(value)
         print "}"
      else
         print(string.format("%s: %s", key, value))
      end
   end
end

local alpha = anyOf "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

local digit = anyOf "0123456789"

local integer = sc.atLeast(1, digit)
local float = sc.sequence(integer, sc.char ".", integer)
local hex = sc.transform(
   sc.sequence(strSequence "0x", sc.capture("num", sc.atLeast(1, sc.any(integer, anyOf "abcdefABCDEF")))),
   function(res)
      if res.success then
         return {
            success = res.success,
            value = tostring(tonumber(res.captures.num, 16)),
            rest = res.rest,
            captures = res.captures,
         }
      end
      return { success = false }
   end
)
local octal = sc.transform(
   sc.sequence(strSequence "0o", sc.capture("num", sc.atLeast(1, anyOf "01234567"))),
   function(res)
      if res.success then
         return {
            success = res.success,
            value = tostring(tonumber(res.captures.num, 8)),
            rest = res.rest,
            captures = res.captures,
         }
      end
      return { success = false }
   end
)
local binary = sc.transform(sc.sequence(strSequence "0b", sc.capture("num", sc.atLeast(1, anyOf "01"))), function(res)
   if res.success then
      return {
         success = res.success,
         value = tostring(tonumber(res.captures.num, 2)),
         rest = res.rest,
         captures = res.captures,
      }
   end
   return { success = false }
end)

local number = sc.any(float, hex, octal, binary, integer)

local space = sc.optional(sc.atLeast(1, anyOf " \n\r"))

local identifier = sc.sequence(alpha, sc.optional(sc.atLeast(1, sc.any(alpha, integer))))

local parseLetStatement = sc.node(
   "let",
   sc.sequence(
      strSequence "let",
      space,
      sc.capture("identifier", identifier),
      space,
      sc.char "=",
      space,
      sc.capture("value", sc.any(identifier, number))
   )
)

local parseImportStatement =
   sc.node("import", sc.sequence(strSequence "import", space, sc.capture("module", identifier)))

local parseImportAliasStatment = sc.node(
   "importAlias",
   sc.sequence(
      sc.transform(parseImportStatement, function(res)
         if res.success then
            return {
               success = true,
               value = res.value,
               rest = res.rest,
               captures = res.captures.import,
            }
         end
         return { success = false }
      end),
      space,
      strSequence "as",
      space,
      sc.capture("alias", identifier)
   )
)

local parseStatement = sc.any(parseLetStatement, parseImportAliasStatment, parseImportStatement)

prettytable(parseStatement("let foo = 0.1").captures)
prettytable(parseStatement("import utils").captures)
prettytable(parseStatement("import utils as ut").captures)

local parseTime = sc.sequence(
   sc.capture("hour", sc.any(sc.sequence(anyOf "01", anyOf "0123456"), anyOf "123456")),
   sc.optional(
      sc.sequence(
         sc.char ":",
         sc.capture("minute", sc.sequence(digit, anyOf "0123456")),
         sc.optional(sc.sequence(sc.char ":", sc.capture("second", sc.sequence(digit, anyOf "0123456"))))
      )
   ),
   sc.capture("period", sc.optional(sc.sequence(anyOf "aApP", anyOf "mM")))
)

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

test("integer", integer, "0987654321", { success = true, value = "0987654321", rest = "" })
test("integer", integer, "a1bc", { success = false })

test("hex", hex, "0x0123456789abcdefABCDEF", { success = true, value = "0x0123456789abcdefABCDEF", rest = "" })
test("hex", hex, "0xz123456789abcdefABCDEF", { success = false })

test("octal", octal, "0o01234567", { success = true, value = "0o01234567", rest = "" })
test("octal", octal, "0x123456789abcdefABCDEF", { success = false })

test("binary", binary, "0b1111", { success = true, value = "15", rest = "" })
test("binary", binary, "0b20101110", { success = false })
