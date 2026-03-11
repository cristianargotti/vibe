import { readdir, readFile, writeFile, mkdir } from 'node:fs/promises';
import { join, basename } from 'node:path';

const STANDARDS_SRC = join(import.meta.dirname, '..', 'standards');
const STANDARDS_DEST = join(import.meta.dirname, '..', 'src', 'content', 'docs', 'standards');

async function main() {
  await mkdir(STANDARDS_DEST, { recursive: true });

  const files = (await readdir(STANDARDS_SRC)).filter((f) => f.endsWith('.md'));

  for (const file of files) {
    const content = await readFile(join(STANDARDS_SRC, file), 'utf-8');

    // Extract title from first # heading
    const titleMatch = content.match(/^#\s+(.+)$/m);
    const title = titleMatch ? titleMatch[1].trim() : basename(file, '.md');

    // Remove HTML comments (like <!-- last-reviewed: ... -->)
    const cleaned = content.replace(/<!--[\s\S]*?-->\n*/g, '');

    // Prepend Starlight frontmatter
    const output = `---\ntitle: "${title}"\n---\n\n${cleaned}`;

    await writeFile(join(STANDARDS_DEST, file), output);
  }

  console.log(`Prebuild: copied ${files.length} standards files`);
}

main().catch((err) => {
  console.error('Prebuild failed:', err);
  process.exit(1);
});
