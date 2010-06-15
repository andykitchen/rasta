module Rasta
require 'strscan'

# We are going to need a really flexible buffer implementation
# for incremental parsing, why the native ruby StringScanner doesn't
# work on streams is beyond me. however we use it for now.

# class Buffer
#   
# end

class Rule
  def parse?(string)
    run_parse(string) != nil
  end
  
  def run_parse(string)
    ss  = StringScanner.new(string)
    self.parse(ss)
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
  attr_accessor :value, :children
  
  def initialize(children, value = {})
    @value    = value
    @children = [children].flatten
  end
  
  def inspect
    print "\n-----\n"
    pretty_print(0)
    print "\n-----\n"
  end
  
  def pretty_print(indent)
    x = @value[:string] || @value[:rule]
    
    puts "#{"  "*indent}#{x}"
    @children.each do |x|
      if x.respond_to?(:pretty_print)
        x.pretty_print(indent + 1)
      elsif x
        puts "#{"  "*(indent + 1)}#{x.inspect}"
      end
    end
  end
  
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
    
    n = Node.new(nil, :string => s, :rule => self)
    
    if s then n else nil end
  end
end

def t(rule)
  Terminal.new(rule)
end

class BlockRule < Rule
  def initialize(&block)
    @block = block
  end
  
  def parse(buffer)
    @block.call(buffer)
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

class MultiRule < Rule
  def initialize(*rules)
    @rules = rules.flatten
  end
end

# Covers sequence rules
class Sequence < MultiRule  
  def parse(buffer)
    c = []
    
    @rules.each do |x|
      n = x.parse(buffer)
      
      if n
        c << n
      else
        return nil
      end
    end
    
    Node.new(c, :rule => self)
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
    @rules.each do |x|
      n = x.parse(buffer)
      
      # return Node.new(n, :rule => self) if n
      return n if n
    end
    
    nil
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
    c = []
    
    while n = @rule.parse(buffer)
      c << n
      
      if @max > 0 && c.length >= @max then
        break
      end
    end
    
    if c.length >= @min
      Node.new(c, :rule => self)
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
    n = @rule.parse(buffer)
    buffer.pos = pos
    if (n != nil) ^ @negate then
      Node.new(n, :rule => self)
    else
      nil
    end
  end
end

end # module Rasta
