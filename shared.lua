local shared = {}

function shared.mkdir(path)
  os.execute(string.format("mkdir %s", path))
end

function shared.rmdir(path)
  os.execute(string.format("rm -r %s", path))
end

return shared