# Class that extends Array to add functions useful 
# when our array is full of nodes

require 'extArray'
require 'algSig'
require 'Matrix'

class NodeArray < Array
  def setTotalGenes(num)
    @numGenes = num
  end   

  def setBgRate(num)
    @bgRate = num
  end   

  def names    
    return self.collect{|x| x.name}
  end

  # coverage is percentage of samples covered
  def scoreCoverage
    combined = Array.new(self[0].samples.length,0)    
    self.each{|node|
      node.samples.each_index{|i|
        if node.samples[i] == 1 || node.samples[i] == "1"
          combined[i] = 1
        end
      }
    }
    return combined.sum.to_f/combined.length.to_f
  end


  # exclusivity is percentage XOR in covered area
  def scoreExclusivity
    covered = 0
    xor = 0
    self[0].samples.each_index{|i|
      sum = 0
      self.each{|node|
        sum += node.samples[i].to_i
      }
      if sum == 1
        xor += 1
        covered += 1
      elsif sum > 1
        covered += 1
      end
    }    
    return xor.to_f/covered.to_f
  end


  #calculate algorithmic significance for each module
  def eScore
    #convert binary arrays for each gene to a matrix
    twodArray = []
    self.each{|node|
      twodArray << Array.new(node.samples)
    }    
    rowHead = Array.new(twodArray.length,"row")
    colHead = Array.new(twodArray[0].length,"col")

    matrix = Matrix.new(twodArray, colHead, rowHead)
    return calcSignificance(matrix,@numGenes,@bgRate)
  end

  def score
     return self.eScore
  end

end


