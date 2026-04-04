import fs from 'node:fs'
import { defineConfig } from 'drizzle-kit'

export default defineConfig({
  out: './drizzle',
  schema: './src/db/schema.ts',
  dialect: 'postgresql',
  dbCredentials: {
    ssl: {
      // biome-ignore lint/style/noNonNullAssertion: we need to make sure DB_CA_CERT is defined
      ca: fs.readFileSync(process.env.DB_CA_CERT!).toString(),
      rejectUnauthorized: true
    },
    // biome-ignore lint/style/noNonNullAssertion: add env validation later
    url: process.env.DATABASE_URL!
  }
})
