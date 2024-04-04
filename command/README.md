
# Command Runner

Command is a module for building small command line tools.
Originally this was created for making build scripts so I didn't have to use `make` in cursed ways,
so the usage is modelled after that.

## Usage

### Basics

To start out lets create a command runner and try running it.

```lua
--foo.lua

local cmd = require("lutils.command").new()

cmd:run(args)
```

Now we can try running our command.

```
> lua foo.lua help
        help:           Displays this help message
```

### Adding Commands

```lua
cmd:add(
    "time", -- Set the command name
    "Displays the current time", -- The help string
    function () -- Command body
        print(os.date("%X"))
    end,
)
```

```
> lua foo.lua time
15:32:56
```

Since this is modelled after make, you can run multiple commands one after another.

```
> lua foo.lua time time
15:32:56
15:32:56
```

### Options

```lua
cmd:add(
    "add",
    "Adds two numbers",
    {
        x = {
            help = "The first number",
            default = 0,
        },
        y = {
            help = "The second number",
            default = 0,
        },
    },
    function (opts)
        print(string.format("%d + %d = %d", opts.x, opts.y, opts.x + opts.y))
    end,
)
```

```
> lua foo.lua --x=2 --y=3
2 + 3 = 5
```

### Errors

If you want to stop execution due to an error, there is an `error` helper method similar to `assert` to cancel execution and print the help message.

```lua
cmd:add(
    "add",
    "Adds two numbers",
    {
        x = {
            help = "The first number",
            default = 0,
        },
        y = {
            help = "The second number",
            default = 0,
        },
    },
    function (opts)
        local x = cmd:error(opts.x >= 0, "x cannot be negative")
        local y = cmd:error(opts.y >= 0, "y cannot be negative")

        print(string.format("%d + %d = %d", x, y, x + y))
    end,
)
```
