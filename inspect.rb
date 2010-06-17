module Rasta

class Rule
  attr_writer :name
  
  def name
    @name || "#{self.class.name}:#{sprintf("%x", self.object_id)}"
  end
  
  def to_s
    self.name
  end
  
  def inspect
    self.name
  end
  
  def deep_inspect
    str = inspect
    bindings = []
    inspect_append_bindings(bindings)
    bindings.uniq!
    
    for binding in bindings
      str += "\n" + binding.inspect
    end
    
    str
  end
  
  def deep_print
    puts inspect
    bindings = []
    inspect_append_bindings(bindings)
    bindings.uniq!
    
    for binding in bindings
      puts binding.inspect
    end
    
    nil
  end
  
  
  def inspect_append_bindings(bindings)
    nil
  end
    
  def inspect_by_name?
    false
  end
  
  def is_container?
    false
  end
  
end

class MultiRule
  def inspect_by_name?
    true
  end
    
  def inspect
    bindings = []
    str = self.deep_inspect(bindings)
    
    for binding in bindings
      str += "\n" + binding.deep_inspect(bindings)
    end
    
    str
  end
    
  def inspect_append_bindings(bindings)
    for rule in @rules
      if rule.inspect_by_name?
        bindings << rule unless rule.is_container?
        rule.inspect_append_bindings(bindings)
      end
    end
  end
  
end

class Sequence
  def name
    @name || "seq:#{sprintf("%x", self.object_id)}"
  end
    
  def inspect
    vars = @rules.collect do |rule|
      str = if rule.inspect_by_name?
        rule.name
      else
        rule.inspect
      end
      
      if @flattens[rule] then
        "<#{str}>"
      else
        str
      end
    end
    
    "#{name} = #{vars.join(' ')}"    
  end
    
end

class Choice    
  def name
    @name || "choice:#{sprintf("%x", self.object_id)}"
  end
  
  def inspect
    vars = @rules.collect do |rule|
      if rule.inspect_by_name?
        rule.name
      else
        rule.inspect
      end
    end
    
    "#{name} = #{vars.join(" | ")}"
  end
  
end

class Builder
  def inspect
    "#[#{self.class.name} #{@rule.inspect}]"
  end
end

class StringBuilder
  def inspect
    @name || "#[string #{@rule.inspect}]"
  end
end

class IntegerBuilder
  def inspect
    @name || "#[integer #{@rule.inspect}]"
  end
end

class RuleRef
  def inspect
    @name || "ref:" + @block.call.name
  end
end

class NoBuilder
  def inspect
    @name || "drop(#{@rule.inspect})"
  end
  
end

class Action
  def name
    @name || "#{self.class.name}(#{@rule.name})"
  end
  
  def inspect    
    @name || "#{self.class.name}(#{@rule.inspect})"
  end  
  
  def inspect_by_name?
    @rule.inspect_by_name?
  end
  
  def is_container?
    true
  end
  
  def inspect_append_bindings(bindings)
    bindings << @rule unless @rule.is_container?
    @rule.inspect_append_bindings(bindings)
  end
end

class FlattenAction
  def name
    @name || "flat(#{@rule.name})"
  end
  
  def inspect
    @name || "flat(#{@rule.inspect})"
  end
end

class More
  def inspect_tail_str
    if @min == 0 && @max == -1 then
      "*"
    elsif @min == 1 && @max == -1 then
      "+"
    else
      "{#{@min}, #{@max}}"
    end
  end
  
  def name
    @name || "#{@rule.name}#{inspect_tail_str}"
  end
  
  def inspect_name
    @name || "more:#{sprintf("%x", self.object_id)}"
  end
  
  def inspect
    if @rule.inspect_by_name? then
      "#{inspect_name} = #{@rule.name}#{inspect_tail_str}"
    else
      "#{@rule.inspect}#{inspect_tail_str}"
    end
  end
  
  def inspect_by_name?
    @rule.inspect_by_name?
  end
  
  def is_container?
    true
  end
  
  def inspect_append_bindings(bindings)
    bindings << @rule unless @rule.is_container?
    @rule.inspect_append_bindings(bindings)
  end
end

end # module Rasta