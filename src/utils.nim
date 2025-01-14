import std/times

template withTimer*(body: untyped) =
  let startTime = cpuTime()
  try:
    body
  finally:
    let timeTaken = cpuTime() - startTime
    echo "Time taken: ", timeTaken, " seconds"
