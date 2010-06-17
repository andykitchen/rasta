module Rasta

class Rule
  def drop
    NoBuilder.new(self)
  end
  
  def mk_s
    StringBuilder.new(self)
  end
  
  def mk_i
    IntegerBuilder.new(self)
  end
  
  def mk_a
    ArrayBuilder.new(self)
  end
  
  def mk_list(sep)
    Rasta::flat(self >> (sep.drop >> self).unbox.star)
  end
  
end

class Builder < Rule
  def initialize(rule = nil)
    @rule = rule
  end
  
  def parse(buffer, builder)
    @rule.parse(buffer, self)
  end
  
  def node(rule, children = nil, value = {})
    true
  end
  
end

class Node
  # @@count = 0
    
  attr_accessor :value, :children
  
  def initialize(children = nil, value = {})
    # puts "built node: #{@@count += 1}"
    
    @value    = value
    @children = children
  end
  
  def [](arg)
    @children.at(arg)
  end
    
  def flatten(n)
    if n == 1
      c = children.collect do |x|
        if x.class == Node then
          x.children
        else
          x
        end
      end.compact.flatten(1)
      
      Node.new(c, @value)
    end
  end
  
  def inspect
    "\n-----\n" +
    pretty_print(0) + 
    "\n-----\n"
  end
  
  def pretty_print(indent)
    s = ""
    x = @value[:string] || @value[:rule]
    
    s += "#{"  "*indent}#{x}\n"
    
    return s unless @children
    
    @children.each do |x|
      if x.respond_to?(:pretty_print)
        s += x.pretty_print(indent + 1)
      elsif x
        s += "#{"  "*(indent + 1)}#{x.inspect}\n"
      end
    end
    
    s
  end
  
end

class NoBuilder < Builder
  def node(rule, children = nil, value = {})
    nil
  end
  
end

def drop(rule)
  NoBuilder.new(rule)
end

class TreeBuilder < Builder
  @@null = Node.new
  
  def node(rule, children = nil, value = {})
    Node.new(children, value.merge(:rule => rule))
  end
  
end

class ArrayBuilder < Builder
  def node(rule, children = nil, value = {})
    if children
      children
    else
      value
    end
  end

end

class StringBuilder < Builder  
  def node(rule, children = nil, value = {})
    if str = value[:string]
      str
    elsif children
      children.join
    end
  end

end

class IntegerBuilder < Builder  
  def node(rule, children = nil, value = {})
    if str = value[:string]
      str.to_i
    else
      0
    end
  end

end

end # module Rasta