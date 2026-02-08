/**
 * Parse HINTS.md markdown into structured hint objects
 */

export interface ParsedHint {
  level: number
  title: string
  content: string
}

/**
 * Parse hints markdown into structured hints.
 * Expected format:
 * ```
 * ## Hint Level 1: Title Here
 * Content here...
 * ---
 * ## Hint Level 2: Another Title
 * More content...
 * ```
 */
export function parseHintsMarkdown(markdown: string): ParsedHint[] {
  if (!markdown.trim()) {
    return []
  }

  const hints: ParsedHint[] = []

  // Split by the hint level headers
  const hintPattern = /##\s*Hint\s+Level\s+(\d+):\s*(.+)/gi
  const sections = markdown.split(/---+/).filter((s) => s.trim())

  for (const section of sections) {
    const match = hintPattern.exec(section)
    hintPattern.lastIndex = 0 // Reset regex state

    if (match) {
      const level = parseInt(match[1], 10)
      const title = match[2].trim()

      // Get content after the header
      const headerEnd = section.indexOf(match[0]) + match[0].length
      const content = section.substring(headerEnd).trim()

      hints.push({
        level,
        title,
        content,
      })
    }
  }

  // Sort by level
  hints.sort((a, b) => a.level - b.level)

  return hints
}
