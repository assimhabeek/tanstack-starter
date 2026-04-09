import * as Sentry from '@sentry/tanstackstart-react'
import dotenv from 'dotenv'

const isProduction = typeof import.meta.env !== 'undefined'

// 1. Try to get the baked value (Vite will replace this string on build)
// 2. Fallback to process.env (Standard Node behavior for dev)
const SENTRY_DSN = isProduction
  ? import.meta.env.VITE_SENTRY_DSN
  : dotenv.config({ path: '.env.local' }) && process.env.VITE_SENTRY_DSN

Sentry.init({
  dsn: SENTRY_DSN,
  // Adds request headers and IP for users, for more info visit:
  // https://docs.sentry.io/platforms/javascript/guides/tanstackstart-react/configuration/options/#sendDefaultPii
  sendDefaultPii: true,
  tracesSampleRate: 1.0,
  replaysSessionSampleRate: 1.0,
  replaysOnErrorSampleRate: 1.0
})
