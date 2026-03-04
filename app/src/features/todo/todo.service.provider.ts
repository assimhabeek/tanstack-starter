import { os } from '@orpc/server';
import { db } from '@/db/db';
import { TodoService } from './todo.service';

export const todoServiceProvider = os.middleware(async ({ next }) =>
  next({ context: { todoService: new TodoService(db) } })
);
