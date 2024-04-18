---- ANSI Text Styling

local function parseHex(num)
   local r = num:sub(2, 3)
   local g = num:sub(4, 5)
   local b = num:sub(6, 7)

   assert(#r == 2 and #g == 2 and #b == 2, "Improperly formatted color")

   return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end

local ESC = string.char(27, 91)

local function apply(codes, obj)
   obj.val = ESC .. table.concat(codes, ";") .. "m" .. obj.val .. ESC .. "0m"
   return obj
end

local fmtMap = {
   bold = function(obj)
      return apply({ 1 }, obj)
   end,
   italic = function(obj)
      return apply({ 3 }, obj)
   end,
   under = function(obj)
      return apply({ 4 }, obj)
   end,
   blink = function(obj)
      return apply({ 5 }, obj)
   end,
   fastblink = function(obj)
      return apply({ 6 }, obj)
   end,
   strike = function(obj)
      return apply({ 9 }, obj)
   end,
   over = function(obj)
      return apply({ 53 }, obj)
   end,
}

local style = {}
function style:new(str)
   local obj = {}

   setmetatable(obj, self)
   self.__index = function(_, idx)
      if idx == "val" then
         return str
      end

      return fmtMap[idx](obj)
   end

   return obj
end

function style:__tostring()
   -- PERF: Right now we're repeating a lot of opening and closing escapes
   -- but we could instead track each code and apply them efficiently at render-time here
   return self.val
end

local colors = {}
function style.SetColor(name, hex)
   colors[name] = { parseHex(hex) }
end

fmtMap.fg = function(obj)
   local function set(_, color)
      if type(color) == "string" then
         local r, g, b = table.unpack(colors[color])
         return apply({ 38, 2, r, g, b }, obj)
      elseif type(color) == "number" then
         local r = (color & 0xff0000) >> 16
         local g = (color & 0x00ff00) >> 8
         local b = (color & 0x0000ff)
         return apply({ 38, 2, r, g, b }, obj)
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
         local r = (color & 0xff0000) >> 16
         local g = (color & 0x00ff00) >> 8
         local b = (color & 0x0000ff)
         return apply({ 48, 2, r, g, b }, obj)
      end
   end
   return setmetatable({}, {
      __index = set,
      __call = set,
   })
end

return style
