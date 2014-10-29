# extensions to the Array class
require 'extMath'

class Array

  def shuffle
    sort_by { rand }
  end

  def shuffle!
    self.replace shuffle
  end

  #returns an array containing any duplicated items in the array
  def dups
    inject({}) {|h,v| h[v]=h[v].to_i+1; h}.reject{|k,v| v==1}.keys
  end

  #-------------------
  # mathy functions

  def product(other)
    inject([]) do |ret, es|
      ret += other.map{|eo| [es, eo]}
    end
  end

  # sums any array by converting elements to floats
  # use with caution on non-float arrays
  def sum 
    sum = 0
    self.each{|i|
      sum += i.to_f
    }
    return sum
  end

  # assumes that the array is already composed of an Enumerable type
  # faster than above method
  def sumNum 
    sum = 0
    self.each{|i|
      sum += i
    }
    return sum
  end
 
  def avg
    return self.sum/self.length
  end

  def mean
    return self.sum/self.length
  end
  
  def median
    #quick sanity check - do we have numbers?
    if self[0].is_a?(Float) || self[0].is_a?(Integer) 
      mid = (self.length/2).to_i
      return self.sort![mid]
    else
      raise "median requires an array of integers or floats"
    end
  end
    
  def variance(sd=false)
    n = 0
    mean = 0.0
    s = 0.0
    self.each { |x|
      n = n + 1
      delta = x - mean
      mean = mean + (delta / n)
      s = s + delta * (x - mean)
    }
    # if we are calculating std deviation
    # of a sample have to change this    
    if sd == true
      return s / (n-1)
    else
      return s / n
    end
  end

  # calculate the standard deviation of a population
  # accepts: an array, the population
  # returns: the standard deviation
  def standard_deviation
    Math.sqrt(self.variance)
  end

  def sd
    standard_deviation
  end


  # functions to do combinations  (choose n of k)
  # usage:   choose(array,3)
  # returns: array of arrays containing combos
  def combinations(num)
    return [] if num < 1 || num > size
    return map{|e| [e] } if num == 1
    tmp = self.dup
    self[0, size - (num - 1)].inject([]) do |ret, e|
      tmp.shift
      ret += tmp.combination(num - 1).map{|a| a.unshift(e) }
    end
  end

  #alias for above
  def choose(k)
    return self.combination(k)
  end

  # returns all permutations - use with caution on 
  # huge arrays
  def perm(n = size)
    if size < n or n < 0
    elsif n == 0
      yield([])
    else
      self[1..-1].perm(n - 1) do |x|
	(0...n).each do |i|
	  yield(x[0...i] + [first] + x[i..-1])
	end
      end
      self[1..-1].perm(n) do |x|
	yield(x)
      end
    end
  end


  # in a binary Array, flip all values from true to false, or vice-versa
  # (probably should be abstracted to a binaryArray class)
  def flipBits
    temp = self.collect{|x|
      if x == true
        x = false
      elsif x == false
        x = true
      else
        raise "flipBits can only be used on binary arrays (all values are true/false)"
      end
    }
    return temp
  end

  def flipBits!
    self.collect!{|x|
      if x == true
        x = false
      elsif x == false
        x = true
      else
        raise "flipBits can only be used on binary arrays (all values are true/false)"
      end
    }
  end


  #convert all values to floats
  def to_f
    self.collect!{|x| x.to_f}
  end

  #does what it says on the box
  def calcUniqPermutations
    counts = Hash.new(0)
    self.each{|item| counts[item]+=1}
    product = 1
    counts.each{|k,v|
      if v > 1
        product *= Math.factorial(v)
      end
    }
    return Math.factorial(self.length)/product
  end

  #the same, but in log2 space
  def calcUniqPermutationsLog2
    counts = Hash.new(0)
    self.each{|item| counts[item]+=1}
    sum = 0
    counts.each{|k,v|
      if v > 1
        sum += Math.log2factorial(v)
      end
    }
    return Math.log2factorial(self.length) - sum
  end

end

