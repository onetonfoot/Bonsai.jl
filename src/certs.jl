using Mkcert, Scratch

# This will be filled in inside `__init__()`
download_cache = ""

function __init__()
    global download_cache = @get_scratch!("certs")
end


function generate_certs()
end