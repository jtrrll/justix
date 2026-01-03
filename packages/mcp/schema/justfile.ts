import { type } from "arktype";

export const Recipe = type({
  attributes: type.or(type.string, type.Record(type.string, type.string)).array(),
  dependencies: type.string.array(),
  doc: type.or(type.string, type.null),
  name: type.string,
  parameters: type({
    name: type.string,
    kind: type.string,
    default: type.or(type.string, type.null),
  }).array(),
  private: type.boolean,
});

export const Justfile = type({
  recipes: type.Record(type.string, Recipe).optional()
});
