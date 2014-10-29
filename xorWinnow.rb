if ARGV[2].nil?
  $stderr.puts "
   takes as input a binary matrix with row and column headers
   uses winnow to do an all v all comparison of the rows,
   converts scores into edge weights, and outputs a listing
   of thresholded edge weights

   arg 0 = matrix
   arg 1 = recurrence threshold
   arg 2 = edge-weight threshold (no lower than 4)

  "

raise "not enough arguments given"
end

#---------------------------------------
require 'Matrix'
require 'winnow'
require 'fileTools'


#extend matrix class
#---------------------------------------
class WinMatrix < Matrix
  attr_accessor :classifier, :classifierName

  def createClass(name)
    @classifier = removeRowByName(name)
    @classifierName = name
  end

  #---------------------
  def revertClass
    insertRow(@classifierName,@classifier)    
    @classifier = nil
    @classifierName = nil
  end

  #---------------------
  def flipClass
    @classifier.flipBits!
  end

  #---------------------
  def flipMatrix
    @valMatrix.collect!{|arr|
      arr.flipBits!
    }
  end

  #---------------------
  def removeLowRecurrenceAtts
    sums = self.rowSums
    posToRm =[]
    sums.each_index{|i|
      thresh = (ARGV[1].to_f * self.numCols.to_f).to_i 
      if (sums[i] < thresh)
        posToRm << i
      end
    }
    #remove from end, so indeces don't change.
    posToRm.sort.reverse.each{|i|
      self.removeRow(i)
    }    
#    $stderr.puts "removed #{posToRm.length} low-recurrence attributes" unless posToRm.length == 0
  end

  #---------------------
  def createInstances    
    arr = []
    @valMatrix.first.each_index{|i|
      arr << Instance.new(getColByIndex(i),@classifier[i])
    }
    return arr
  end

  #---------------------
  def copy
    tmp = []
    @valMatrix.each{|arr| tmp << Array.new(arr)}
    zz = WinMatrix.new(tmp, Array.new(@colHeader), Array.new(@rowHeader))
    zz.classifier = self.classifier
    zz.classifierName = self.classifierName
    return zz
  end

end

#-----------------------------------------------
class FalseClass

  def to_i
    return 0
  end

  def to_f
    return 0.0
  end
end

class TrueClass

  def to_i
    return 1
  end

  def to_f
    return 1.0
  end
end

#-----------------------------------------------
class ScoredSample
  attr_accessor :score, :classifier
  def initialize(score, classifier)
    @score = score
    @classifier = classifier
  end
end

#-----------------------------------------------
class Winnow
  def calcSeperability(instances,threshold)
    samples = []
    
    # first, calculate the score for each attribute,
    # where score = Sum(bit*(weight for that att))

    tp,fp,tn,fn = 0,0,0,0
    instances.each_index{|i|
      aclass = instances[i].last
      sum = 0

      0.upto(instances[i].length-2){|j|
        if instances[i][j] == true
          sum += @model.weights[j] 
        end
      }

      if sum >= threshold 
        if instances[i].last == true
          tp +=1
        else
          fp += 1
        end
      else #sum < threshold
        if instances[i].last == true
          fn += 1
        else
          tn += 1
        end
      end
    }

    sens =tp.to_f/(tp.to_f+fn.to_f)
    spec = tn.to_f/(tn.to_f+fp.to_f)

    return (sens + spec)
  end


  def createEdges(name,instances,tfThreshold)
    threshScore = ARGV[2].to_f

    scores = {}
    @model.attributes.each_index{|i|
      scores[@model.weights[i]] = 0
    }     

    if scores.keys.sort.reverse[1] > threshScore
      threshScore = scores.keys.sort.reverse[1]
    end

    @model.attributes.each_index{|i|
      score = @model.weights[i]
      if score >= threshScore
        puts "#{name}\tpp\t#{@model.attributes[i]}\t#{score}"
      end
    }
  end
end

#-----------------------------------------------


def readWinMatrix(file)
  colHeader = getHeader(file)
  colHeader.delete_at(0)

  rowHeader = []
  matrix = []

  tabRead(file,header=true){|arr|
    rowHeader << arr.delete_at(0)
    matrix << arr    
  }

  return WinMatrix.new(matrix,colHeader,rowHeader)
end


#---------------------
def runWinnow(matrix)
  t_class = true
  f_class = false
  instances = matrix.createInstances

  win = Winnow.new
  win.initialize_model(matrix.rowHeader, t_class, f_class, instances)
  win.threshold = matrix.numRows+1
  win.train_model(instances)

  win.createEdges(matrix.classifierName, instances, win.threshold)
end



#============================================
matrix = readWinMatrix(ARGV[0])
matrix.to_f!
matrix.removeLowRecurrenceAtts
matrix.to_binary!

# create a flipped copy so we don't have to keep
# flipping bits back and forth
fMatrix = matrix.copy

#use each attribute as a classifier in turn
rows = Array.new(matrix.rowHeader)
rows.each{|rowName|

  #first, flip the class
  matrix.createClass(rowName)  
  matrix.flipClass
  runWinnow(matrix)
  matrix.flipClass #restore it

  #then, flip the matrix
  fMatrix.createClass(rowName)  
  fMatrix.flipClass #class starts out flipped, revert to original
  runWinnow(fMatrix)
  fMatrix.flipClass #restore it

  #finally, restore the matrix to it's original state      
  matrix.revertClass
  fMatrix.revertClass
}
