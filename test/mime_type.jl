using Bonsai, StructTypes, Test
using FilePaths: Path
using StructTypes: @Struct

@Struct struct S1 
	x
	y
end


@testset "mime_type" begin
	@test mime_type(Body{String}) == "text/plain"
	@test mime_type(Body{Dict}) == "application/json"
	P = typeof(Path("file.xml"))
	# we can't set the correct mime type for the file because
	# we don't known the mime_type until we have a instance of the
	# type and we can check the file extenstino, this causes
	# a problem for open api generation with paths...
	@test_skip mime_type(Body{P}) == "text/plain"
	@test mime_type(Body{S1}) == "application/json"
end