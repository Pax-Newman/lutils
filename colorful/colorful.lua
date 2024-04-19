---- ANSI Text Styling

---Converts a hex color string (e.g. #808080) to individual base10 values for rgb channels
---@param num string
---@return integer
---@return integer
---@return integer
local function parseHex(num)
   local r = num:sub(2, 3)
   local g = num:sub(4, 5)
   local b = num:sub(6, 7)

   assert(#r == 2 and #g == 2 and #b == 2, "Improperly formatted color")

   return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end

---Splits a hex color integer (e.g. 0x808080) into its respective rgb channels
---@param color integer
---@return integer
---@return integer
---@return integer
local function splitHex(color)
   assert(0x000000 <= color and color <= 0xffffff, string.format("Color #%x out of bounds", color))

   local r = (color & 0xff0000) >> 16
   local g = (color & 0x00ff00) >> 8
   local b = (color & 0x0000ff)
   return r, g, b
end

---The start of any escape sequence
local ESC = string.char(27, 91)

---Applies an escape code to a string
---@param codes integer[]
---@param str string
---@return string
local function apply(codes, str)
   str = ESC .. table.concat(codes, ";") .. "m" .. str .. ESC .. "0m"
   return str
end

---Contains functions to apply an ANSI format escape sequence to text
local fmtMap = {
   bold = function(str)
      return apply({ 1 }, str)
   end,
   italic = function(str)
      return apply({ 3 }, str)
   end,
   under = function(str)
      return apply({ 4 }, str)
   end,
   blink = function(str)
      return apply({ 5 }, str)
   end,
   fastblink = function(str)
      return apply({ 6 }, str)
   end,
   strike = function(str)
      return apply({ 9 }, str)
   end,
   over = function(str)
      return apply({ 53 }, str)
   end,
}

---Wraps a string with metamethods for ANSI styling
---@param str string
---@return string
local function Style(str)
   assert(type(str) == "string", "Only strings can be wrapped")

   local meta = debug.getmetatable(str)
   meta.__index = function(inner, idx)
      if idx == "isFstring" then
         return true
      end

      return fmtMap[idx](inner)
   end

   meta.__mod = function(a, b)
      assert(
         type(a) == "string" and type(b) == "table",
         string.format("__mod not implemented for %s and %s", type(a), type(b))
      )

      return string.format(a, table.unpack(b))
   end

   ---@class string
   ---@field italic string Italicizes the string
   ---@field bold string Bolds the string
   ---@field under string Underlines the string
   ---@field over string Overlines the string
   ---@field strike string Strikes through the string
   ---@field blink string Causes the string to blink slowly
   ---@field fastblink string Causes the string to blink quicly
   ---@field fg table<string|integer, string> | fun(color: string | integer): string Sets the foreground color
   ---@field bg table<string|integer, string> | fun(color: string | integer): string Sets the background color
   return str
end

local colors = {}
---Register a color for later use
---@param name string
---@param hex string e.g. #808080
--Ex.
--```lua
--SetColor('grey', '#808080')
--
--Style("This will be grey").fg.grey
--
--```
--
local function SetColor(name, hex)
   colors[name] = { parseHex(hex) }
end

fmtMap.fg = function(obj)
   local function set(_, color)
      if type(color) == "string" then
         local r, g, b = table.unpack(colors[color])
         return apply({ 38, 2, r, g, b }, obj)
      elseif type(color) == "number" then
         return apply({ 38, 2, splitHex(color) }, obj)
      end
   end
   return setmetatable({}, {
      __index = set,
      __call = set,
   })
end

fmtMap.bg = function(obj)
   local function set(_, color)
      if type(color) == "string" then
         local r, g, b = table.unpack(colors[color])
         return apply({ 48, 2, r, g, b }, obj)
      elseif type(color) == "number" then
         return apply({ 48, 2, splitHex(color) }, obj)
      end
   end
   return setmetatable({}, {
      __index = set,
      __call = set,
   })
end

return {
   Style = Style,
   SetColor = SetColor,
}
