export default {
	maxIterations: 20, // Maximum loop iterations (default: 10)
	worktreesDir: ".agent-loop/worktrees",
	implementer: {
		model: "openrouter/moonshotai/kimi-k2.7-code", // Model for the Implementer agent
	},
	reviewer: {
		model: "openrouter/z-ai/glm-5.2", // Model for the Reviewer agent
	},
};
