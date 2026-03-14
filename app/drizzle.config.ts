import { defineConfig } from 'drizzle-kit'

export default defineConfig({
  out: './drizzle',
  schema: './src/db/schema.ts',
  dialect: 'postgresql',
  dbCredentials: {
    ssl: {
      ca: process.env.DB_CA_CERT?.replace(/\\n/g, '\n'),
      rejectUnauthorized: true
    },
    // biome-ignore lint/style/noNonNullAssertion: add env validation later
    url: process.env.DATABASE_URL!
  }
})
