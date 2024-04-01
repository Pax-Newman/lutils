---- Implements setfenv and getfenv

---Sets the _ENV for a function
---@param fn function
---@param env table<any, any>
---@return function
local function setfenv(fn, env)
   local i = 1
   while true do
      local name = debug.getupvalue(fn, i)
      if name == "_ENV" then
         debug.upvaluejoin(fn, i, function()
            return env
         end, 1)
         break
      elseif not name then
         break
      end

      i = i + 1
   end

   return fn
end

---Gets the _ENV for a function
---@param fn function
---@return table | nil
local function getfenv(fn)
   local i = 1
   while true do
      local name, val = debug.getupvalue(fn, i)
      if name == "_ENV" then
         return val
      elseif not name then
         break
      end
      i = i + 1
   end
end

return {
   setfenv = setfenv,
   getfenv = getfenv,
}
