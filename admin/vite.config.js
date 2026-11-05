import { fileURLToPath } from 'node:url';
import { defineConfig } from 'vite';

const fromAdmin = (relative) => fileURLToPath(new URL(relative, import.meta.url));

export default defineConfig({
  resolve: { alias: { zod: fromAdmin('./node_modules/zod/index.js') } },
  server: {
    fs: {
      allow: [
        fromAdmin('./'),
        fromAdmin('../functions/src/catalog.ts'),
        fromAdmin('../firebase/remote-config-defaults.json'),
      ],
    },
  },
});
