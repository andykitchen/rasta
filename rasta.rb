module Rasta
require 'strscan'

# We are going to need a really flexible buffer implementation
# for incremental parsing, why the native ruby StringScanner doesn't
# work on streams is beyond me. however we use it for now.

# class Buffer
#   
# end

def Builder; end

class Rule
  attr_accessor :name
    
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
  # or a Failure object, nil means this rule doesn't
  # generate any AST
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
    s = Sequence.new(self)
    s >> rule
  end
  
  def <<(rule)
    s = Sequence.new(self)
    s << rule
  end
  
  def |(rule)
    Choice.new(self, rule)
  end
  
  def fail(rule, inner_failure = nil, info = {})
    Failure.new(inner_failure, info.merge(:rule => rule))
  end
end

class Failure
  attr_reader :context
  
  def initialize(inner_failure, info = {})
    @context = Array.new
    @context += inner_failure.context if inner_failure
    @context << info
  end
  
  def inspect
    "Parse Failure:\n" +
    @context.join("\n")
  end
end

class Terminal < Rule
  def initialize(terminal)
    super()
    
    self.name = terminal.inspect
    
    if terminal.class == String
      @terminal = /#{Regexp.quote(terminal)}/
    else
      @terminal = terminal
    end
    
  end

  def parse(buffer, builder)
    if s = buffer.scan(@terminal)
      builder.node(self, nil, :string => s)
    else
      fail(self)
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
  # TODO Sequences seem to know too much now
  attr_reader   :flattens
  attr_accessor :trans
  
  def initialize(*rules)
    super
    @flattens = {}
  end
  
  def parse(buffer, builder)
    c = []
    
    for x in @rules
      n = x.parse(buffer, builder)
      
      if n.class == Failure
        return fail(self, n)
      else
        if @flattens[x] then
          # TODO find a more elegant way to do this
          if n.class == Array then
            c += n
          elsif n.respond_to?(:children)
            c += n.children
          end
          
          # TODO throw an error or something here
        else
          c << n
        end
      end
    end
    
    c.compact!
    
    if @trans && c.length == 1
      c[0]
    else
      builder.node(self, c)
    end
  end
    
  def >>(rule)
    @rules << rule
    
    self
  end
  
  def <<(rule)
    if rule.class == Sequence
      @rules = @rules + rule.rules
      @flattens.merge!(rule.flattens)
    else
      @rules << rule
      @flattens[rule] = true
    end
    
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
    
    for x in @rules
      pos = buffer.pos
      n = x.parse(buffer, builder)
      
      if n.class != Failure
        return n
      else
        buffer.pos = pos
      end
    end
    
    fail(self, n)
  end
  
  def |(rule)
    @rules << rule
    
    self
  end
end

def choose(*rules)
  Sequence.new(*rules)
end

# Covers zero-or-more, one-or-more and optional
class More < Rule
  def initialize(rule, min = 0, max = -1)
    super()
    @rule = rule
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
      c.compact!
      builder.node(self, c)
    else
      buffer.pos = pos
      fail(self)
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
      nil
    else
      fail(self)
    end
  end
end

def has(rule)
  Peek.new(rule)
end

def has_not(rule)
  Peek.new(rule, true)
end

require 'builder'
require 'action'
require 'inspect'

end # module Rasta
