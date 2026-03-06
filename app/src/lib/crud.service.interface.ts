export interface CrudService<
  FindInput,
  FindOutput,
  FindOneInput,
  FindOneOutput,
  CreateInput,
  CreateOutput,
  UpdateInput,
  UpdateOutput,
  DeleteInput,
  DeleteOutput
> {
  find: (input: FindInput) => Promise<FindOutput>
  findOne: (input: FindOneInput) => Promise<FindOneOutput>
  create: (input: CreateInput) => Promise<CreateOutput>
  update: (input: UpdateInput) => Promise<UpdateOutput>
  remove: (input: DeleteInput) => Promise<DeleteOutput>
}
