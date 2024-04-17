local function hex(num)
   return tonumber(num, 16)
end

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
         -- \033[38;2;<r>;<g>;<b>m     #Select RGB foreground color
         local fg = item.fg

         local r = fg:sub(2, 3)
         local g = fg:sub(4, 5)
         local b = fg:sub(6, 7)
         assert(#r == 2 and #g == 2 and #b == 2, "Improperly formatted color")
         table.insert(effects, string.format("38;2;%d;%d;%d", hex(r), hex(g), hex(b)))
      end

      ---- Apply background color
      if item.bg then
         -- \033[48;2;<r>;<g>;<b>m     #Select RGB background color
         local bg = item.bg

         local r = bg:sub(2, 3)
         local g = bg:sub(4, 5)
         local b = bg:sub(6, 7)
         assert(#r == 2 and #g == 2 and #b == 2, "Improperly formatted color")
         table.insert(effects, string.format("48;2;%d;%d;%d", hex(r), hex(g), hex(b)))
      end

      local eff_str = table.concat(effects, ";")
      local esc = string.char(27, 91)

      table.insert(collection, esc .. eff_str .. "m" .. str .. esc .. "0m")
   end

   return table.concat(collection)
end

return style
