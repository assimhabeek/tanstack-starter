import { fileURLToPath, URL } from 'node:url'
import { sentryTanstackStart } from '@sentry/tanstackstart-react/vite'
import tailwindcss from '@tailwindcss/vite'
import { devtools } from '@tanstack/devtools-vite'
import { tanstackStart } from '@tanstack/react-start/plugin/vite'
import viteReact from '@vitejs/plugin-react'
import { nitro } from 'nitro/vite'
import { defineConfig, loadEnv } from 'vite'
import viteTsConfigPaths from 'vite-tsconfig-paths'

const config = defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const isTest = process.env.VITEST === 'true'

  const devEnvPlugin = isTest
    ? []
    : [
        devtools(),
        nitro(),
        sentryTanstackStart({
          telemetry: false,
          org: env.SENTRY_ORG,
          project: env.SENTRY_PROJECT,
          authToken: env.SENTRY_AUTH_TOKEN
        })
      ]

  return {
    test: {
      passWithNoTests: true
    },
    build: {
      sourcemap: true
    },
    resolve: {
      alias: {
        '@': fileURLToPath(new URL('./src', import.meta.url))
      }
    },
    plugins: [
      tailwindcss(),
      tanstackStart(),
      viteReact(),
      viteTsConfigPaths({
        projects: ['./tsconfig.json']
      }),
      ...devEnvPlugin
    ]
  }
})

export default config
