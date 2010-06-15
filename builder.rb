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
  
  def inspect
    print "\n-----\n"
    pretty_print(0)
    print "\n-----\n"
  end
  
  def pretty_print(indent)
    x = @value[:string] || @value[:rule]
    
    puts "#{"  "*indent}#{x}"
    
    return unless @children
    
    @children.each do |x|
      if x.respond_to?(:pretty_print)
        x.pretty_print(indent + 1)
      elsif x
        puts "#{"  "*(indent + 1)}#{x.inspect}"
      end
    end
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
      children.compact
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
  def initialize(rule = nil)
    @rule = rule
  end
end

class FlattenAction < Action
  def parse(buffer, builder)
    n = @rule.parse(buffer, builder)
    if n.respond_to?(:flatten) then
      n.flatten(1)
    else
      n
    end
  end

end

def flat(rule)
  FlattenAction.new(rule)
end

class UnboxAction < Action
  # def node(rule, children = nil, value = {})
  #   if children
  #     children.compact[0]
  #   else
  #     value[:string] || value
  #   end
  # end

  def parse(buffer, builder)
    n = @rule.parse(buffer, builder)
    if n.respond_to?(:[]) then
      n[0]
    else
      n
    end
  end
end

def unbox(rule)
  UnboxAction.new(rule)
end

end # module Rasta