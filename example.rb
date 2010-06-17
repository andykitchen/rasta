require 'rasta'

include Rasta

def list1
  number = t(/[0-9]+/)
  word   = t(/[A-Za-z]+/)
  
  atom   = number | word
  
  l      = t("[")
  r      = t("]")
  sep    = t(",")
  
  list   = l >> atom >> (sep >> atom).star >> r  
end

def list2
  number = t(/[0-9]+/)
  word   = t(/[A-Za-z]+/)
  
  atom   = number | word
  
  l      = t("[")
  r      = t("]")
  sep    = t(",")
  
  list   = l >> ref{list} >> (sep >> ref{list}).star >> r
end

def listx
  list   = nil
  
  number = t(/[0-9]+/).mk_i
  word   = t(/[A-Za-z]+/).mk_s
  
  atom   = number | word
  
  l      = t("[").drop
  r      = t("]").drop
  sep    = t(",").drop

  lref   = ref{list}

  list   = l >> lref << (sep >> lref).star.flat >> r | atom
  
  atom.name = "atom"
  number.name = "number"
  list.name = "list"
  
  list
end
