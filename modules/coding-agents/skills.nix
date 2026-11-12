{
  lib,
  codingAgentPackages,
  codingAgentSources,
}:
lib.genAttrs codingAgentPackages.operator.skills (name: "${codingAgentPackages.operator}/share/skills/operator/${name}")
// {
  herdr = "${codingAgentSources.herdr}/skills/herdr";
  hunk-review = "${codingAgentSources.hunk}/packages/hunk/skills/hunk-review";
}
