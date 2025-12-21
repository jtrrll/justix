import { FastMCP } from "fastmcp";
import { Justfile } from "./schema/justfile";
import { type } from "arktype";
import { readFileSync } from "fs";

const parseJustfileConfig = type("string.json.parse").to(Justfile)
const out = parseJustfileConfig(readFileSync(`@JUSTFILE_CONFIG@`).toString());
if (out instanceof type.errors) {
  throw new Error(`Invalid justfile config: ${out.summary}`);
}
const justfileConfig = out;

const recipes = [""];

const server = new FastMCP({
  name: "justix-mcp",
  version: "0.0.0",
});

server.addTools(recipes.map(recipe => {
  return {
    name: "temp",
    description: undefined, // TODO: Try to pull from "doc" annotation if exists
    parameters: undefined, // TODO: Try to pull from parameters field, no validation on param types
    execute: async (args) => { // TODO: Try to execute the just command
      return String("");
    }
  }
}))

server.start({
  transportType: "stdio",
});
