// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  integrations: [
    starlight({
      title: 'Admapu',
      sidebar: [
        { label: 'Docs', autogenerate: { directory: 'docs' } },
      ],
      head: [
        { tag: 'link', attrs: { rel: 'icon', href: '/favicon.svg', type: 'image/svg+xml' } },
      ],
    }),
  ],
});
