------ Command Runner

---@alias option {help : string, default : any?}
---@alias options {[string] : option}
---@alias parsedOptions {[string] : string}

-- A simple command runner to make writing build/dev scripts easier
---@class Command
---@field commands table<string, {action : fun() | fun(opts: parsedOptions), options : options | nil, help : string}>
local Command = {}

function Command.new(setup)
   setup = setup or {}

   local config = {
      commands = setup.commands or {},
   }

   local command = setmetatable(config, Command)
   Command.__index = Command

   command:add("help", "Displays this help message", function()
      -- Sort the keys so we have a consistent order
      local cmds = {}
      for k in pairs(command.commands) do
         table.insert(cmds, k)
      end
      table.sort(cmds)

      -- Print keys and their help messages
      for _, cmd_name in ipairs(cmds) do
         local cmd = command.commands[cmd_name]
         print("\t%s:\t\t%s" % { cmd_name, cmd.help })

         table.sort(cmd.options or {}, function(a, b)
            return a.name < b.name
         end)
         for opt, details in pairs(cmd.options) do
            local default_str = ""
            if details.default then
               default_str = " (default: " .. details.default .. ")"
            end

            print("\t\t--%s:\t%s" % { opt, details.help } .. default_str)
         end
      end
   end)

   return command
end

---Add a command to the command runner
---@param name string Name of the command
---@param help string Help string to display for the command
---@param options? options
---@param action fun(opts?: parsedOptions) Function to run when the command is called
---@overload fun(self: Command, name: string, help: string, action: fun(opts?: parsedOptions))
function Command:add(name, help, options, action)
   if type(options) == "function" then
      action = options
      options = {}
   end

   self.commands[name] = {
      action = action,
      options = options,
      help = help,
   }
end

---Display help message
function Command:help()
   self.commands.help.action()
end

---Exits the program displaying a message and the help message on a falsey value
---Meant to be an analog to
---@param v? any
---@param message string? | nil
---@return any
---@overload fun(self: Command, v: any): any
function Command:error(v, message)
   if not v then
      print(message)
      self:help()
      os.exit(1)
   end
   return v
end

---Run one or more commands as specific in args
---@param args string[]
function Command:run(args)
   self:error(#args > 0, "No commands given")

   ---@type string[]
   local cmds = {}
   --         cmd      opt     opt-val
   ---@type { string: {string: string} }
   local options = {}

   -- Parse the commands and options
   local last_cmd
   for _, arg in ipairs(args) do
      -- If we have a command already and the next arg is an option
      if arg:match("--%S+='?[^'\"]+'?") then
         self:error(last_cmd, "Option given before command")

         -- Match --option=value and --option="val1 val2 ..."
         local opt, val = arg:match("--([^-%s]+)='?([^'\"]+)'?")
         self:error(self.commands[last_cmd].options[opt], "Option %s not found for command %s" % { opt, last_cmd })

         -- Add parsed option to the command's option table
         if options[last_cmd][opt] then
            options[last_cmd][opt] = options[last_cmd][opt] .. " " .. val
         else
            options[last_cmd][opt] = val
         end
      -- If the arg is a valid command
      elseif self.commands[arg] then
         table.insert(cmds, arg)
         last_cmd = arg
         options[last_cmd] = {}
      -- If it's neither a command nor an option, it's a syntax error
      else
         self:error(nil, "Argument %s neither a valid command or option" % { arg })
      end
   end

   -- Run each command with its options
   for _, cmd in ipairs(cmds) do
      -- Check for option defaults
      for opt, details in pairs(self.commands[cmd].options or {}) do
         if not options[cmd][opt] then
            options[cmd][opt] = details.default
         end
      end

      local _, err = pcall(self.commands[cmd].action, options[cmd])
      if err then
         print("Error running command '%s': %s" % { cmd, err })
         os.exit(1)
      end
   end
end

return Command
