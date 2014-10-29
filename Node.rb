require 'fileTools'
require 'extArray'

class Node
  # contains the name of the node 
  # the binary array representing samples
  # and links to the connected nodes (ORs)

  attr_accessor :name, :samples, :conns

  def initialize(samples,name)
    @samples = samples 
    @name = name
    @conns = []
    @ands = []
  end

  def eql?(node2)
    unless node2.is_a?(Node)
      raise "both objects need to be the same type (Node) in order to test for equality" 
    end
    
    if self.samples == node2.samples &&
        self.name == node2.name &&
        self.conns == node2.conns
      return true
    end
    return false    
  end

  # return the names of the top N OR-connected nodes
  def topConns(num)
    return conns[0..(num-1)].collect{|genescore| genescore.name}
  end
  
  # return the name of a random OR-connected node
  def randConn
    return conns[rand(conns.length)].name
  end

  # return an array containing the names of all OR-connected 
  # nodes, randomly ordered
  def randConns()        
    return conns.shuffle
  end

  #is the or list non-empty?
  def hasConns?
    if conns.length > 0
      return true
    end
    return false
  end
end


#-----------------------------------
# stores a name/score combo

class GeneScore
  attr_accessor :name, :score
  def initialize(name,score)
    @name = name
    @score = score
  end
end
