local function extension(t)
   local target = t[1]

   assert(target ~= nil, "First element of the table must not be nil")

   local mt = getmetatable(target)

   -- If the target doesn't already have a metatable, let's make an empty one for them
   if mt == nil then
      setmetatable(target, { __index = {} })
      mt = getmetatable(target)
   end

   for key, value in pairs(t) do
      if type(key) ~= "string" then
         goto continue
      end

      -- Set metatable value directly
      if key:sub(1, 2) == "__" then
         mt[key] = value
      -- Set the value in the metatable index
      else
         mt.__index[key] = value
      end

      ::continue::
   end

   return target
end

return extension
