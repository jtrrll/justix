import { FastMCP } from "fastmcp";
import { Justfile } from "./schema/justfile";
import { type } from "arktype";
import { $ } from "bun";

const JUST = `@JUST_BINARY@`
const JUSTFILE = `@JUSTFILE@`
const justfile = await $`${JUST} --justfile ${JUSTFILE} --dump --dump-format json`.json().then(Justfile.assert)

const server = new FastMCP({
  name: "justix-mcp",
  version: "0.0.0",
});

Object.entries(justfile.recipes || {}).filter(([_, recipe]) => !recipe.private).forEach(([name, recipe]) => {
  const parameters = (recipe.parameters || []).map(param => {
    return {
      name: param.name,
      isVariadic: param.kind !== "singular",
      hasDefault: param.default !== null
    };
  });
  server.addTool({
    name: name,
    description: recipe.doc ? recipe.doc : undefined,
    parameters: type(
      Object.fromEntries(
        parameters.map(param => {
          const paramType = param.isVariadic ? type.string.array(): type.string;
          return [param.name, param.hasDefault ? paramType.optional() : paramType ];
        })
      )
    ),
    execute: async (args) => {
      const params = parameters.reduce((acc: string[], param) => {
        const value = (args as Record<string, string | string[]>)[param.name]
        if (!value) {
          return acc
        }
        if (Array.isArray(value)) {
          return [...acc, ...value]
        }
        return [...acc, value]
      }, []);

      return await $`${JUST} --justfile ${JUSTFILE} ${name} ${params.join(" ")}`.text()
    },
  })
})

server.start({
  transportType: "stdio",
});
