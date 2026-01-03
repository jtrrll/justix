import { FastMCP } from "fastmcp";
import { Justfile } from "./schema/justfile";
import { type } from "arktype";
import { $ } from "bun";
import { parseArgs } from "util";

const { values } = parseArgs({
  options: {
    just: {
      type: "string",
      description: "Path to the just executable. If not provided, searches for a valid executable in PATH",
    },
  },
  strict: true,
  allowPositionals: false,
});

const JUST = values.just || await (async () => {
  try {
    return await $`which just`.text()
  }
  catch {
    console.error("Error: No just executable not found");
    process.exit(1);
  }
})();

const justfile = await $`${JUST} --dump --dump-format json`.json().then(Justfile.assert)

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

      return await $`${JUST} ${name} ${params.join(" ")}`.text()
    },
  })
})

server.start({
  transportType: "stdio",
});
