---Utility functions

local exports = {}

function exports.map(arr, fun)
   local res = {}
   for item in arr do
      table.insert(res, fun(item))
   end

   return table.unpack(res)
end

function exports.merge(t1, t2)
   for key, value in pairs(t2) do
      t1[key] = value
   end
   return t1
end

return exports
