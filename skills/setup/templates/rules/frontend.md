# Frontend Rules

Always use functional components. Never use class components.
Always use TanStack Query for server state, Zustand for client state.
Always wrap route segments with error boundaries.
Always use skeleton loaders for loading states. Never use spinners.
Always use next/image for images. Never use raw `<img>` tags.
Always use react-hook-form + zod for form handling and validation.
Always use Server Components by default (App Router). Add "use client" only when needed.
Never prop-drill beyond 2 levels — use context or Zustand instead.
Always colocate styles with components using CSS Modules or Tailwind.
Always use semantic HTML elements (nav, main, section, article).
Always ensure accessibility: aria labels, keyboard navigation, focus management.
