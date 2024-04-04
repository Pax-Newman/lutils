---- An experiment on DSLs and backend html generation

---Options for creating a new element
---@alias opts { singleton? : boolean }
---Partially rendered html piece
---@alias partial (string|fun(opts: table<string, any>): string)[]
---A piece of dynamic rendering code in an html partial
---@alias codepiece fun(opts?: table<string, any>): string | partial

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

      -- TODO: Consider changing from a list
      -- to an fstring which the results of functions
      -- can be injected into

      for index, value in pairs(data) do
         if type(index) == "string" then
            -- If the key is a string, then it's an attribute
            -- attributes = attributes .. string.format(' %s="%s"', index:gsub("_", "-"), value)
            -- NOTE: Consider reducing number of calls to appendChunk, think about letting that func take
            -- multiple string params that all get joined
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
---@param writer? fun(str: string) Handles the render html output, will be called multiple times as the rendering occurs. If left nil, render will return a string of the rendered html
---@param opts? table<string, any>
---@return nil | string
local function render(partial, writer, opts)
   local out = nil
   if writer == nil then
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
      if type(item) == "function" then
         local result = item(opts)
         if type(result) == "table" then
            render(result, writer, opts)
         else
            writer(result)
         end
      else
         writer(item)
      end
   end

   return out
end

---Retrieves a render-time parameter
---@param param string
---@param default any Fallback if opts.param == nil
---@return fun(opts: table<string, any>): any
local function get(param, default)
   assert(type(param) == "string", "item should be a string")
   return function(opts)
      local val = opts[param]
      assert(val or default, "%s was found to be nil with no default set")
      return val or default
   end
end

---Format a string using parameters passed in at render time
---@param fstring string
---@param params (string | codepiece)[]
---@return fun(opts: table<string, any>): string
local function format(fstring, params)
   return function(opts)
      local vals = {}
      for _, param in ipairs(params) do
         if type(param) == "function" then
            table.insert(vals, param(opts))
         else
            local val = opts[param]
            assert(val, "%s was a nil value while formatting" % { param })
            table.insert(vals, opts[param])
         end
      end
      return fstring % vals
   end
end

local exports = {
   render = render,
   format = format,
   get = get,
}

local singletons = {
   area = true,
   base = true,
   br = true,
   col = true,
   command = true,
   embed = true,
   hr = true,
   img = true,
   input = true,
   keygen = true,
   link = true,
   meta = true,
   param = true,
   source = true,
   track = true,
   wbr = true,
}

local cache = {}

return setmetatable({}, {
   __index = function(_, idx)
      if exports[idx] then
         return exports[idx]
      elseif cache[idx] then
         return cache[idx]
      else
         cache[idx] = Element(idx, { singleton = singletons[idx] })
         return cache[idx]
      end
   end,
})
