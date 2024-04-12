---- An attempt to create a Brainfuck virtual machine

---- Consts

TOKENS = {
   [">"] = 62,
   ["<"] = 60,
   ["+"] = 43,
   ["-"] = 45,
   ["."] = 46,
   [","] = 44,
   ["["] = 91,
   ["]"] = 93,
}

CHARMAP = {
   [62] = ">",
   [60] = "<",
   [43] = "+",
   [45] = "-",
   [46] = ".",
   [44] = ",",
   [91] = "[",
   [93] = "]",
}

OPERATORS = {
   [62] = ">",
   [60] = "<",
   [43] = "+",
   [45] = "-",
   [46] = ".",
   [44] = ",",
}

---- Parser

---@class Parser
---@field opmap table<integer, string>
---@field source string[]
---@field cur string
---@field peek string
---@field program (string | table)[]
local Parser = {}

function Parser:New(source)
   local obj = {}

   obj.source = { string.byte(source, 1, #source) }
   obj.ptr = 1

   obj.cur = obj.source[1]
   obj.peek = obj.source[2]

   obj.program = {}

   setmetatable(obj, self)
   self.__index = self

   return obj
end

function Parser:next()
   self.ptr = self.ptr + 1
   self.cur = self.source[self.ptr]
end

function Parser:error(msg)
   -- TODO: Track row and column numbers during parsing
   return string.format("%d:%d >> Error >> %s", 0, self.ptr, msg)
end

function Parser:Parse()
   while self.cur ~= nil do
      -- Check for a loop
      if self.cur == 91 then -- [
         local loop, err = self:parseLoop()
         -- Stop if we encountered an error while parsing the loop
         if err then
            return nil, err
         end

         table.insert(self.program, loop)
      elseif self.cur == 93 then -- ]
         -- We shouldn't ever see a closing bracket outside of parseLoop
         return nil, self:error("Unexpected ] encountered")
      end

      -- Ingest valid non-loop tokens

      if OPERATORS[self.cur] ~= nil then
         table.insert(self.program, self.cur)
      end

      self:next()
   end

   return self.program, nil
end

function Parser:parseLoop()
   -- TODO: Keep track of the start position for error reporting
   -- local row = self.row
   -- local col = self.col

   local loop = {}

   self:next()

   while self.cur ~= nil do
      -- Recursively parse if we see a new loop
      if self.cur == 91 then -- [
         local inner, err = self:parseLoop()
         if err then
            return nil, err
         end
         table.insert(loop, inner)
      -- Stop when we see a closing bracket
      elseif self.cur == 93 then -- ]
         return loop, nil
      end

      -- Until then continue ingesting code into the loop
      if OPERATORS[self.cur] ~= nil then
         table.insert(loop, self.cur)
      end
      self:next()
   end

   return nil, self:error("Unclosed bracket")
end

function Parser:printInner(program, depth)
   depth = depth or 0

   local out = ""
   local space = true

   local indent = ""
   for _ = 0, depth do
      indent = indent .. "  "
   end

   for _, node in ipairs(program) do
      if type(node) == "table" then
         space = true
         out = out .. "\n" .. indent .. "["
         out = out .. "\n" .. self:printInner(node, depth + 1)
         out = out .. "\n" .. indent .. "]" .. "\n"
      else
         if space then
            out = out .. indent
         end
         out = out .. CHARMAP[node]
         space = false
      end
   end

   return out
end

function Parser:PrettyPrint()
   print(self:printInner(self.program, 0))
end

-- local prog = "--+><[--[++]]><"

local prog = [[
-,+[                         Read first character and start outer character reading loop
    -[                       Skip forward if character is 0
        >>++++[>++++++++<-]  Set up divisor (32) for division loop
                               (MEMORY LAYOUT: dividend copy remainder divisor quotient zero zero)
        <+<-[                Set up dividend (x minus 1) and enter division loop
            >+>+>-[>>>]      Increase copy and remainder / reduce divisor / Normal case: skip forward
            <[[>+<-]>>+>]    Special case: move remainder back to divisor and increase quotient
            <<<<<-           Decrement dividend
        ]                    End division loop
    ]>>>[-]+                 End skip loop; zero former divisor and reuse space for a flag
    >--[-[<->+++[-]\]\]<[         Zero that flag unless quotient was 2 or 3; zero quotient; check flag
        ++++++++++++<[       If flag then set up divisor (13) for second division loop
                               (MEMORY LAYOUT: zero copy dividend divisor remainder quotient zero zero)
            >-[>+>>]         Reduce divisor; Normal case: increase remainder
            >[+[<+>-]>+>>]   Special case: increase remainder / move it back to divisor / increase quotient
            <<<<<-           Decrease dividend
        ]                    End division loop
        >>[<+>-]             Add remainder back to divisor to get a useful 13
        >[                   Skip forward if quotient was 0
            -[               Decrement quotient and skip forward if quotient was 1
                -<<[-]>>     Zero quotient and divisor if quotient was 2
            ]<<[<<->>-]>>    Zero divisor and subtract 13 from copy if quotient was 1
        ]<<[<<+>>-]          Zero divisor and add 13 to copy if quotient was 0
    ]                        End outer skip loop (jump to here if ((character minus 1)/32) was not 2 or 3)
    <[-]                     Clear remainder from first division if second division was skipped
    <.[-]                    Output ROT13ed character from copy and clear it
    <-,+                     Read next character
]
]]

local test_parser = Parser:New(prog)
local test_program, err = test_parser:Parse()

if err then
   print(err)
   os.exit(1)
end

test_parser:PrettyPrint()

---- Machine State

-- Holds the current cell index
local Cell = 0

-- Holds memory cell state
local State = { [0] = 0 }

---- Operator Code

-- Increment byte
local function binc()
   -- Overflow to 0 for byte simulation
   State[Cell] = State[Cell] + 1 % 256
end

-- Decrement byte
local function bdec()
   State[Cell] = State[Cell] - 1
   -- Underflow to 255 for byte simulation
   if State[Cell] < 0 then
      State[Cell] = 255
   end
end

-- Increment pointer
local function pinc()
   Cell = Cell + 1
   if not State[Cell] then
      State[Cell] = 0
   end
end

-- Decrement pointer
local function pdec()
   Cell = Cell - 1
   if not State[Cell] then
      State[Cell] = 0
   end
end

-- Output 1 byte to stdout
local function output()
   io.write(string.char(State[Cell]))
end

-- Accept 1 byte of input from stdin
local function input()
   -- FIXME: This is semi-broken tbh, we read the first char of an entire line from stdin
   State[Cell] = string.byte(io.read(), 1, 1) % 256
end

local function parse_braces() end

---- Interpreter

-- Map tokens to instructions
local OpMap = {
   [">"] = pinc,
   ["<"] = pdec,
   ["+"] = binc,
   ["-"] = bdec,
   ["."] = output,
   [","] = input,
}
