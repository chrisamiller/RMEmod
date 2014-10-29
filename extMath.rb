class << Math

  #log base 2 definition
  def log2(n); log(n) / log(2); end


  #log2 star definition
  def log2star(n)
    if n < 1
      return 0
    else
      return 1+log2star(log2(n))
    end
  end

  #factorial definition
  def factorial(n)
    sum = 1
    1.upto(n){|i|
      sum *= i
    }
    return sum
  end

  #calculates factorial in log space
  def log2factorial(n)
    sum = 0
    1.upto(n){|i|
      sum += Math.log2(i)
    }
    return sum
  end

  # uses cancelling to do huge factorials
  # the efficient way
  # (a choose b)
  def binomCoefficient(a,b)
    top = 1
    0.upto(b-1){|i|
      top *= (a-i)
    }	
    bottom = Math.factorial(b)
    return top/bottom
  end

  # same, but in log2 space
  # (a choose b)
  def binomCoefficientLog2(a,b)
    top = 0
    0.upto(b-1){|i|
      top += Math.log2(a-i)
    }	
    bottom = Math.log2factorial(b)
    return top - bottom
  end
end
