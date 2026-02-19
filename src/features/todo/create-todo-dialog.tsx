/** biome-ignore-all lint/correctness/noChildrenProp: <explanation> */
"use client";

import { useForm } from "@tanstack/react-form";
import { useId } from "react";
import { Button } from "@/components/ui/button";
import {
	Dialog,
	DialogClose,
	DialogContent,
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
import { type TodoCreateInput, TodoSchemas } from "./todo.schema";

interface Props {
	open: boolean;
	onOpenChange: (open: boolean) => void;
	onAction: (create: TodoCreateInput) => void;
}

const formSchema = TodoSchemas.CreateInputSchema;

export const CreateTodoDialog = ({ onOpenChange, open, onAction }: Props) => {
	const formId = useId();

	const form = useForm({
		formId,
		defaultValues: {
			name: "",
		} as TodoCreateInput,
		validators: {
			onChange: formSchema,
			onSubmit: formSchema,
		},
		onSubmit: ({ value }) => onAction(value),
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
						<DialogTitle>Create Todo</DialogTitle>
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
											placeholder="Todo Name"
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
