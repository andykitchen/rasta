module Rasta
  
class Rule
  def flat
    FlattenAction.new(self)
  end

  def unbox
    UnboxAction.new(self)
  end

  def box(box = nil)
    BoxAction.new(self, box)
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
  def initialize(rule, box = nil, opts = {})
    super(rule)
    @box  = box
    @opts = opts
  end

  def run_action(node, builder)
    builder.node(@box || self, [node], @opts)
  end

end

def box(*args)
  BoxAction.new(*args)
end
  
end # module Rasta