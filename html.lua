---- An experiment on meta programming and backend html generation

---@alias opts { singleton? : boolean }

--- Element Factory
---@param tag string
---@param opts? opts
---@return fun(data: table): string
local function Element(tag, opts)
   opts = opts or {}

   return function(data)
      local attributes = ""
      local contents = {}

      for index, value in pairs(data) do
         if type(index) == "string" then
            attributes = attributes .. string.format(' %s="%s"', index:gsub("_", "-"), value)
         elseif type(index) == "number" then
            table.insert(contents, value)
         end
      end

      -- local attr_str = table.concat(attributes, " ")
      local opening = string.format("<%s%s>", tag, attributes)

      if opts.singleton then
         return opening
      end

      local closing = string.format("</%s>", tag)
      return opening .. table.concat(contents, "") .. closing
   end
end

local html = {
   div = Element("div"),
   a = Element("a"),
   img = Element("img", { singleton = true }),
}

return html
