include Rasta

def list1
  number = t(/[0-9]+/)
  word   = t(/[A-Za-z]+/)
  
  atom   = number | word
  space  = t(" ").star
  
  l      = t("[") >> space
  r      = space  >> t("]")
  sep    = space  >> t(",") >> space
  
  list   = l >> atom >> (sep >> atom).star >> r
end

def list2
  number = t(/[0-9]+/).mk_i
  word   = t(/[A-Za-z]+/).mk_s
  
  atom   = number | word
  space  = t(" ").star.drop
  
  l      = drop(t("[") >> space)
  r      = drop(space  >> t("]"))
  sep    = space       >> t(",").drop >> space
  
  list   = unbox(l >> flat(atom >> (unbox(sep >> atom)).star) >> r)
end

def list3
  number = t(/[0-9]+/).mk_i
  word   = t(/[A-Za-z]+/).mk_s
  
  atom   = number | word
  space  = t(" ").star.drop
  
  l      = drop(t("[") >> space)
  r      = drop(space  >> t("]"))
  sep    = space       >> t(",").drop >> space
  
  list   = unbox(
    l >> flat(ref{list} >> (unbox(sep >> ref{list})).star) >> r
    )    | atom
  
  list.mk_a
end

def list_of(atom, sep)
  flat(atom >> (unbox(sep.drop >> atom)).star)
end

def list4
  number = t(/[0-9]+/).mk_i
  word   = t(/[A-Za-z]+/).mk_s
  
  atom   = number | word
  space  = t(" ").star.drop
  
  l      = drop(t("[") >> space)
  r      = drop(space  >> t("]"))
  sep    = space       >> t(",") >> space
  
  # list   = unbox(l >> ref{list}.mk_list(sep) >> r) | atom
  list   = unbox(l >> list_of(ref{list}, sep) >> r) | atom
  
  list.mk_a
end
