import path from 'node:path'
import { defineConfig } from 'vite'

export default defineConfig({
  build: {
    lib: {
      entry: path.resolve(__dirname, 'instrument.server.mjs'),
      name: 'instrument',
      fileName: () => 'instrument.server.mjs' // output filename without extension
    },
    outDir: '.output/server', // put it inside Nitro server output
    emptyOutDir: false // don’t delete existing server output
  }
})
