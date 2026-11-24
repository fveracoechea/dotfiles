{
  codingAgentSources,
  lib,
  codingAgentPkgs,
  codingAgentMcpPackage,
  codingAgentPackages,
}:
{
  skills =
    lib.genAttrs codingAgentPackages.operator.skills (
      name: "${codingAgentPackages.operator}/share/skills/operator/${name}"
    )
    // {
      herdr = "${codingAgentSources.herdr}/skills/herdr";
      hunk-review = "${codingAgentSources.hunk}/packages/hunk/skills/hunk-review";
    };
  settings = {
    update = "disable";
    model = "openai/gpt-6.1-sol";
    formatter = {
      oxfmt = {
        command = [
          (lib.getExe codingAgentPkgs.oxfmt)
          "--write"
          "$FILE"
        ];
        extensions = [
          ".js"
          ".jsx"
          ".mjs"
          ".cjs"
          ".ts"
          ".tsx"
          ".mts"
          ".cts"
          ".json"
          ".jsonc"
          ".css"
          ".md"
        ];
      };
      nixfmt = {
        command = [
          (lib.getExe codingAgentPkgs.nixfmt)
          "$FILE"
        ];
        extensions = [ ".nix" ];
      };
    };
    mcp.servers.nix-mcp = {
      type = "local";
      command = [ (lib.getExe codingAgentMcpPackage) ];
    };
    compaction = {
      buffer = "35%";
      keep.tokens = 25000;
    };
    agents = {
      plan.disabled = true;
      build.model = "openai/gpt-6.1-sol#medium";
      super.model = "openai/gpt-6.1-sol#medium";
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
        models = {
          "gpt-6.1-sol" = {
            settings.reasoningEffort = "medium";
          };
          "gpt-6.2-sol" = {
            settings.reasoningEffort = "medium";
          };
        };
      };
      openrouter = {
        body.provider = {
          sort = "throughput";
          only = [
            "baseten"
            "novita"
            "fireworks"
          ];
          allow_fallbacks = true;
          data_collection = "deny";
          zdr = true;
        };
      };
    };
    lsp = {
      nixd = {
        command = [ "nixd" ];
        extensions = [ ".nix" ];
      };
      typescript = {
        command = [
          "typescript-language-server"
          "--stdio"
        ];
        extensions = [
          ".js"
          ".jsx"
          ".ts"
          ".tsx"
          ".mjs"
          ".cjs"
          ".mts"
          ".cts"
        ];
      };
    };
  };
}
