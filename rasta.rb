# module Rasta

require 'strscan'

# We are going to need a really flexible buffer implementation
# for incremental parsing, why the native ruby StringScanner doesn't
# work on streams is beyond me. however we use it for now.

# class Buffer
#   
# end

class Rule    
  def parse?(string)
    ss  = StringScanner.new(string)
    ret = self.parse(ss)
    
    # if ret && ret.eos? then true else false end
  end
  
  # This function returns a piece of ast on success
  # and nil on failure
  def parse
    nil
  end
  
  def plus
    More.new(self, 1, -1)
  end
  
  def star
    More.new(self, 0, -1)
  end
  
  def opt
    More.new(self, 0, 1)
  end
  
  def >>(rule)
    Sequence.new(self, rule)
  end
  
  def |(rule)
    Choice.new(self, rule)
  end
end

class Node

end

def has(rule)
  Peek.new(rule)
end

def has_not(rule)
  Peek.new(rule, true)
end

class Terminal < Rule
  def initialize(terminal)
    @terminal = terminal
  end

  def parse(buffer)
    if @terminal.class == Regexp then
      s = buffer.scan(@terminal)
    elsif @terminal == buffer.peek(@terminal.length)
      s = @terminal
      buffer.pos += @terminal.length
    else
      s = nil
    end 
      
    # puts s
    if s then buffer else nil end
  end
end

def term(rule)
  Terminal.new(rule)
end

def BlockRule
  def initialize(&block)
    @block = block
  end
end

# This is a special class that allows bindings wrangling
class RuleRef < BlockRule
  def parse(buffer)
    ref = @block.call
    ref.parse(buffer)
  end  
end

def ref(&block)
  RuleRef.new(&block)
end

# This is a wild rule
class BlockRule < BlockRule
  def parse(buffer)
    @block.call(buffer)
  end  
end

class MultiRule
  def initialize(*rules)
    @rules = rules.flatten
  end
end

# Covers sequence rules
class Sequence < MultiRule  
  def parse(buffer)
    @rules.inject(true) do |a, x|
      a = a && x.parse(buffer)
    end
  end
  
  def >>(rule)
    @rules << rule
    self
  end
end

def seq(*rules)
  Sequence.new(*rules)
end

# class Array
#   def seq
#     Sequence.new(self)
#   end
# end

# Covers ordered choice rules
class Choice < MultiRule  
  def parse(buffer)
    @rules.inject(nil) do |a, x|
      a = a || x.parse(buffer)
    end
  end
end

def choose(*rules)
  Sequence.new(*rules)
end

# Covers zero-or-more, one-or-more and optional
class More < Rule
  def initialize(rule, min = 0, max = -1)
    @rule  = rule
    @min = min
    @max = max
  end
  
  def parse(buffer)
    pos = buffer.pos
    count = 0
    
    while @rule.parse(buffer)
      count += 1
      
      if @max > 0 && count >= @max then
        break
      end
    end
    
    if count >= @min
      buffer
    else
      buffer.pos = pos
      nil
    end
  end
  
end

# Covers and and not syntactic predicates
class Peek < Rule
  def initialize(rule, negate = false)
    @rule   = rule
    @negate = negate
  end
  
  def parse(buffer)
    pos = buffer.pos
    ret = @rule.parse(buffer)
    buffer.pos = pos
    if (ret != nil) ^ @negate then
      buffer
    else
      nil
    end
  end
end

def test1
  a = nil
  b = nil
  
  ta = Terminal.new(/a/)
  tb = Terminal.new(/b/)
  tc = Terminal.new(/c/)

  peek  = Peek.new(Sequence.new(RuleRef.new{a}, tc))
  peek2 = Peek.new(Terminal.new(/[abc]/), true)
  morea = More.new(ta, 1)
  a = Sequence.new(ta, More.new(RuleRef.new{a}, 0, 1), tb)
  b = Sequence.new(tb, More.new(RuleRef.new{b}, 0, 1), tc)

  Sequence.new(peek, morea, RuleRef.new{b}, peek2)
end

def test2
  a = nil
  b = nil
  
  ta = term("a")
  tb = term("b")
  tc = term("c")
  
  peek  = has(ref{a} >> tc)
  peek2 = has_not(term(/[abc]/))
  
  morea = ta.plus
  
  a = seq ta, ref{a}.opt, tb
  b = seq tb, ref{b}.opt, tc
  
  seq peek, morea, ref{b}, peek2
end

# end
