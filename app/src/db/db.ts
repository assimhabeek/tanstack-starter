import { drizzle } from 'drizzle-orm/node-postgres'
import pg from 'pg'
import { env } from '@/env'
import { relations } from './schema'

const { Pool } = pg

const pool = new Pool({
  connectionString: env.DATABASE_URL,
  ssl: {
    ca: process.env.DB_CA_CERT?.replace(/\\n/g, '\n')
  }
})

export const db = drizzle({
  relations,
  logger: true,
  client: pool
})

export type Database = typeof db
