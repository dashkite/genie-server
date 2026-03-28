import { createRequire } from "node:module"
import FS from "node:fs"
import Path from "node:path"
import { Worker } from "node:worker_threads"
import { vol } from "memfs"
import { ufs } from "unionfs"
import { patchFs as patchFS } from "fs-monkey"

class Mirror

  @make: ( root ) ->
    K = @
    do ( require = createRequire import.meta.url ) ->
      Object.assign ( new K ),
        root: Path.resolve root
        fs: require "node:fs"

  mirror: ( root = @root ) ->
    entries = @fs.readdirSync root, withFileTypes: true
    for entry in entries
      path = Path.join root, entry.name      
      if entry.isDirectory()
        vol.mkdirSync path, recursive: true
        @mirror path
      else
        vol.writeFileSync path, 
          @fs.readFileSync path

  start: ( handler ) ->

    console.log "💾 Mirroring #{@root} to memory..."
    @mirror()

    @worker = new Worker ( Path.join __dirname, "./worker.js" ), 
      workerData: { @root }

    @worker.on "message", ({ event, filePath }) =>
      @process event, filePath
      handler()

    # fallback to the real filesystem
    ufs
      .use vol
      .use { @fs... }

    @unpatch = patchFS ufs
    
    console.log "🚀 FS Monkey Patched. Watcher active in background thread."

  process: ( event,  path ) ->
    try
      switch event
        when "add", "change"
          content = @fs.readFileSync path
          vol.writeFileSync path, content
        when "unlink"
          vol.unlinkSync path
      
      console.log "⚡ [memfs] #{ event }: #{ path }"
    catch err
      console.error "❌ Mirror sync error:", err

  stop: ->
    @worker?.terminate()
    @unpatch?()

export default Mirror