'use client';

import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle
} from '@/components/ui/alert-dialog';
import type { Todo, TodoDeleteInput } from './todo.schema';

interface Props {
  todo: Todo;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onAction: (input: TodoDeleteInput) => void;
}
export const DeleteTodoDialog = ({ todo, open, onOpenChange, onAction }: Props) => {
  return (
    <AlertDialog open={open} onOpenChange={onOpenChange}>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Delete Todo Confirmation</AlertDialogTitle>
          <AlertDialogDescription>
            {' '}
            Are you sure you want to delete <span className="font-semibold">{todo.name}</span>?
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel>Cancel</AlertDialogCancel>
          <AlertDialogAction onClick={() => onAction({ id: todo.id })}>Delete</AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
};
