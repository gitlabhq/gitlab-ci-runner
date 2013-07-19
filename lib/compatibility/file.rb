class File
  def File.binread(fname)
    open(fname, 'rb') {|f|
      return f.read
    }
  end
end
