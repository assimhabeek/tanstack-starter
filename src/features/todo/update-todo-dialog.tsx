/** biome-ignore-all lint/correctness/noChildrenProp: <explanation> */
"use client";

import { useForm } from "@tanstack/react-form";
import { useId } from "react";
import z from "zod";
import { Button } from "@/components/ui/button";
import {
	Dialog,
	DialogClose,
	DialogContent,
	DialogDescription,
	DialogFooter,
	DialogHeader,
	DialogTitle,
} from "@/components/ui/dialog";
import {
	Field,
	FieldError,
	FieldGroup,
	FieldLabel,
} from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { type Todo, TodoSchemas, type TodoUpdateInput } from "./todo.schema";

interface Props {
	todo: Todo;
	open: boolean;
	onOpenChange: (open: boolean) => void;
	onAction: (update: TodoUpdateInput) => void;
}

// In form name field is required, unlike in api where we don't have to send it if we don't want to updated it
const formSchema = TodoSchemas.UpdateInputSchema.shape.data.extend({
	name: z.string().min(1),
});

export const UpdateTodoDialog = ({
	onOpenChange,
	open,
	todo,
	onAction,
}: Props) => {
	const formId = useId();
	const form = useForm({
		formId,
		defaultValues: todo as TodoUpdateInput["data"],
		validators: {
			onChange: formSchema,
			onSubmit: formSchema,
		},
		onSubmit: ({ value }) => onAction({ id: todo.id, data: value }),
	});

	return (
		<Dialog open={open} onOpenChange={onOpenChange}>
			<form
				id={formId}
				onSubmit={(e) => {
					e.preventDefault();
					form.handleSubmit();
				}}
			>
				<DialogContent className="sm:max-w-[425px]">
					<DialogHeader>
						<DialogTitle>Edit Todo</DialogTitle>
						<DialogDescription>
							Make changes to <span className="font-semibold">{todo.name}</span>
							. Click save when you&apos;re done.
						</DialogDescription>
					</DialogHeader>
					<FieldGroup>
						<form.Field
							name="name"
							children={(field) => {
								const isInvalid =
									field.state.meta.isTouched && !field.state.meta.isValid;
								return (
									<Field data-invalid={isInvalid}>
										<FieldLabel htmlFor={field.name}>
											Name<span className="text-destructive">*</span>
										</FieldLabel>
										<Input
											id={field.name}
											name={field.name}
											value={field.state.value}
											onBlur={field.handleBlur}
											onChange={(e) => field.handleChange(e.target.value)}
											aria-invalid={isInvalid}
											required
											placeholder="Login button not working on mobile"
											autoComplete="off"
										/>
										{isInvalid && (
											<FieldError errors={field.state.meta.errors} />
										)}
									</Field>
								);
							}}
						/>
					</FieldGroup>
					<DialogFooter>
						<DialogClose asChild>
							<Button variant="outline">Cancel</Button>
						</DialogClose>

						<form.Subscribe
							selector={(state) => [
								state.isDefaultValue,
								state.canSubmit,
								state.isSubmitting,
							]}
							children={([isDefaultValue, canSubmit, isSubmitting]) => (
								<Button
									type="submit"
									// The button is disabled if:
									// 1. the form's fields are the same as default values.
									// 2. The form is invalid (canSubmit is false)
									// 3. The form is currently submitting (isSubmitting is true)
									form={formId}
									disabled={isDefaultValue || !canSubmit || isSubmitting}
								>
									{isSubmitting ? "Saving..." : "Save Changes"}
								</Button>
							)}
						></form.Subscribe>
					</DialogFooter>
				</DialogContent>
			</form>
		</Dialog>
	);
};
