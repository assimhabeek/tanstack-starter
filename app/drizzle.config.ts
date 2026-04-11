import fs from 'node:fs'
import { defineConfig } from 'drizzle-kit'

export default defineConfig({
  out: './drizzle',
  schema: './src/db/schema.ts',
  dialect: 'postgresql',
  dbCredentials: {
    // setup ssl only if DB_CA_CERT is provided
    ssl: process.env.DB_CA_CERT
      ? {
          ca: fs.readFileSync(process.env.DB_CA_CERT).toString(),
          rejectUnauthorized: true
        }
      : undefined,
    // biome-ignore lint/style/noNonNullAssertion: add env validation later
    url: process.env.DATABASE_URL!
  }
})
