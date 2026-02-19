"use client";

import type { ColumnDef } from "@tanstack/react-table";
import { ActionCell, type ActionCellProps } from "./action-cell";
import type { Todo } from "./todo.schema";

type Input = Omit<ActionCellProps, "todo">;
type Output = ColumnDef<Todo>[];

export const columns = ({ onDelete, onUpdate }: Input): Output => [
	{
		accessorKey: "id",
		header: "ID",
	},
	{
		accessorKey: "name",
		header: "Name",
	},
	{
		accessorKey: "createdAt",
		header: "Created At",
	},
	{
		id: "actions",
		enableHiding: false,
		cell: ({ row }) => (
			<ActionCell todo={row.original} onDelete={onDelete} onUpdate={onUpdate} />
		),
	},
];
