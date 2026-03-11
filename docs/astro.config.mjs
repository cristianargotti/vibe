import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://cristianargotti.github.io',
  base: '/vibe',
  vite: {
    ssr: {
      noExternal: ['zod'],
    },
  },
  integrations: [
    starlight({
      title: 'Vibe',
      social: [
        { icon: 'github', label: 'GitHub', href: 'https://github.com/cristianargotti/vibe' },
      ],
      sidebar: [
        { label: 'Getting Started', autogenerate: { directory: 'getting-started' } },
        { label: 'Skills', autogenerate: { directory: 'skills' } },
        { label: 'Hooks', autogenerate: { directory: 'hooks' } },
        { label: 'GitHub Automation', autogenerate: { directory: 'automation' } },
        { label: 'Configuration', autogenerate: { directory: 'configuration' } },
        { label: 'Standards', autogenerate: { directory: 'standards' } },
        { label: 'Guides', autogenerate: { directory: 'guides' } },
        { label: 'Admin', autogenerate: { directory: 'admin' } },
      ],
    }),
  ],
});
