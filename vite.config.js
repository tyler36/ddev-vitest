
import { defineConfig } from 'vite';

export default {
    // Adjust Vitest's dev server for DDEV: https://vitejs.dev/config/server-options.html
    server: {
        allowedHosts: [`${process.env.DDEV_HOSTNAME}`, 'localhost'],
    },
};
