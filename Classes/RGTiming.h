// Copyright 2014-present Ryan Gomba. All rights reserved.

#ifndef RGFoundation_RGTiming_h
#define RGFoundation_RGTiming_h

#define StartTimer() CFTimeInterval __startTimer = CACurrentMediaTime();
#define RestartTimer() __startTimer = CACurrentMediaTime();
#define PrintTimeElapsedMessage(message) NSLog(@"Time elapsed: %.2f ms (%@)", (CACurrentMediaTime() - __startTimer) * 1000.0, message);
#define PrintTimeElapsed() PrintTimeElapsedMessage(@"");

#endif
