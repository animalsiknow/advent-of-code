use "collections"
use "files"
use "itertools"

actor Main
  new create(env: Env) =>
    let path =
      try
        FilePath(env.root as AmbientAuth, "./chronal-calibration.txt")?
      else
        env.out.print("could not open file")
        return
      end

    let frequencyChanges = List[I32]()
    match OpenFile(path)
      | let file: File =>
      for line in file.lines() do
        try frequencyChanges.push(_parseInt(consume line)?) end
      end
    end

    env.out.print("final frequency: " + _finalFrequency(frequencyChanges).string())
    env.out.print("first repeating frequency: " + _firstRepeatingFrequency(frequencyChanges).string())

  fun _finalFrequency(frequencyChanges: List[I32]): I32 =>
    frequencyChanges.fold[I32]({ (l: I32, r: I32): I32 => l + r }, 0)

  fun _firstRepeatingFrequency(frequencyChanges: List[I32]): I32 =>
    let seenFrequencies = Set[I32]()
    var f: I32 = 0
    for change in Iter[I32](frequencyChanges.values()).cycle() do
      f = f + change
      if seenFrequencies.contains(f) then
        return f
      end
      seenFrequencies.set(f)
    end
    f

  fun _parseInt(source: String iso): I32? =>
    if source.substring(0, 1) == "+" then
      source.shift()?
    end
    source.i32(10)?
