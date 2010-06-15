module Rasta
require 'builder'
require 'strscan'

# We are going to need a really flexible buffer implementation
# for incremental parsing, why the native ruby StringScanner doesn't
# work on streams is beyond me. however we use it for now.

# class Buffer
#   
# end

class Rule
  attr_accessor :debug
  
  def initialize
    @debug = false
  end
  
  def parse?(string)
    ss = StringScanner.new(string)
    x = self.parse(ss, Builder.new)
    
    if @debug && x.class == Failure
      p x
    end
    
    x.class != Failure && ss.eos?
  end
  
  def parse_str(string, builder = Builder.new)
    ss  = StringScanner.new(string)
    self.parse(ss, builder)
  end
  
  # This function returns a piece of ast on success
  # and nil on failure
  def parse(buffer, builder)
    nil
  end
  
  def plus
    More.new(self, 1)
  end
  
  def star
    More.new(self, 0)
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
  
  def fail(inner_failure, info = {})
    Failure.new(inner_failure, info)
  end
end

class Failure
  attr_reader :context
  
  def initialize(inner_failure, info = {})
    @context = Array.new
    @context += inner_failure.context if inner_failure
    @context << info
  end
end

class Terminal < Rule
  def initialize(terminal)
    super()
    @terminal = terminal
  end

  def parse(buffer, builder)
    if @terminal.class == Regexp then
      s = buffer.scan(@terminal)
    elsif @terminal == buffer.peek(@terminal.length)
      s = @terminal
      buffer.pos += @terminal.length
    else
      s = nil
    end 
    
    if s
      builder.node(self, nil, :string => s)
    else
      fail(nil, :rule => self)
    end
  end
end

def t(rule)
  Terminal.new(rule)
end

class BlockRule < Rule
  def initialize(&block)
    super()
    @block = block
  end
  
  def parse(buffer, builder)
    @block[buffer, builder]
  end  
end

# This is a special class that allows bindings wrangling
class RuleRef < BlockRule
  def parse(buffer, builder)
    ref = @block.call
    ref.parse(buffer, builder)
  end  
end

def ref(&block)
  RuleRef.new(&block)
end

class MultiRule < Rule
  attr_accessor :rules
  
  def initialize(*rules)
    super()
    @rules = rules.flatten
  end
end

# Covers sequence rules
class Sequence < MultiRule  
  def parse(buffer, builder)
    c = []
    
    @rules.each do |x|
      n = x.parse(buffer, builder)
      
      if n.class == Failure
        return fail(n, :rule => self)
      else
        c << n
      end
    end
    
    builder.node(self, c)
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
  def parse(buffer, builder)
    n = nil
    
    @rules.each do |x|
      n = x.parse(buffer, builder)
      
      return n if n.class != Failure
    end
    
    fail(n, :rule => self)
  end
end

def choose(*rules)
  Sequence.new(*rules)
end

# Covers zero-or-more, one-or-more and optional
class More < Rule
  def initialize(rule, min = 0, max = -1)
    super()
    @rule  = rule
    @min = min
    @max = max
  end
  
  def parse(buffer, builder)
    pos = buffer.pos
    c = []
    
    while (n = @rule.parse(buffer, builder)).class != Failure
      c << n
      
      if @max > 0 && c.length >= @max then
        break
      end
    end
    
    if c.length >= @min
      builder.node(self, c)
    else
      buffer.pos = pos
      fail(nil, :rule => self)
    end
  end
  
end

# Covers and and not syntactic predicates
class Peek < Rule
  def initialize(rule, negate = false)
    super()
    @rule   = rule
    @negate = negate
  end
  
  def parse(buffer, builder)
    pos = buffer.pos
    n = @rule.parse(buffer, builder)
    buffer.pos = pos
    if (n.class != Failure) ^ @negate then
      builder.node(self)
    else
      fail(nil, :rule => self)
    end
  end
end

def has(rule)
  Peek.new(rule)
end

def has_not(rule)
  Peek.new(rule, true)
end

end # module Rasta
