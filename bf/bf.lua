---- An attempt to create a Brainfuck virtual machine

---- Parser

---@class Parser
---@field source string[]
---@field cur string
---@field peek string
---@field program (string | table)[]
local Parser = {}

function Parser:New(source)
   local obj = {}

   -- PERF: Storings chars as an int may be more space and time efficient
   local chars = {}
   for char in source:gmatch(".") do
      table.insert(chars, char)
   end

   obj.source = chars
   obj.ptr = 1

   obj.cur = chars[1]
   obj.peek = chars[2]

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

function Parser:eatValid()
   if string.match("><+-.,", self.cur) ~= nil then
      table.insert(self.program, self.cur)
   end
end

function Parser:Parse()
   while self.cur ~= nil do
      -- Check for a loop
      if self.cur == "[" then
         local loop, err = self:parseLoop()
         -- Stop if we encountered an error while parsing the loop
         if err then
            return nil, err
         end

         table.insert(self.program, loop)
      elseif self.cur == "]" then
         -- We shouldn't ever see a closing bracket outside of parseLoop
         return nil, self:error("Unexpected ] encountered")
      end

      -- Ingest valid non-loop tokens
      self:eatValid()

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
      if self.cur == "[" then
         local inner, err = self:parseLoop()
         if err then
            return nil, err
         end
         table.insert(loop, inner)
      -- Stop when we see a closing bracket
      elseif self.cur == "]" then
         return loop, nil
      end

      -- Until then continue ingesting code
      if string.match("><+-.,", self.cur) ~= nil then
         table.insert(loop, self.cur)
      end
      self:next()
   end

   return nil, self:error("Unclosed bracket")
end

function Parser:printInner(program, depth)
   depth = depth or 0

   local indent = ""
   for _ = 0, depth do
      indent = indent .. "  "
   end

   for _, node in ipairs(program) do
      if type(node) == "table" then
         print(indent .. "[")
         self:printInner(node, depth + 1)
         print(indent .. "]")
      else
         print(indent .. node)
      end
   end
end

function Parser:PrettyPrint()
   self:printInner(self.program, 0)
end

local prog = "-[[+]]-"

local test_parser = Parser:New(prog)
local test_program, err = test_parser:Parse()

if err then
   print(err)
   os.exit(1)
end

test_parser:PrettyPrint()
