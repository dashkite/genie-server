import HTTP from "node:http"
import handler from "serve-static"
import final from "finalhandler"

defaults = 
  port:  8000
  root:  "build"
  index: "index.html"

listen = ( server, port ) ->
  new Promise ( resolve, reject ) ->
    server.once "error", ( error ) ->
      if error.code == "EADDRINUSE"
        listen server, port++
      else 
        reject error
    server.listen port, resolve

export default ( Genie ) ->

  options = { defaults..., ( Genie.get "server" )... }

  Genie.define "server:run", ->

    serve = handler options.root, index: options.index

    server = HTTP.createServer ( request, response ) ->
      serve request, response, final request, response

    try
      await listen server, options.port
    catch error
      console.err error
    
    { port } = server.address()
    console.log "HTTP server listening on 
      [ http://localhost:#{ port } ]
      serving content from 
      [ #{ options.root } ]"

  Genie.define "serve", "server:run"