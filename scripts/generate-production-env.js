import fs from 'node:fs'
import path from 'node:path'

const PREFIXES = ['VITE_']

const envVars = Object.keys(process.env)
  .filter((key) => PREFIXES.some((prefix) => key.startsWith(prefix)))
  .map((key) => `${key}=${process.env[key]}`)
  .join('\n')

// Target file path
const filePath = path.resolve(process.cwd(), 'app/.env.production')

// Write file
fs.writeFileSync(filePath, envVars)

console.log(
  `✅ Generated .env.production with ${envVars ? envVars.split('\n').length : 0} variables.`
)
