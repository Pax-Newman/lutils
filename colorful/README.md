
# Colorful

Provides a simple interface for styling strings with ANSI formatters.

## Usage

```lua
local clr = require('lutils.colorful')

-- Wrap a string with additional functionality
local str = clr.Style "Hello World"

-- Apply formatter by indexing the string accordingly
print(str.italic)

-- You can chain formatters as you'd like
print(str.italic.blink.underline)

-- Apply foreground and background colors in several ways
str.fg(0x808080) -- As a function
str.fg[0x808080] -- as an index

str.bg(0x808080) -- Background
str.bg[0x808080]

-- For ease of use you can also register colors

clr.SetColor("orange", 0xed7637)

str.fg("orange") -- You can reference the color in a function
str.fg.orange -- Or you can use it as an index

-- As an additional comfort, wrapping a string also provides easier string formatting

local greeting = clr.style("Hello %s!")

print(greeting % { "Foo" })

```

