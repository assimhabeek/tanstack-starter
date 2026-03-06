import { drizzle } from 'drizzle-orm/node-postgres'
import { env } from '@/env'
import { relations } from './schema'

export const db = drizzle({
  relations,
  logger: true,
  connection: { connectionString: env.DATABASE_URL }
})

export type Database = typeof db
