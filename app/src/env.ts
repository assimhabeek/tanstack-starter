import { createEnv } from '@t3-oss/env-core'
import { z } from 'zod'

console.log('process.env', process.env)
console.log('import.meta.env', import.meta.env)

export const env = createEnv({
  server: {
    DATABASE_URL: z.string().min(1).nonempty('Database URL is required'),
    SENTRY_AUTH_TOKEN: z.string().min(1).nonempty('Sentry Auth Token is required'),
    CLERK_SECRET_KEY: z.string().min(1).nonempty('Clerk Secret Key is required')
  },

  /**
   * The prefix that client-side variables must have. This is enforced both at
   * a type-level and at runtime.
   */
  clientPrefix: 'VITE_',

  client: {
    VITE_APP_TITLE: z.string().min(1).optional(),
    VITE_CLERK_PUBLISHABLE_KEY: z.string().min(1).nonempty('Clerk Publishable Key is required'),
    VITE_SENTRY_DSN: z.string().min(1).optional()
  },

  /**
   * What object holds the environment variables at runtime. This is usually
   * `process.env` or `import.meta.env`.
   *
   * */
  runtimeEnv: {
    DATABASE_URL: process.env.DATABASE_URL,
    SENTRY_AUTH_TOKEN: process.env.SENTRY_AUTH_TOKEN,
    CLERK_SECRET_KEY: process.env.CLERK_SECRET_KEY,
    VITE_APP_TITLE: process.env.VITE_APP_TITLE ?? import.meta.env.VITE_APP_TITLE,
    VITE_CLERK_PUBLISHABLE_KEY:
      process.env.VITE_CLERK_PUBLISHABLE_KEY ?? import.meta.env.VITE_CLERK_PUBLISHABLE_KEY,
    VITE_SENTRY_DSN: process.env.VITE_SENTRY_DSN ?? import.meta.env.VITE_SENTRY_DSN
  },

  /**
   * By default, this library will feed the environment variables directly to
   * the Zod validator.
   *
   * This means that if you have an empty string for a value that is supposed
   * to be a number (e.g. `PORT=` in a ".env" file), Zod will incorrectly flag
   * it as a type mismatch violation. Additionally, if you have an empty string
   * for a value that is supposed to be a string with a default value (e.g.
   * `DOMAIN=` in an ".env" file), the default value will never be applied.
   *
   * In order to solve these issues, we recommend that all new projects
   * explicitly specify this option as true.
   */
  emptyStringAsUndefined: true
})
