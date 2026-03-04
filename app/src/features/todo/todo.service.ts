import { eq } from 'drizzle-orm'
import type { Database } from '@/db/db'
import { todoTable } from '@/db/schema'
import type { CrudService } from '@/lib/crud.service.interface'
import type {
  TodoCreateInput,
  TodoCreateOutput,
  TodoDeleteInput,
  TodoDeleteOutput,
  TodoFindInput,
  TodoFindOneInput,
  TodoFindOneOutput,
  TodoFindOutput,
  TodoUpdateInput,
  TodoUpdateOutput
} from './todo.schema'

export class TodoService
  implements
    CrudService<
      TodoFindInput,
      TodoFindOutput,
      TodoFindOneInput,
      TodoFindOneOutput,
      TodoCreateInput,
      TodoCreateOutput,
      TodoUpdateInput,
      TodoUpdateOutput,
      TodoDeleteInput,
      TodoDeleteOutput
    >
{
  constructor(private db: Database) {}

  find({ limit, offset }: TodoFindInput): Promise<TodoFindOutput> {
    return this.db.query.todos.findMany({ limit, offset })
  }

  findOne({ id }: TodoFindOneInput): Promise<TodoFindOneOutput> {
    return this.db.query.todos.findFirst({ where: { id } })
  }

  create({ name }: TodoCreateInput): Promise<TodoCreateOutput> {
    return this.db
      .insert(todoTable)
      .values({ name })
      .returning()
      .then((rows) => rows[0])
  }

  update(input: TodoUpdateInput): Promise<TodoUpdateOutput> {
    return this.db
      .update(todoTable)
      .set(input.data)
      .where(eq(todoTable.id, input.id))
      .returning()
      .then((rows) => rows[0])
  }

  remove(input: TodoDeleteInput): Promise<TodoDeleteOutput> {
    return this.db
      .delete(todoTable)
      .where(eq(todoTable.id, input.id))
      .returning()
      .then((rows) => rows[0])
  }
}
