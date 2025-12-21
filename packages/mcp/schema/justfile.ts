import { type } from "arktype";

export const Recipe = type({
  "aliases?": "string[]",
  "attributes?": "Record<string, boolean | string>",
  "commands?": "string",
  "dependencies?": "string[]",
  "parameters?": "string[]",
});

export const Justfile = type({
  "recipes?": {
    "[string]": Recipe
  },
});
