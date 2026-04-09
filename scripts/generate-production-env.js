const fs = require('node:fs')

// Define which prefixes you want to include in your .env file
const PREFIXES = ['VITE_']

const envVars = Object.keys(process.env)
  .filter((key) => PREFIXES.some((prefix) => key.startsWith(prefix)))
  .map((key) => `${key}=${process.env[key]}`)
  .join('\n')

fs.writeFileSync('../app/.env.production', envVars)
console.log(`✅ Generated .env.production with ${envVars.split('\n').length} variables.`)
