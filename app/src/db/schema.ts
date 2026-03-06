import * as p from 'drizzle-orm/pg-core'
import { defineRelations } from 'drizzle-orm/relations'

export const todoTable = p.pgTable('todos', {
  id: p.integer().generatedAlwaysAsIdentity().primaryKey(),
  name: p.text().notNull(),
  createdAt: p.timestamp().notNull().defaultNow()
})

export const relations = defineRelations({ todos: todoTable }, () => ({}))
