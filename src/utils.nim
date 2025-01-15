import std/times
import jsony
import ./types

template withTimer*(body: untyped) =
  let startTime = cpuTime()
  try:
    body
  finally:
    let timeTaken = cpuTime() - startTime
    echo "Time taken: ", timeTaken, " seconds"


proc readRecipeFile*(filePath: string): Recipe =
  let content: string = readFile(filePath)
  let recipe = content.fromJson(Recipe)
  return recipe
