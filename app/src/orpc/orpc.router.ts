import { todoRouter } from '@/features/todo/todo.router';

export const router = {
  todo: todoRouter
};

export type Router = typeof router;
