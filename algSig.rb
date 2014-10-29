#!/usr/bin/ruby

require 'extArray'
require 'extMath'


#-------------------------------------------
# update the d-score based on the values from
# the null encoder (pn) and the alt encoder (pa)

def calcD(pn,pa)
  return -1*(Math.log2(pn/pa))
end

#-------------------------------------------
# define the null probability bet
# return based on what bit value came up

def probNull(bit)
  if bit == 1
    return @probNullVal
  else #bit == 0
    return @negProbNullVal
  end
end


#-------------------------------------------
# define the A0 probability bet
def probA0(bit)

  # not quite zero, to avoid paying infinitely large
  # penalty when calculating score (div by zero)
  if bit == 0
    return 0.999999
  else #bit == 1
    # This value can be used to tweak coverage vs
    # exclusivity of modules
    return 0.000005
  end
end


#-------------------------------------------
# define the A1 probability bet

def probA1(bit, sampleSum, remainingSamples, geneSum, remainingGenes, mutsRemaining, bitsRemaining)

  ar = sampleSum.to_f/remainingSamples.to_f
  ac = geneSum.to_f/remainingGenes.to_f
  a = mutsRemaining.to_f/bitsRemaining.to_f

  prob = nil
  if a == 1 #avoid division by zero problem in prob calculation
    prob = 1
  else
    prob = (ar*ac)/(a*(((1-ar)*(1-ac)/(1-a))+(ar*ac/a)))
  end

  #avoid division by zero problem in d calculation
  if prob == 1 
    prob = 0.999999
  elsif prob == 0
    prob = 0.000001
  end

  if bit == 1    
    return prob
  end
  return 1-prob
end


#-------------------------------------------
# calculate the significance of the matrix's pattern
# 
def sigCalc(matrix)

  d = 0
  mutsRemaining = matrix.rowSums.sum
  bitsRemaining = matrix.numRows * matrix.numCols
  geneSums = Array.new(matrix.rowSums)

  #look at one sample at a time
  matrix.colHeader.each_index{|sampIndex|
    sample = matrix.getColByIndex(sampIndex)
    foundOne = false
    sampSum = sample.sumNum

    #now, look at each bit in that sample
    sample.each_index{|geneIndex|
      bit = sample[geneIndex]

      # We have already seen a one, and are betting the XOR pattern,
      # or we know there are no more mutations here due to the sums
      if foundOne == true || mutsRemaining == 0
        d += calcD(probNull(bit),probA0(bit))

      else #estimate the mutation probability
        d += calcD(probNull(bit),probA1(bit, geneSums[geneIndex], (matrix.numCols-sampIndex), sampSum, sample.length-geneIndex, mutsRemaining,bitsRemaining))
      end

      if bit == 1
        foundOne = true
        geneSums[geneIndex] -= 1
        sampSum -= 1
	mutsRemaining -= 1
      end
      bitsRemaining -=1
    }
  }
  return d
end


#-----------------------------------------------
# Have to adjust the final score by subtracting the number
# of bits of information that we use for sums, sorting, etc 

def calcAdjustment(matrix,totalGenes)
  #score adjustment for col/row sum
  colAdj = 0
  matrix.colSums.each{|sum|
    colAdj += Math.log2star(sum)
  }
  
  rowAdj = 0
  matrix.rowSums.each{|sum|
    rowAdj += Math.log2star(sum)
  }

  # each row gets sorted by its sum  
  rowSortAdj = matrix.rowSums.calcUniqPermutationsLog2
  colSortAdj = matrix.colSums.calcUniqPermutationsLog2
  sortAdj = rowSortAdj + colSortAdj

  # score adjustment for which set of N genes to use 
  # (think "multiple testing" via binomial coefficient)
  testAdj = Math.binomCoefficientLog2(totalGenes,matrix.numRows)

  return colAdj + rowAdj + testAdj +sortAdj
end

#-------------------------------------------
# takes a matrix of values, total number of genes assayed, 
def calcSignificance(inMatrix,totalGenes,bgRate)

  #total number of mutations in matrix
  oneCount = inMatrix.rowSums.sum
  
  #calculate the adjustment from the raw matrix, for simplicity (prob should be switched later)
  penalty = calcAdjustment(inMatrix,totalGenes)

  #sort the matrix (have already paid the penalty for this)
  inMatrix.sortByRowSums!
  inMatrix.sortByColSums!

  @probNullVal = bgRate
  @negProbNullVal = 1-@probNullVal
  
  #calculate d for the matrix
  d = sigCalc(inMatrix)    

  return d - penalty 
end
