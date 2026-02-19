import { RPCHandler } from "@orpc/server/fetch";
import { createFileRoute } from "@tanstack/react-router";
import { router } from "@/orpc/orpc.router";

const handler = new RPCHandler(router);
const handle = async ({ request }: { request: Request }) => {
	const { response } = await handler.handle(request, {
		prefix: "/api/rpc",
		context: {},
	});
	return response ?? new Response(null, { status: 500 });
};

export const Route = createFileRoute("/api/rpc/$")({
	server: {
		handlers: {
			ANY: handle,
		},
	},
});
