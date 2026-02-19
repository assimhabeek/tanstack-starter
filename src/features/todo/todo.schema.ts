import { createSchemaFactory } from "drizzle-orm/zod";
import z from "zod";
import { todoTable } from "@/db/schema";

const { createInsertSchema, createSelectSchema, createUpdateSchema } =
	createSchemaFactory({ coerce: {} });

const TodoSchema = createSelectSchema(todoTable);

const FindInputSchema = z.object({
	limit: z.coerce.number().int().min(1).max(100).optional().default(10),
	offset: z.coerce.number().int().min(0).default(0),
});

const FindOneInputSchema = TodoSchema.pick({ id: true });

const CreateInputSchema = createInsertSchema(todoTable).omit({
	createdAt: true,
});

const UpdateInputSchema = z.object({
	id: z.number().min(0).max(100),
	data: createUpdateSchema(todoTable),
});

const DeleteInputSchema = z.object({ id: z.number().min(0).max(100) });

const FindOutputSchema = z.array(TodoSchema);
const FindOneOutputSchema = z.optional(TodoSchema);
const CreateOutputSchema = z.optional(TodoSchema);
const UpdateOutputSchema = z.optional(TodoSchema);
const DeleteOutputSchema = z.optional(TodoSchema);

export const TodoSchemas = {
	TodoSchema,
	FindOneInputSchema,
	FindInputSchema,
	CreateInputSchema,
	UpdateInputSchema,
	DeleteInputSchema,
	FindOutputSchema,
	FindOneOutputSchema,
	CreateOutputSchema,
	UpdateOutputSchema,
	DeleteOutputSchema,
};

export type Todo = z.infer<typeof TodoSchema>;

export type TodoFindInput = z.infer<typeof FindInputSchema>;
export type TodoFindOutput = z.infer<typeof FindOutputSchema>;

export type TodoFindOneInput = z.infer<typeof FindOneInputSchema>;
export type TodoFindOneOutput = z.infer<typeof FindOneOutputSchema>;

export type TodoCreateInput = z.infer<typeof CreateInputSchema>;
export type TodoCreateOutput = z.infer<typeof CreateOutputSchema>;

export type TodoUpdateInput = z.infer<typeof UpdateInputSchema>;
export type TodoUpdateOutput = z.infer<typeof UpdateOutputSchema>;

export type TodoDeleteInput = z.infer<typeof DeleteInputSchema>;
export type TodoDeleteOutput = z.infer<typeof DeleteOutputSchema>;
