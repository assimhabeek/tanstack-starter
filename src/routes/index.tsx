import {
	type DefaultError,
	useMutation,
	useSuspenseQuery,
} from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { PlusIcon } from "lucide-react";
import { useCallback, useState } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { columns } from "@/features/todo/columns";
import { CreateTodoDialog } from "@/features/todo/create-todo-dialog";
import { DataTable } from "@/features/todo/data-table";
import { DeleteTodoDialog } from "@/features/todo/delete-todo-dialog";
import type {
	Todo,
	TodoCreateInput,
	TodoCreateOutput,
	TodoDeleteInput,
	TodoDeleteOutput,
	TodoUpdateInput,
	TodoUpdateOutput,
} from "@/features/todo/todo.schema";
import { UpdateTodoDialog } from "@/features/todo/update-todo-dialog";
import { orpc } from "@/orpc/orpc.client";

const todoQueryOptions = orpc.todo.find.queryOptions({
	input: {},
	initialData: [],
});

export const Route = createFileRoute("/")({
	component: App,
	loader: ({ context: { queryClient } }) =>
		queryClient.ensureQueryData(todoQueryOptions),
});

function App() {
	const { data: todos, refetch } = useSuspenseQuery(todoQueryOptions);

	const { mutate: create } = useMutation<
		TodoCreateOutput,
		DefaultError,
		TodoCreateInput
	>({
		mutationFn: (input) => orpc.todo.create.call(input),
		onSuccess: (data) => {
			refetch();
			setOpenCreateDialog(false);
			toast.success(`Todo ${data?.name} has been created.`);
		},
	});

	const { mutate: update } = useMutation<
		TodoUpdateOutput,
		DefaultError,
		TodoUpdateInput
	>({
		mutationFn: (input) => orpc.todo.update.call(input),
		onSuccess: (data) => {
			refetch();
			setOpenUpdateDialog(false);
			toast.success(`Todo ${data?.name} has been updated.`);
		},
	});

	const { mutate: remove } = useMutation<
		TodoDeleteOutput,
		DefaultError,
		TodoDeleteInput
	>({
		mutationFn: ({ id }) => orpc.todo.remove.call({ id }),
		onSuccess: (data) => {
			refetch();
			setOpenDeleteDialog(false);
			toast.success(`Todo ${data?.name} has been deleted.`);
		},
	});

	const [selectedTodo, setSelectedTodo] = useState<Todo>();
	const [openDeleteDialog, setOpenDeleteDialog] = useState(false);
	const [openUpdateDialog, setOpenUpdateDialog] = useState(false);
	const [openCreateDialog, setOpenCreateDialog] = useState(false);

	const onUpdate = useCallback((selected: Todo) => {
		setSelectedTodo(selected);
		setOpenUpdateDialog(true);
	}, []);

	const onDelete = useCallback((selected: Todo) => {
		setSelectedTodo(selected);
		setOpenDeleteDialog(true);
	}, []);

	return (
		<div className="overflow-hidden rounded-md border">
			<div className="container mx-auto py-10">
				<div className="flex justify-end m-2">
					<Button type="button" onClick={() => setOpenCreateDialog(true)}>
						<PlusIcon /> Create Todo
					</Button>
				</div>

				<DataTable<Todo, unknown>
					columns={columns({
						onDelete,
						onUpdate,
					})}
					data={todos}
				/>
				<CreateTodoDialog
					open={openCreateDialog}
					onOpenChange={setOpenCreateDialog}
					onAction={create}
				/>
				{selectedTodo && (
					<>
						<DeleteTodoDialog
							todo={selectedTodo}
							open={openDeleteDialog}
							onOpenChange={setOpenDeleteDialog}
							onAction={remove}
						/>
						<UpdateTodoDialog
							todo={selectedTodo}
							open={openUpdateDialog}
							onOpenChange={setOpenUpdateDialog}
							onAction={update}
						/>
					</>
				)}
			</div>
		</div>
	);
}
