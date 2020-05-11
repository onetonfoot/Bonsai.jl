using Bonsai, FilePaths, FilePathsBase
using FilePaths: URI

app = App()


#TODO file path should be cleaned to prevent 
safe_path(file) = file

app("img/:file") do req
    params = query_params(req)
    file = safe_path(params[:file])
    URI(cwd() / file)


end



URI(cwd() / "..asfdas/asdf")