enum StartupBeat {
  ignite,
  learn,
  practice,
  lab,
  remember,
  converge,
}

class StartupTimeline {
  const StartupTimeline._();

  static const int totalFrames = 144;

  static const Map<StartupBeat, int> startFrames = <StartupBeat, int>{
    StartupBeat.ignite: 0,
    StartupBeat.learn: 18,
    StartupBeat.practice: 44,
    StartupBeat.lab: 70,
    StartupBeat.remember: 96,
    StartupBeat.converge: 132,
  };

  static StartupBeat beatForProgress(double progress) {
    final normalized = progress.clamp(0.0, 1.0).toDouble();
    final frame = normalized * totalFrames;

    if (frame >= startFrames[StartupBeat.converge]!) {
      return StartupBeat.converge;
    }
    if (frame >= startFrames[StartupBeat.remember]!) {
      return StartupBeat.remember;
    }
    if (frame >= startFrames[StartupBeat.lab]!) {
      return StartupBeat.lab;
    }
    if (frame >= startFrames[StartupBeat.practice]!) {
      return StartupBeat.practice;
    }
    if (frame >= startFrames[StartupBeat.learn]!) {
      return StartupBeat.learn;
    }
    return StartupBeat.ignite;
  }

  static double beatProgress(double progress, StartupBeat beat) {
    final normalized = progress.clamp(0.0, 1.0).toDouble();
    final frame = normalized * totalFrames;
    final start = startFrames[beat]!.toDouble();
    final next = _nextStartFrame(beat).toDouble();

    if (frame <= start) {
      return 0;
    }
    if (frame >= next) {
      return 1;
    }
    return (frame - start) / (next - start);
  }

  static int _nextStartFrame(StartupBeat beat) {
    switch (beat) {
      case StartupBeat.ignite:
        return startFrames[StartupBeat.learn]!;
      case StartupBeat.learn:
        return startFrames[StartupBeat.practice]!;
      case StartupBeat.practice:
        return startFrames[StartupBeat.lab]!;
      case StartupBeat.lab:
        return startFrames[StartupBeat.remember]!;
      case StartupBeat.remember:
        return startFrames[StartupBeat.converge]!;
      case StartupBeat.converge:
        return totalFrames;
    }
  }
}
