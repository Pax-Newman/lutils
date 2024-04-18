---- ANSI Text Styling

local function parseHex(num)
   local r = num:sub(2, 3)
   local g = num:sub(4, 5)
   local b = num:sub(6, 7)

   assert(#r == 2 and #g == 2 and #b == 2, "Improperly formatted color")

   return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end

---@alias item { [1] : string, fg : string, bg : string, under : boolean, strike : boolean, over : boolean, bold : boolean, italic : boolean, blink : boolean, fastblink : boolean}

---Applies ANSI text formatting
---@param opts item | item[]
---@return string
local function style(opts)
   if type(opts[1]) == "string" then
      opts = { opts }
   end

   local collection = {}

   for _, item in ipairs(opts) do
      local str = assert(item[1], "Must supply a string at the first table idx")

      local effects = {}

      ---- Apply foreground color
      if item.fg then
         -- \033[38;2;<r>;<g>;<b>m     Select RGB foreground color
         table.insert(effects, string.format("38;2;%d;%d;%d", parseHex(item.fg)))
      end

      ---- Apply background color
      if item.bg then
         -- \033[48;2;<r>;<g>;<b>m     Select RGB background color
         table.insert(effects, string.format("48;2;%d;%d;%d", parseHex(item.bg)))
      end

      if item.bold then
         table.insert(effects, 1)
      end

      if item.italic then
         table.insert(effects, 3)
      end

      if item.under then
         table.insert(effects, 4)
      end

      if item.blink then
         table.insert(effects, 5)
      end

      if item.fastblink then
         table.insert(effects, 6)
      end

      if item.strike then
         table.insert(effects, 9)
      end

      if item.over then
         table.insert(effects, 53)
      end

      local eff_str = table.concat(effects, ";")
      local esc = string.char(27, 91)

      table.insert(collection, esc .. eff_str .. "m" .. str .. esc .. "0m")
   end

   return table.concat(collection)
end

return style
