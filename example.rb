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

def listx
  list = nil
  
  number = t(/[0-9]+/).mk_i
  word   = t(/[A-Za-z]+/).mk_s
  
  atom   = number | word
  
  l      = t("[").drop
  r      = t("]").drop
  sep    = t(",").drop

  ref    = ref{list}

  list   = l >> ref << (sep >> ref).star.flat >> r | atom
end
