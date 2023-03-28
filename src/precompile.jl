try
    for file in readdir("precompile")
        include(file)
    end
catch
end