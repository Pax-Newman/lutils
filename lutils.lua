---- Imports sub-modules

package.path = package.path .. ";?/?.lua"

return {
   html = require("html"),
   enumerable = require("enumerable"),
   command = require("command"),
   fenv = require("fenv"),
   itertools = require("itertools"),
   streams = require("streams"),
}
