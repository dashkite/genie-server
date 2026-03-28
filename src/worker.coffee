import { parentPort, workerData } from "node:worker_threads"
import chokidar from "chokidar"

{ root } = workerData

watcher = chokidar.watch root, ignoreInitial: true

watcher.on "all", ( event, filePath ) ->
  parentPort.postMessage { event, filePath }

watcher.on "error", ( error ) ->
  console.error "❌ Watcher Worker Error: #{error.message}"

console.log "🔍 Watcher Worker: Monitoring #{ root }"