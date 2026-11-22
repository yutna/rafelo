import babel from "@rolldown/plugin-babel";
import react, { reactCompilerPreset } from "@vitejs/plugin-react";

export const reactPlugins = () => [react(), babel({ presets: [reactCompilerPreset()] })];
