local function extension(target)
   local mt = getmetatable(target)

   -- If the target doesn't already have a metatable, let's make an empty one for them
   if mt == nil then
      setmetatable(target, { __index = {} })
      mt = getmetatable(target)
   end

   return function(extensions)
      for key, value in pairs(extensions) do
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
end

return extension
