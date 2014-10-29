
class Matrix

  require 'extArray'

  # the input 2d array (valMatrix) is always constructed such that 
  # each row is a sub-array
  attr_accessor :colHeader, :rowHeader, :numRows, :numCols

  def initialize(valMatrix, colHeader, rowHeader)
    #validate input    
    if colHeader.length != valMatrix.first.length
      raise "colHeader must be an array of names equal in size to the length of valMatrix"
    end

    if rowHeader.length != valMatrix.length
      raise "rowHeader must be an array of names equal in size to the length of each valMatrix sub-array"
    end
      
    #store info
    @colHeader = colHeader
    @numCols = colHeader.length

    @rowHeader = rowHeader
    @numRows = rowHeader.length

    @valMatrix = valMatrix

    # first time sums are called, we need to actually
    # calculate them, but not until then
    @colSumUpdate = true
    @rowSumUpdate = true
  end


  #---------------------
  def rowSums
    # returns an array of row sums. For efficiency, we only
    # update the row sums if a change has been made
    # to the matrix
    if @rowSumUpdate
      #returns an array of row sums
      @rowSums = @valMatrix.collect{|x| x.sumNum}
      @rowSumUpdate = false
      return @rowSums 
    else
      return @rowSums
    end
  end


  #---------------------
  def colSums    
    # returns an array of col sums. For efficiency, we only
    # update the col sums if a change has been made
    # to the matrix
    if @colSumUpdate
      @colSums = Array.new(@numCols,0)
      @valMatrix.each{|row|
        row.each_index{|i|
          @colSums[i] += row[i]
        }
      }
      @colSumUpdate = false
      return @colSums
    else
      return @colSums
    end
  end


  #---------------------
  def sortByRowSums
    @rowSumUpdate = true
    return @valMatrix.sort{|a,b| b.sumNum <=> a.sumNum}
  end

  def sortByRowSums!
    @rowSumUpdate = true
    @valMatrix.sort!{|a,b| b.sumNum <=> a.sumNum}
  end

  #---------------------
  def sortByColSums
    @colSumUpdate = true
    return @valMatrix.transpose.sort{|a,b| b.sumNum <=> a.sumNum}.transpose
  end

  def sortByColSums!
    @colSumUpdate = true
    @valMatrix = @valMatrix.transpose.sort{|a,b| b.sumNum <=> a.sumNum}.transpose
  end


  #---------------------
  # removes a column from the matrix, and returns the array of values associated with it
  def removeCol(index)
    @rowSumUpdate = true
    @colSumUpdate = true

    @colHeader.delete_at(index)
    @numCols = numCols-1
    arr = []
    @valMatrix.each_index{|i|
      arr << @valMatrix[i].delete_at(index)
    }    
    return arr
  end  

  #---------------------
  def removeColByName(name)
    return removeCol(@colHeader.index(name))
  end

  #---------------------
  def getColByName(name)
    index = @colHeader.index(name)
    arr = []
    @valMatrix.each_index{|i|
      arr << @valMatrix[i][index]
    }    
    return arr
  end

  #alias
  def getColumnByName(name)
    return getColByName(name)
  end
  #---------------------
  def getColByIndex(index)
    arr = []
    @valMatrix.each_index{|i|
      arr << @valMatrix[i][index]
    }    
    return arr
  end

  #alias
  def getColumnByIndex(index)
    return getColByIndex(index)
  end
  #---------------------
  def insertCol(name,arr)
    @rowSumUpdate = true
    @colSumUpdate = true

    if arr.length != @valMatrix.length
      raise "column being inserted into matrix must be the same size as the matrix"
    end
    @valMatrix.each_index{|i|
      @valMatrix[i] << arr[i]
    }
    @colHeader << name
    @numCols += 1
  end


  #---------------------
  #removes a row from the matrix, and returns the array of values associated with it
  def removeRow(index)
    @rowSumUpdate = true
    @colSumUpdate = true

    @rowHeader.delete_at(index)
    @numRows = numRows-1
    return @valMatrix.delete_at(index)
  end  

  #---------------------
  def removeRowByName(name)
    index = rowHeader.index(name)
    if index.nil?
      return nil
    else
      return removeRow(index)
    end
  end

  #---------------------
  def insertRow(name,arr)
    if arr.length != @valMatrix.first.length
      raise "row being inserted into matrix must be the same size as the matrix"
    end
    @valMatrix << arr
    @rowHeader << name
    @numRows += 1
    @rowSumUpdate = true
    @colSumUpdate = true
  end

  #---------------------
  def getRowByName(name)
    index = @rowHeader.index(name)
    return getRowByIndex(index)
  end

  #---------------------
  def getRowByIndex(index)
    return @valMatrix[index]
  end


  #---------------------
  #returns an array of col values from the row at the given index
  def valuesByRow(rowIndex)
    return @valMatrix[rowIndex]
  end

  #---------------------
  #returns an array of row values from the col at the given index
  def valuesByCol(colIndex)
    arr = []
    @valMatrix.each_index{|ii|
      arr << @valMatrix[ii][colIndex]
    }
    return arr
  end


  #---------------------
  def print
    puts @valMatrix.transpose.collect{|x| x.join("\t")}.join("\n")
  end

  #---------------------
  def print_arff
    @rowHeader.each{|name|
      puts "@attribute #{name} {1,0}"
    }
    puts ""
    puts "@data"
    0.upto(@numCols-1){|i|
      puts valuesByCol(i)
    }    
  end

  #---------------------
  def valByRowNameColName(rowName,colName)
    rindex = @rowHeader.index(rowName)
    cindex = @colHeader.index(colName)
    if cindex.nil? || rindex.nil?
      return nil
    else
      return @valMatrix[rindex][cindex]
    end
  end

  def setValByRowNameColName(rowName,colName,val)
    rindex = @rowHeader.index(rowName)
    cindex = @colHeader.index(colName)
    if cindex.nil? || rindex.nil?
      return nil
    else
      @valMatrix[rindex][cindex] = val
    end
    @rowSumUpdate = true
    @colSumUpdate = true
  end

  #---------------------
  def to_binary
    a = Array.new
    @valMatrix.each{|row|
      temp = []
      row.each{|val|
        case val
        when "true", 1, "1", true
          temp << true
        when "false", 0, "0", false
          temp << false
        else
          raise "error: to convert to binary, a matrix must contain only the values:\n0,1,'true','false', or true/false binary values"
        end  
      }
      a << temp
    }
    return a
  end

  def to_binary!
    @valMatrix = self.to_binary
  end

  #---------------------
  def to_f
    a = Array.new
    @valMatrix.each{|row|
      temp = []
      row.each{|val|
        temp << val.to_f
      }
      a << temp
    }
    return a
  end

  def to_f!
    @valMatrix = self.to_f
  end

  #---------------------
  def to_i
    a = Array.new
    @valMatrix.each{|row|
      temp = []
      row.each{|val|
        temp << val.to_i
      }
      a << temp
    }
    return a
  end

  def to_i!
    @valMatrix = self.to_i
  end

  #---------------------
  def copy
    tmp = []
    @valMatrix.each{|arr| tmp << Array.new(arr)}
    return Matrix.new(tmp, Array.new(@colHeader), Array.new(@rowHeader))
  end

  #---------------------
  def transpose!
    @valMatrix = @valMatrix.transpose
    tmp = @colHeader
    @colHeader = @rowHeader
    @rowHeader = tmp
    tmp = @numCols
    @numCols = @numRows
    @numRows = tmp

    @rowSumUpdate = true
    @colSumUpdate = true
  end

  #---------------------
  def shuffleCols
    self.transpose!

    #attach the names to the rows
    @rowHeader.each_index{|i|
      @valMatrix[i] << @rowHeader[i]
    }

    #mix them up
    @valMatrix.shuffle!

    #now remove names back to header
    @rowHeader = []
    @valMatrix.each{|row|
      @rowHeader << row.pop
    }
    self.transpose!
    @colSumUpdate = true
  end

  #---------------------
  def print
    temp = Array.new(@colHeader)
    temp.unshift("")
    puts temp.join("\t")
    
    @rowHeader.each_index{|i|
      temp = Array.new(@valMatrix[i])
      temp.unshift(rowHeader[i])
      puts temp.join("\t")
    }
  end
  #-------------------------
  def stderrPrint
    temp = Array.new(@colHeader)
    temp.unshift("")
    $stderr.puts temp.join("\t")
    
    @rowHeader.each_index{|i|
      temp = Array.new(@valMatrix[i])
      temp.unshift(rowHeader[i])
      $stderr.puts temp.join("\t")
    }
  end

end
