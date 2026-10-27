// Lets Node resolve the extensionless imports used by Vite-style source files.
import { register } from 'node:module'

register('./resolve-hook.mjs', import.meta.url)
