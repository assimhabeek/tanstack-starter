#!/usr/bin/env node
import { spawnSync } from 'node:child_process'
import { GoogleGenAI } from '@google/genai'
import dotenv from 'dotenv'

dotenv.config()

// 1️⃣ Configuration
const AI_MODEL = process.env.GEMINI_MODEL
const API_KEY = process.env.GEMINI_API_KEY
const ai = new GoogleGenAI({ apiKey: API_KEY })

// 2️⃣ Utility: run shell commands
const runCommand = (command, args, { inherit = false } = {}) => {
  const result = spawnSync(command, args, {
    encoding: 'utf-8',
    stdio: inherit ? 'inherit' : 'pipe', // inherit for live output
    env: process.env,
    shell: false // important! avoid shell parsing
  })

  if (result.error) throw result.error
  if (result.status !== 0) throw new Error(result.stderr)

  return result.stdout?.trim()
}

// 3️⃣ Git operations
const git = {
  diff: () => {
    console.log('🔍 Analyzing git changes...')
    return runCommand('git', ['diff', 'main...HEAD'])
  },

  currentBranch: () => {
    console.log('🔍 Detecting current branch...')
    return runCommand('git', ['rev-parse', '--abbrev-ref', 'HEAD'])
  },

  findPR: (branch) => {
    console.log('🔍 Checking for existing PR...')
    return runCommand('gh', ['pr', 'list', '--head', branch, '--json', 'url', '-q', '.[0].url'])
      .split('/')
      .pop()
  },

  updatePR: (prNumber, title, body) => {
    console.log(`✏️ Updating existing PR: ${prNumber}`)
    runCommand('gh', ['pr', 'edit', prNumber, '--title', title, '--body', body], { inherit: true })
    console.log('✅ Pull Request successfully updated!')
  },

  createPR: (branch, title, body) => {
    console.log(`🚀 Creating new PR from branch '${branch}'`)
    runCommand(
      'gh',
      ['pr', 'create', '--title', title, '--body', body, '--base', 'main', '--head', branch],
      { inherit: true }
    )
    console.log('✅ Pull Request successfully created!')
  }
}

// 4️⃣ LLM operations
const generatePRContent = async (diff) => {
  console.log('🤖 Generating PR title and description with Gemini...')

  const prompt = `
You are a lead developer. Based on the following git diff, generate:

1. A **type** for the PR: one of feat, fix, docs, chore, refactor, test
2. A **scope** if applicable (optional short module/area)
3. A **short description** suitable for a PR title (max 80 chars)
4. A **detailed PR description well written and formatted in Markdown**, including:
   - ## Overview:
   - ## Changes: (the changes made to each file one by one. If multiple changes are made to a file, list them all. focus readability and clean formatting.) 
   - ## Checklist: (Markdown checkboxes)

Return the result in JSON format:
{
  "type": "...",
  "scope": "...",
  "shortDescription": "...",
  "body": "..."
}

Return ONLY JSON, no extra text.

Git Diff:
${diff}
  `

  const response = await ai.models.generateContent({
    model: AI_MODEL,
    contents: prompt
  })

  let data
  try {
    data = JSON.parse(response.text)
  } catch {
    console.log(response.text)
    console.warn('⚠️ Failed to parse LLM response. Using fallback.')
    data = {
      type: 'feat',
      scope: '',
      shortDescription: 'Update from current branch',
      body: response.text
    }
  }

  const { type, scope, shortDescription, body } = data
  const title = scope ? `${type}(${scope}): ${shortDescription}` : `${type}: ${shortDescription}`

  console.log('\n--- PR TITLE ---\n', title)
  console.log('\n--- PR BODY ---\n', body)
  console.log('----------------------------\n')

  return { title, body }
}

// 5️⃣ Upsert PR (create or update)
const upsertPR = (branch, title, body) => {
  const existingPR = git.findPR(branch)
  if (existingPR) git.updatePR(existingPR, title, body)
  else git.createPR(branch, title, body)
}

// 6️⃣ Main workflow
const main = async () => {
  try {
    const diff = git.diff()
    if (!diff) {
      console.log('❌ No changes found against main. Exiting.')
      return
    }

    const branch = git.currentBranch()

    const { title, body } = await generatePRContent(diff)
    upsertPR(branch, title, body)
  } catch (err) {
    console.error('💥 Fatal error:', err instanceof Error ? err.message : err)
    console.log("\nTip: Ensure 'gh' CLI is installed and authenticated via 'gh auth login'")
    process.exit(1)
  }
}

// Run
main()
