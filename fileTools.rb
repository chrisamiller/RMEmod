def tabRead(filename,header=false)
  f = File.open(filename)
  if header==true
    f.gets
  end

  f.each{|line|
    unless line.nil?
      yield line.chomp.split(/\t/)
    end
  }
  f.close()
end


def csvRead(filename,header=false)
  f = File.open(filename)
  if header==true
    f.gets
  end

  f.each{|line|
    unless line.nil?
      yield line.chomp.split(/,/).collect{|x| x.strip}
    end
  }
  f.close()
end


def getHeader(filename)
  f = File.open(filename)
  return f.gets.chomp.split(/\t/)
end


require 'Matrix'
def readMatrix(file)
  colHeader = getHeader(file)
  colHeader.delete_at(0)

  rowHeader = []
  matrix = []


  tabRead(file,header=true){|arr|
    rowHeader << arr.delete_at(0)
    matrix << arr    
  }
  
  return Matrix.new(matrix,colHeader,rowHeader)
end
