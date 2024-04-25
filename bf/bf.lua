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

NEWLINES = {
   [10] = true,
   [13] = true,
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

   obj.row = 1
   obj.col = 1

   obj.cur = obj.source[1]

   obj.program = {}

   setmetatable(obj, self)
   self.__index = self

   return obj
end

function Parser:next()
   self.ptr = self.ptr + 1
   self.cur = self.source[self.ptr]
end

function Parser:isValid()
   if OPERATORS[self.cur] ~= nil then
      return true
   elseif NEWLINES[self.cur] then
      self.row = self.row + 1
      self.col = 0
   end
   return false
end

function Parser:ParseNext()
   self:next()

   -- Skip non-operator tokens
   while self.cur ~= nil and not Parser:isValid() do
      self:next()
   end

   return TOKENS[self.cur]
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

---- Virtual Machine

---@class Machine
---@field cell integer
---@field state integer[]
---@field opMap table<integer, function>
---@field jumpMap table<integer, integer>
local Machine = {}

function Machine:New()
   local obj = {
      cell = 0,
      state = { [0] = 0 },
      opMap = {
         [62] = self.pinc,
         [60] = self.pdec,
         [43] = self.binc,
         [45] = self.bdec,
         [46] = self.output,
         [44] = self.input,
      },
   }

   setmetatable(obj, self)
   self.__index = self

   return obj
end

-- Increment byte
function Machine:binc()
   -- Overflow to 0 for byte simulation
   self.state[self.cell] = (self.state[self.cell] + 1) % 256
end

-- Decrement byte
function Machine:bdec()
   self.state[self.cell] = self.state[self.cell] - 1
   -- underflow to 255 for byte simulation
   if self.state[self.cell] < 0 then
      self.state[self.cell] = 255
   end
end

-- Increment pointer
function Machine:pinc()
   self.cell = self.cell + 1
   if not self.state[self.cell] then
      self.state[self.cell] = 0
   end
end

-- Decrement pointer
function Machine:pdec()
   self.cell = self.cell - 1
   if not self.state[self.cell] then
      self.state[self.cell] = 0
   end
end

-- Output 1 byte to stdout
function Machine:output()
   io.write(string.char(self.state[self.cell]))
end

-- Accept 1 byte of input from stdin
function Machine:input()
   self.state[self.cell] = string.byte(io.read(1)) % 256
end

---Evaluates a chunk of Brainfuck code
---@param program string
function Machine:Eval(program)
   local parser = Parser:New(program)

   local prog = {}
   local jumpMap = {}
   local loopStack = {}

   local op = parser:ParseNext()
   while op ~= nil do
      -- If it's an open [
      if op == 91 then
         table.insert(prog, op)
         table.insert(loopStack, #prog)
      -- If it's a close ]
      elseif op == 93 then
         if #loopStack == 0 then
            print("Error, unmatched ]")
            return
         end

         local open = table.remove(loopStack, #loopStack)

         -- Set locations for jumps
         jumpMap[open] = #prog + 1
         jumpMap[#prog] = open + 1

         table.insert(prog, op)
      end

      op = parser:ParseNext()
   end
end

function Machine:PrettyPrint()
   local fmt = [[

|---------|-------|-------|-------|-------|-------|
| Mem Ptr | %05d | %05d | %05d | %05d | %05d |
|---------|-------|-------|-------|-------|-------|
| Mem Val |  %03d  |  %03d  |  %03d  |  %03d  |  %03d  |
|---------|---<<--|---<---|---|---|--->---|-->>---|
]]
   local out = fmt:format(
      self.cell - 2,
      self.cell - 1,
      self.cell,
      self.cell + 1,
      self.cell + 2,
      self.state[self.cell - 2] or 0,
      self.state[self.cell - 1] or 0,
      self.state[self.cell],
      self.state[self.cell + 1] or 0,
      self.state[self.cell + 2] or 0
   )
   print(out)
end

local function REPL()
   local vm = Machine:New()
   vm:PrettyPrint()

   local input = ""
   while input ~= nil do
      io.write("> "):flush()
      input = io.read()

      local parser = Parser:New(input)
      local program, err = parser:Parse()

      if err then
         print(err)
      else
         vm:Eval(program)
         vm:PrettyPrint()
      end
   end
end

REPL()
