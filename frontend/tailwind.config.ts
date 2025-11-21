import type { Config } from "tailwindcss";
import forms from "@tailwindcss/forms";

export default {
  content: [
    "./components/**/*.{vue,js,ts}",
    "./layouts/**/*.{vue,js,ts}",
    "./pages/**/*.{vue,js,ts}",
    "./composables/**/*.{vue,js,ts}",
    "./app/**/*.{vue,js,ts}",
    "./plugins/**/*.{js,ts}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Inter", "system-ui", "sans-serif"],
      },
      colors: {
        brand: {
          50: "#f1f5ff",
          100: "#dfe7ff",
          200: "#b9c8ff",
          300: "#8ba6ff",
          400: "#4d75ff",
          500: "#1f4dff",
          600: "#0b33db",
          700: "#0b2ab3",
          800: "#102680",
          900: "#101f54",
        },
      },
    },
  },
  plugins: [forms],
} satisfies Config;

