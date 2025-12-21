import { FastMCP } from "fastmcp";

const server = new FastMCP({
  name: "justix-mcp",
  version: "0.0.0",
});

server.start({
  transportType: "stdio",
});
