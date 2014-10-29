#!/usr/bin/env ruby

require 'fileTools'
require 'Node'
require 'NodeArray'
require 'extMath'


#for min score calculation
require 'algSig'
require 'Matrix'

#--------------------------------------------------------------------------------------
# as a heuristic for reducing the search space, calculate the minimum score
# that a module of size N must have in order to be a seed for the search 
# for modules of N+1 
#
# these adjustments were found through intuition and trial-and-error. More rigorous 
# and robust heuristics probably exist, but this works well at the present.

def calcThresholdScore(matrixFile,minSize,maxSize,recur,totalGenes,bgRate)
  threshModScore = {}
  numSamples = getHeader(matrixFile).length-1
  minSize.upto(maxSize){|i|
    if i > 4
      inc = 100
    else
      inc = 0
    end
    
    if recur < 0.10
      threshModScore[i] = (threshScore((recur*i.to_f*2), numSamples, totalGenes, 0.95, bgRate)-(100+(i-4)*inc))
    else 
      threshModScore[i] = (threshScore((recur*i.to_f), numSamples, totalGenes, 0.95, bgRate)-(100+(i-4)*inc))
    end
  }
  return threshModScore
end


#-----------------------------------
# creates a sample matrix with the given characteristics
# for use in calculating thresholds that reduce the search space
def createMatrix(size,covPerc,exclPerc)
  arr = []
  a1 = Array.new(size,0)
  a2 = Array.new(size,0)

  cov = (covPerc*size).to_i
  overlaps = (cov*(1-exclPerc)).to_i

  #split coverage equally among two genes
  if cov % 2 == 0
    index = 0
    (cov/2).times do
      a1[index] = 1
      a2[index+(cov/2)] = 1
      index += 1
    end
  else #odd number
    index = 0
    (cov/2).times do
      a1[index] = 1
      a2[index+(cov/2)] = 1
      index += 1
    end
    a2[index] = 1
  end

  #overlap any genes necessary for excl score
  #add extra mut to alternating genes
  count = 0
  a1Index = cov/2
  a2Index = 0
  gene = 1
  while count < overlaps
    if gene == 1
      a1[a1Index] = 1
      a1Index += 1
      gene = 2
    else
      a2[a2Index] = 1
      a2Index += 1
      gene = 1
    end
    count += 1
  end

  arr << a1 << a2
  cols = Array.new(size,"col")
  rows = Array.new(2,"row")
  return Matrix.new(arr,cols,rows)
end

#------------
# extend class with these functions
class Matrix

  # coverage is the percentage of samples covered
  def scoreCoverage
    count = 0
    colSums.each{|sum|
      if sum > 0
        count += 1
      end
    }
    return count.to_f/@colHeader.length.to_f
  end

  # connectivity is percentage XOR in covered area
  def scoreExclusivity
    covered = 0
    xor = 0
    colSums.each{|sum|
      if sum == 1
      xor += 1
        covered += 1
      elsif sum > 1
        covered += 1
      end
    }
    return xor.to_f/covered.to_f
  end
end


#------------------
def threshScore(cov,size,numGenes,excl,bgRate)
  mat = createMatrix(size,cov,excl)
  sum = 0
  5.times do
    mat.shuffleCols
    sum += calcSignificance(mat,numGenes,bgRate)
  end
  return (sum.to_f/5.0)
end


#-------------------------------------------------------------
# score the specified module, if it hasn't already been seen 
def calcScore(mod)
  #if we've already seen this combination, why score it again?
  id = mod.names.sort.join("--")
  if @allScores.key?(id)
    return @allScores[id]
  else
    #new - score it and return it
    score = mod.score
    @allScores[id] = score
    return score
  end
end


#---------------------------------------------------------------
# reads in matrix, hashes each gene name to a node with the app.
def createNodes
  tabRead(@matrix){|arr|
    name = arr.delete_at(0)
    if @nodeList.key?(name)
      arr = arr.collect{|x| x.to_i}
      @allNodes[name] = Node.new(arr,name)
    end
  }
  
  #add weights to nodes, make bi-directional
  @allEdgeWeightScores.each{|names,score|
    name = names.split(/--/)
    @allNodes[name[0]].conns << name[1]
    @allNodes[name[1]].conns << name[0]
  }  
end

#---------------------------------------------------------------
# read in winnow scores, set each node with the appropriate scores
def getNodeWeights()
  # (two possible sources: flipped and negated, so 
  # add them for each node)
  
  tabRead(@edges){|arr|
    ordered = [arr[0],arr[2]].sort
    @allEdgeWeightScores[ordered.join("--")] += arr[3].to_f
    @nodeList[arr[0]] = 1
    @nodeList[arr[2]] = 1
  }
end 

#--------------------------------------------------

def modSearch(seeds,nodeNames,size,bgRate)
  newSeeds = []
  seeds.each{|seed|
    nodeNames.each{|nodeName|
      # can't have two instances of a node in a single module 
      unless seed.collect{|x| x.name}.include?(nodeName)
        #check this combination
        mod = NodeArray.new(seed)
        mod.setTotalGenes(@totalGenes)
        mod.setBgRate(bgRate)
        mod << @allNodes[nodeName]
      
        #score it
        modScore = calcScore(mod)
        if modScore > @threshModScore[size]
          puts "#{modScore}\t#{mod.names.join(",")}"
          newSeeds << mod unless size >= @maxSize #no point in keeping things I won't use
        end
      end
    }
  }
  if size < @maxSize
    #get uniq node names that are still included 
    modSearch(newSeeds, newSeeds.collect{|a| a.names}.flatten.uniq, size+1, bgRate)
  end
end


################################################################

if ARGV[6].nil?
  $stderr.puts "

  Uses combinatorial search of depth one to find modules that have internal
  exclusivity as well as high predictive power across samples.
 

  inputs:  arg0 = gene/sample matrix (.dat)
           arg1 = edge weights 
           arg2 = minimum size of a module	   
           arg3 = maximum size of a module	   
	   arg4 = total number of genes assayed
	   arg5 = recurrence threshold (like 0.10, 0.05, etc)
	   arg5 = bg mutation rate (like 13.0)
           arg7 = verbose (true or false - optional - default true)
"
  raise "need more arguments"
end

@matrix = ARGV[0]
@edges = ARGV[1]
minSize = ARGV[2].to_i
@maxSize = ARGV[3].to_i
@totalGenes = ARGV[4].to_i
recur = ARGV[5].to_f
bgRate = ARGV[6].to_f
@verbose = true
if ARGV[7] =~ /F|f|false|False|FALSE/
  @verbose = false
end

@threshModScore = calcThresholdScore(@matrix,minSize,@maxSize,recur,@totalGenes,bgRate)

@allNodes = {}
@allEdgeWeightScores = Hash.new{|h,k| h[k] = 0}
@allScores = Hash.new

$stderr.puts "reading in network..." if @verbose

#get the nodes all set up
@nodeList = {}
getNodeWeights()
createNodes()

@allNodes.keys.each{|anchor|
  $stderr.puts "searching from #{anchor}..." if @verbose
  start = NodeArray.new
  start << @allNodes[anchor]
  initSeed = [start]
  modSearch(initSeed,start.first.conns,minSize,bgRate)
}


