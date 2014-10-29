#!/usr/bin/ruby

if ARGV[1].nil?
  $stderr.puts "

  Goes through a list of potential modules and outputs
  non-overlapping modules with the largest size and
  highest significance score that exceed the given
  threshold

  arg 0 = network1.dat (listing of all nets and scores
  arg 1 = original matrix
  arg 2 = threshold score

"
  raise "error - need more arguments"
end


require 'fileTools'
require 'Matrix'

class Gmodule
  attr_accessor :score, :genes

  def initialize(arr)
    @score = arr[0].to_f
    @genes = arr[1].split(/,/)
  end

  # are the genes in this module all also included in
  # this other module?
  def subsetOf(mod)
    found = true
    @genes.each{|gene|
      unless mod.includes(gene)
        found = false
      end
    }
    return found
  end

  # does this module include this gene?
  def includes(gene)
    if @genes.include?(gene)
      return true
    end
    return false
  end

  def to_s
    o = []
    o << @score << @genes.sort.join(",")
    return o.join("\t")
  end

end

#------------------------------------------

def scoreCoverage(mat)
  combined = Array.new(mat.first.length,0)
  mat.each{|node|
    node.each_index{|i|
      if node[i] == 1 || node[i] == "1"
        combined[i] = 1
      end
    }
  }
  return combined.sum.to_f/combined.length.to_f
end

# calculate connectivity by percentage XOR in covered area
def scoreExclusivity(mat)
  covered = 0
  xor = 0
  mat.first.each_index{|i|
    sum = 0
    mat.each{|node|
      sum += node[i].to_i
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

#------------------------------------------
# main

# read in the modules that have scores above threshold
# bin them by size of modules
modules = Hash.new{|h,k| h[k] = []}
tabRead(ARGV[0]){|arr|
  unless arr[0].to_f < ARGV[2].to_f
    mod = Gmodule.new(arr)
    modules[mod.genes.length] << mod
  end
}


# sort the modules within their bins by score
# 
modules.keys.each{|num|
  modules[num] = modules[num].sort{|x,y| y.score <=> x.score}
}

bestMods = []

#start with the largest module size

modules.keys.sort.reverse.each{|modSize|
  # if there are modules in this bin
  until modules[modSize].length == 0
    #choose the best module
    bestMods << modules[modSize].delete_at(0)
  
    # now remove any module that contains one of the genes
    # already kept
    modules.keys.sort.reverse.each{|modSize2|
      toRm = []
      modules[modSize2].each_index{|i|
        bestMods.last.genes.each{|agene|

          #split apart any conjugations
          a = []
          if agene =~/_AND_/
	    a = agene.split(/_/)
	    a.delete_if {|x| x == "AND" }
          else
            a = [agene]
          end	
          
          
	  a.each{|gene|
            if modules[modSize2][i].includes(gene)
  	      toRm << i
  	    end
	    #also remove conjugates 
	    modules[modSize2][i].genes.each{|g|
	      if g =~/(AND_#{gene}|#{gene}_AND)/
                toRm << i
              end
            }
          }
        }
      }
      toRm.sort.uniq.reverse.each{|i|
        modules[modSize2].delete_at(i)
      }
    }
  end #loop and take the next best remaining module
  
} #when out of mods of this size, take next smallest size
 

# look up all the correlation and coverage stats
# from the original matrix

#get a list of all genes involved in modules
allgenes = {}
bestMods.each{|mod|
  unless mod.nil? || mod == ""
    mod.genes.each{|gene|
      allgenes[gene] = 1
    }
  end
}

#create a matrix of just our involved genes
rows = []
rowNames = []
tabRead(ARGV[1],header=true){|arr|
  name = arr.delete_at(0)
  if allgenes.key?(name)
    rows << arr
    rowNames << name
  end
}
colNames = Array.new(rows.first.length,"col")
matrix = Matrix.new(rows,colNames,rowNames)

#now, for each module, score it.
bestMods.each{|mod|
  mat = []
  mod.genes.each{|gene|
    mat << matrix.removeRowByName(gene)
  }
  puts [mod.score,scoreCoverage(mat),scoreExclusivity(mat),mod.genes.join(",")].join("\t")
}
