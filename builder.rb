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
  
  def unbox
    UnboxAction.new(self)
  end
  
  def box(box = nil)
    BoxAction.new(self, box)
  end
  
  def flat
    FlattenAction.new(self)
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
  attr_accessor :value, :children
  
  def initialize(children = nil, value = {})
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
    str = value[:string]
    
    if str
      str
    elsif children
      children.join
    end
  end

end

class IntegerBuilder < Builder  
  def node(rule, children = nil, value = {})
    str = value[:string]
    
    if str
      str.to_i
    elsif children
      children.join
    end
  end

end

class Action < Rule
  def initialize(rule)
    @rule = rule
  end
  
  def parse(buffer, builder)
    n = @rule.parse(buffer, builder)
    if n.class == Failure
       n
    else
       self.run_action(n, builder)
    end
  end
  
end

class FlattenAction < Action
  def run_action(node, builder)
    if node.respond_to?(:flatten) then
      node.flatten(1)
    end
  end

end

def flat(rule)
  FlattenAction.new(rule)
end

class UnboxAction < Action
  def run_action(node, builder)
    n[0]
  end
end

def unbox(rule)
  UnboxAction.new(rule)
end

class BoxAction < Action
  def initialize(rule, box = nil)
    super(rule)
    @box = box
  end

  def run_action(node, builder)
    builder.node(@box || self, [node])
  end

end

def box(rule, box = nil)
  BoxAction.new(rule, box)
end

end # module Rasta