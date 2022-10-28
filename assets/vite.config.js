
import elm from 'vite-plugin-elm';

export default {
  publicDir: "./static",
  build: {
    target: "esnext",
    minify: true,
    outDir: "../priv/static",
    emptyOutDir: true,
    rollupOptions: {
      input: ["js/app.js", "css/app.css"],
      output: {
        entryFileNames: "js/[name].js",
        chunkFileNames: "js/[name].js",
        assetFileNames: "[ext]/[name][extname]"
      }
    },
    assetsInlineLimit: 0
  },
  plugins: [elm({ optimize: false })]
}
