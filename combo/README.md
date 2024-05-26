
# Combo

A small parser combinator library

## Usage

Currently Combo only provides combinators for operating on string-to-string tasks.

```lua

local sc = require("combo").string2string

-- Matches a single lowercase a character
local matchA = sc.char("a")

matchA("abc") --> { success = true, value = "a", rest = "bc", captures = {}}

-- All combinators return a result table
-- In a successful case it returns a table of the form:
--    { 
--       success = true,
--       value = "MATCHES",
--       rest = "LEFTOVERS",
--       captures = { "A CAPTURE GROUP NAME" = "SUB-MATCHES" },
--    }

-- We can use combinators to quickly build up larger parsers

-- We can use sc.any to match any of a set of sub-parsers
-- Here we can make one that parses a single a or a single b
local AorB = sc.any(sc.char "a" , sc.char "b")

AorB 'abc' --> success, val = a, rest = bc
AorB 'bc'  --> success, val = b, rest = c

-- We could also create a parser programmatically like here where we can use a map
-- to create a parser that matches one of any alphabet character
local alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
local alpha = sc.any(utils.map(alphabet:gmatch ".", sc.char))

-- Or a function to create parsers easier
local function anyOf(str)
   return sc.any(utils.map(alphabet:gmatch ".", sc.char))
end

-- Now we can expand quickly!
local alpha = anyOf(alphabet) -- Matches one alphabet char
local numeric = anyOf("0123456789") -- Matches one numberic char
local alphanum = sc.any(alpha, numeric) -- Matches one alphanumeric char

-- If we want to parse longer structure we could use atLeast
local word = sc.atLeast(1, alpha) -- This parses alphabet strings that are at least 1 char long

word "abc"  --> success, value = abc, rest = ''
word "abc123" --> success, value = abc, rest = 123
word "123abc" --> failure

-- If we wanted an exact sequence we could use... sc.sequence!
local abc = sc.sequence(char "a", char "b", char "c") -- Matches 'abc'

abc 'abc' --> success, value = abc, rest = ''
abc 'ab' --> fail

-- We can use this to parse more complex things, like a decimal number!
local integer = sc.atLeast(1, numeric)
local float = sc.sequence(integer, sc.char ".", integer)

-- Another powerful combinator is sc.optional
-- This allows us to define a parser as optional, meaning that it will succeed even
-- if nothing was parsed

-- Parses an identifier, which must start with a letter, but can then contain any
-- combination of letters and numbers
local identifier = sc.sequence(alpha, sc.optional(sc.atLeast(1, sc.any(alpha, integer))))

```

Other examples can be found in `test.lua`

