---- An experiment on DSLs and backend html generation
package.path = package.path .. ";?.lua"

local fenv = require("fenv")

---Options for creating a new element
---@alias opts { singleton? : boolean }
---Partially rendered html piece
---@alias partial (string|fun(opts: table<string, any>): string)[]
---A piece of dynamic rendering code in an html partial
---@alias codepiece fun(opts?: table<string, any>): string

local function join(arr1, arr2)
   for i = 1, #arr2 do
      arr1[#arr1 + 1] = arr2[i]
   end
end

---Appends a piece of an html partial to a partial
---@param arr partial
---@param val string | codepiece | partial
local function appendChunk(arr, val)
   -- If the new element and last element are strings, attach them
   if type(val) == "string" and type(arr[#arr]) == "string" then
      arr[#arr] = arr[#arr] .. val
   elseif type(val) == "table" then
      for i = 1, #val do
         appendChunk(arr, val[i])
      end
   else
      table.insert(arr, val)
   end
end

--- Element Factory
---@param tag string
---@param opts? opts
---@return fun(data: table<number|string, string|codepiece|partial>): partial
local function Element(tag, opts)
   opts = opts or {}

   return function(data)
      local attributes = {}
      local contents = {}

      for index, value in pairs(data) do
         if type(index) == "string" then
            -- If the key is a string, then it's an attribute
            -- attributes = attributes .. string.format(' %s="%s"', index:gsub("_", "-"), value)
            appendChunk(attributes, string.format(' %s="', index:gsub("_", "-")))
            appendChunk(attributes, value)
            appendChunk(attributes, '"')
         elseif type(index) == "number" then
            -- If the key is a number, then it's a child element
            appendChunk(contents, value)
         end
      end

      -- Add opening tag
      if type(attributes[1]) == "string" then
         attributes[1] = "<" .. tag .. attributes[1]
         appendChunk(attributes, ">")
      elseif #attributes == 0 and type(contents[1]) == "string" then
         contents[1] = "<" .. tag .. ">" .. contents[1]
      else
         table.insert(attributes, 1, "<" .. tag)
         appendChunk(attributes, ">")
      end

      join(attributes, contents)

      if not opts.singleton then
         appendChunk(attributes, string.format("</%s>", tag))
      end

      return attributes
   end
end

---Renders an HTML chunk
---@param partial partial
---@param writer? fun(str: string) Handles the render html output, will be called multiple times as the rendering occurs. If left blank, render will return a string of the rendered html
---@param opts? table<string, any>
---@return nil | string
local function render(partial, writer, opts)
   local out = nil
   if not writer then
      out = ""
      writer = function(str)
         out = out .. str
      end
   end
   opts = opts or {}

   -- Escape any strings in the input opts
   for key, value in pairs(opts) do
      if type(value) == "string" then
         opts[key] = value:gsub('"', "&quot;"):gsub("<", "&lt;"):gsub(">", "&gt;")
      end
   end

   -- Render and gather html fragments
   for _, item in ipairs(partial) do
      if type(item) == "string" then
         writer(item)
      elseif type(item) == "function" then
         writer(item(opts))
      end
   end

   return out
end

---Allows you to write html without having to predefine the tags
---@param inner fun(): partial
---@return partial
---Ex.
--```lua
--local function foo() return div { p { function(opts) return "Hello " .. opts.name end } } end
--local fragment = html(foo) -- Build the fragment using html to build the tags
--render(fragment, nil, { name = "Bar" }) -- We can now render the fragment as usual!
--```
local function html(inner)
   fenv.setfenv(
      inner,
      setmetatable({}, {
         __index = function(self, tag)
            return Element(tag)
         end,
      })
   )

   return inner()
end

return {
   Element = Element,
   render = render,
   html = html,
}
