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

function exports.prettytable(t)
   for key, value in pairs(t) do
      if type(value) == "table" then
         print(string.format("%s: {", key))
         exports.prettytable(value)
         print "}"
      else
         print(string.format("%s: %s", key, value))
      end
   end
end

return exports
