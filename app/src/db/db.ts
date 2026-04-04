import fs from 'node:fs'
import { drizzle } from 'drizzle-orm/node-postgres'
import pg from 'pg'
import { env } from '@/env'
import { relations } from './schema'

const { Pool } = pg

const pool = new Pool({
  connectionString: env.DATABASE_URL,
  ssl: {
    // biome-ignore lint/style/noNonNullAssertion: we need to make sure DB_CA_CERT is defined
    ca: fs.readFileSync(process.env.DB_CA_CERT!).toString()
  }
})

export const db = drizzle({
  relations,
  logger: true,
  client: pool
})

export type Database = typeof db
