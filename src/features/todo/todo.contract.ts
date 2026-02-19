import { oc } from "@orpc/contract";
import { HTTP_METHOD } from "@/lib/http.method";
import { TodoSchemas } from "./todo.schema";

const find = oc
	.route({
		method: HTTP_METHOD.GET,
		path: "/todos",
	})
	.input(TodoSchemas.FindInputSchema)
	.output(TodoSchemas.FindOutputSchema);

const findOne = oc
	.route({
		method: HTTP_METHOD.GET,
		path: "/todos/:id",
	})
	.input(TodoSchemas.FindOneInputSchema)
	.output(TodoSchemas.FindOneOutputSchema);

const create = oc
	.route({
		method: HTTP_METHOD.POST,
		path: "/todos",
	})
	.input(TodoSchemas.CreateInputSchema)
	.output(TodoSchemas.CreateOutputSchema);

const update = oc
	.route({
		method: HTTP_METHOD.PUT,
		path: "/todos",
	})
	.input(TodoSchemas.UpdateInputSchema)
	.output(TodoSchemas.UpdateOutputSchema);

const remove = oc
	.route({
		method: HTTP_METHOD.DELETE,
		path: "/todos",
	})
	.input(TodoSchemas.DeleteInputSchema)
	.output(TodoSchemas.DeleteOutputSchema);

export const todoContract = {
	find,
	findOne,
	create,
	update,
	remove,
};

export type TodoContract = typeof todoContract;
