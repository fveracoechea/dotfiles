{
  lib,
  codingAgentMcpPackage,
}: {
  update = "disable";
  model = "openai/gpt-6.1-sol";
  mcp.servers.nix-mcp = {
    type = "local";
    command = [(lib.getExe codingAgentMcpPackage)];
  };
  compaction = {
    buffer = "25%";
    keep.tokens = 20000;
  };
  agents = {
    plan.disabled = true;
    build.model = "openai/gpt-6.1-sol#high";
    super.model = "openai/gpt-6.1-sol#high";
    worker.model = "openai/gpt-6.1-sol#medium";
  };
  permissions = [
    {
      action = "*";
      resource = "*";
      effect = "allow";
    }
  ];
  experimental.todo = true;
  websearch.provider = "exa";
  providers = {
    openai = {
      settings.compaction.type = "native";
      models."gpt-6.1-sol" = {
        settings.reasoningEffort = "high";
        variants = [
          {
            id = "medium";
            settings.reasoningEffort = "medium";
          }
          {
            id = "high";
            settings.reasoningEffort = "high";
          }
        ];
      };
    };
    openrouter = {
      models."z-ai/glm-5.3-flash" = {
        settings.reasoning.effort = "high";
        variants = [
          {
            id = "high";
            settings.reasoning.effort = "high";
          }
        ];
      };
      body.provider = {
        sort = "throughput";
        only = ["baseten" "novita" "fireworks"];
        allow_fallbacks = true;
        data_collection = "deny";
        zdr = true;
      };
    };
  };
  lsp = {
    nixd = {
      command = ["nixd"];
      extensions = [".nix"];
    };
    typescript = {
      command = ["typescript-language-server" "--stdio"];
      extensions = [".js" ".jsx" ".ts" ".tsx" ".mjs" ".cjs" ".mts" ".cts"];
    };
  };
}
