import { implement } from '@orpc/server';
import { type TodoContract, todoContract } from './todo.contract';
import { todoServiceProvider } from './todo.service.provider';

const os = implement<TodoContract>(todoContract).use(todoServiceProvider);

export const todoRouter = {
  find: os.find
    .handler(({ input, context }) => context.todoService.find(input))
    .actionable()
    .callable(),
  findOne: os.findOne
    .handler(({ input, context }) => context.todoService.findOne(input))
    .actionable()
    .callable(),

  create: os.create
    .handler(({ input, context }) => context.todoService.create(input))
    .actionable()
    .callable(),

  update: os.update
    .handler(({ input, context }) => context.todoService.update(input))
    .actionable()
    .callable(),

  remove: os.remove
    .handler(({ input, context }) => context.todoService.remove(input))
    .actionable()
    .callable()
};
