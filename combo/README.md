
# Combo

A small parser combinator library

## Usage

Currently Combo only provides combinators for operating on string-to-string tasks.

```lua

local cb = require("combo")

-- Matches a single lowercase a character
local matchA = cb.char("a")

matchA {"a", "b", "c"} --> { success = true, value = {a}, rest = {b, c}, captures = {}}

-- If we're just dealing with string input, we can use cb.takeStr
-- to automatically convert string input to a character array
cb.takeStr(matchA) "abc" --> { success = true, value = {a}, rest = {b, c}, captures = {}}

-- All combinators return a result table
-- In a successful case it returns a table of the form:
--    { 
--       success = true,
--       value = { match_1, .., match_n },
--       rest = { leftover_1, .., leftover_m },
--       captures = { "A CAPTURE GROUP NAME" = any },
--    }
--
-- In an unsuccessful case it simply returns the following:
--    { success = false }

-- We can use combinators to quickly build up larger parsers

-- We can use cb.any to match any of a set of sub-parsers
-- Here we can make one that parses a single a or a single b
local AorB = cb.takeStr(cb.any(cb.char "a" , cb.char "b"))

AorB 'abc' --> success, val = {a}, rest = {b, c}
AorB 'bc'  --> success, val = {b}, rest = {c}

-- We could also create a parser programmatically like here where we can use a map
-- to create a parser that matches one of any alphabet character
local alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
local alpha = cb.any(utils.map(alphabet:gmatch ".", cb.char))

-- Or a function to create parsers easier
local function anyOf(str)
   return cb.any(utils.map(alphabet:gmatch ".", cb.char))
end

-- Now we can expand quickly!
local alpha = anyOf(alphabet) -- Matches one alphabet char
local numeric = anyOf("0123456789") -- Matches one numberic char
local alphanum = cb.any(alpha, numeric) -- Matches one alphanumeric char

-- If we want to parse longer structure we could use atLeast
local word = cb.atLeast(1, alpha) -- This parses alphabet strings that are at least 1 char long

cb.takeStr(word) "abc"  --> success, value = {a, b ,c}, rest = {}
cb.takeStr(word) "abc123" --> success, value = {a, b, c}, rest = {1, 2, 3}
cb.takeStr(word) "123abc" --> fail

-- If we wanted an exact sequence we could use... cb.sequence!
local abc = cb.takeStr(cb.sequence(char "a", char "b", char "c")) -- Matches 'abc'

abc 'abc' --> success, value = {a, b, c}, rest = {}
abc 'ab' --> fail

-- We can use this to parse more complex things, like a decimal number!
local integer = cb.atLeast(1, numeric)
local float = cb.sequence(integer, cb.char ".", integer)

-- Another powerful combinator is cb.optional
-- This allows us to define a parser as optional, meaning that it will succeed even
-- if nothing was parsed

-- Parses an identifier, which must start with a letter, but can then contain any
-- combination of letters and numbers
local identifier = cb.sequence(alpha, cb.optional(cb.atLeast(1, cb.any(alpha, integer))))

```

Other examples can be found in `test.lua`

