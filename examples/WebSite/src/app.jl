using Bonsai 
using FilePaths: Path

app = App()

app("/img", Folder(joinpath(@__DIR__, "../assets/img") ))
app("/", Path(joinpath(@__DIR__, "../assets/index.html")))




start(app)

wait(app)