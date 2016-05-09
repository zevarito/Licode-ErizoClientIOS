//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "SDPUtils.h"

#import "RTCSessionDescription.h"

@implementation SDPUtils

+ (RTCSessionDescription *)
descriptionForDescription:(RTCSessionDescription *)description
preferredVideoCodec:(NSString *)codec {
    NSString *sdpString = description.description;
    NSString *lineSeparator = @"\n";
    NSString *mLineSeparator = @" ";
    // Copied from PeerConnectionClient.java.
    // TODO(tkchin): Move this to a shared C++ file.
    NSMutableArray *lines =
    [NSMutableArray arrayWithArray:
     [sdpString componentsSeparatedByString:lineSeparator]];
    long mLineIndex = -1;
    NSString *codecRtpMap = nil;
    // a=rtpmap:<payload type> <encoding name>/<clock rate>
    // [/<encoding parameters>]
    NSString *pattern =
    [NSString stringWithFormat:@"^a=rtpmap:(\\d+) %@(/\\d+)+[\r]?$", codec];
    NSRegularExpression *regex =
    [NSRegularExpression regularExpressionWithPattern:pattern
                                              options:0
                                                error:nil];
    for (NSInteger i = 0; (i < lines.count) && (mLineIndex == -1 || !codecRtpMap);
         ++i) {
        NSString *line = lines[i];
        if ([line hasPrefix:@"m=video"]) {
            mLineIndex = i;
            continue;
        }
        NSTextCheckingResult *codecMatches =
        [regex firstMatchInString:line
                          options:0
                            range:NSMakeRange(0, line.length)];
        if (codecMatches) {
            codecRtpMap =
            [line substringWithRange:[codecMatches rangeAtIndex:1]];
            continue;
        }
    }
    if (mLineIndex == -1) {
        NSLog(@"No m=video line, so can't prefer %@", codec);
        return description;
    }
    if (!codecRtpMap) {
        NSLog(@"No rtpmap for %@", codec);
        return description;
    }
    NSArray *origMLineParts =
    [lines[mLineIndex] componentsSeparatedByString:mLineSeparator];
    if (origMLineParts.count > 3) {
        NSMutableArray *newMLineParts =
        [NSMutableArray arrayWithCapacity:origMLineParts.count];
        NSInteger origPartIndex = 0;
        // Format is: m=<media> <port> <proto> <fmt> ...
        [newMLineParts addObject:origMLineParts[origPartIndex++]];
        [newMLineParts addObject:origMLineParts[origPartIndex++]];
        [newMLineParts addObject:origMLineParts[origPartIndex++]];
        [newMLineParts addObject:codecRtpMap];
        for (; origPartIndex < origMLineParts.count; ++origPartIndex) {
            if (![codecRtpMap isEqualToString:origMLineParts[origPartIndex]]) {
                [newMLineParts addObject:origMLineParts[origPartIndex]];
            }
        }
        NSString *newMLine =
        [newMLineParts componentsJoinedByString:mLineSeparator];
        [lines replaceObjectAtIndex:mLineIndex
                         withObject:newMLine];
    } else {
        NSLog(@"Wrong SDP media description format: %@", lines[mLineIndex]);
    }
    NSString *mangledSdpString = [lines componentsJoinedByString:lineSeparator];
    return [[RTCSessionDescription alloc] initWithType:description.type
                                                   sdp:mangledSdpString];
}

@end

