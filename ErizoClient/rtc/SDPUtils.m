//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

@import WebRTC;
#import "SDPUtils.h"
#import "Logger.h"

@implementation SDPUtils

+ (RTCSessionDescription *)descriptionForDescription:(RTCSessionDescription *)description
                                       codecMimeType:(const NSString *)codec
                                          fmtpString:(NSString *)fmtpString
                                    preserveExistent:(BOOL)preserveExistent {

    NSAssert(![[fmtpString substringWithRange:NSMakeRange(0, 1)] isEqualToString:@";"],
             @"Can't contain ; at the begining of fmtpString");
    NSAssert(![[fmtpString substringWithRange:NSMakeRange([fmtpString length]-1, 1)] isEqualToString:@";"],
             @"Can't contain ; at the end of fmtpString");

    __block NSString *newSDP = @"";
    __block BOOL rtpmapFound = NO;
    __block NSString *codecMap = nil;
    NSString *rtpmapPattern = [NSString stringWithFormat:@"a=rtpmap:([0-9]+) %@.*", codec];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:rtpmapPattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];

    [description.sdp enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
        NSTextCheckingResult *matches = [regex firstMatchInString:line
                                                          options:0
                                                            range:NSMakeRange(0, [line length])];

        if (matches) {
            rtpmapFound = YES;
            codecMap = [line substringWithRange:[matches rangeAtIndex:1]];
            newSDP = [[newSDP stringByAppendingString:line] stringByAppendingString:@"\r\n"];
        } else if (rtpmapFound) {
            //NSString *lineStart;
            NSString *replaceLine = [NSString stringWithFormat:@"a=fmtp:%@ %@\r\n", codecMap, fmtpString];

            if ([[line substringWithRange:NSMakeRange(0, 7)] isEqualToString:@"a=fmtp:"]) {
                if (preserveExistent) {
                    NSString *modifiedLine =  [NSString stringWithFormat:@"%@;%@\r\n", line, fmtpString];
                    newSDP = [newSDP stringByAppendingString:modifiedLine];
                    L_DEBUG(@"SDP Modified a=fmtp for codec %@, line: %@ with line: %@",
                            codecMap, line, modifiedLine);
                } else {
                    newSDP = [newSDP stringByAppendingString:replaceLine];
                    L_DEBUG(@"SDP Replaced previous a=fmtp for codec %@, line: %@ with line: %@",
                            codecMap, line, replaceLine);
                }
                rtpmapFound = NO;
            } else if (![[line substringWithRange:NSMakeRange(0, 10)] isEqualToString:@"a=rtcp-fb:"]) {
                newSDP = [newSDP stringByAppendingString:replaceLine];
                rtpmapFound = NO;
                L_DEBUG(@"SDP Added a=fmtp for codec %@, line: %@", codecMap, replaceLine);
            } else {
                newSDP = [[newSDP stringByAppendingString:line] stringByAppendingString:@"\r\n"];
            }
        } else {
            newSDP = [[newSDP stringByAppendingString:line] stringByAppendingString:@"\r\n"];
        }
    }];

    return [[RTCSessionDescription alloc] initWithType:description.type sdp:newSDP];

}

+ (RTCSessionDescription *)descriptionForDescription:(RTCSessionDescription *)description
                                  matchingPatternStr:(NSString *)matchingPatternStr
                                     replaceWithLine:(NSString *)replacementLine {

    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:matchingPatternStr
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    NSString *newSDP = [regex stringByReplacingMatchesInString:description.sdp
                                                       options:0
                                                         range:NSMakeRange(0, [description.sdp length])
                                                  withTemplate:replacementLine];

    if (![newSDP isEqualToString:description.sdp]) {
        L_DEBUG(@"SDP Line replaced! %@ pattern with %@", matchingPatternStr, replacementLine);
    }

    return [[RTCSessionDescription alloc] initWithType:description.type sdp:newSDP];
}

+ (RTCSessionDescription *)descriptionForDescription:(RTCSessionDescription *)description
                                       bandwidthLimit:(NSInteger)bandwidthLimit
                                         forMediaType:(NSString *)mediaType {

    NSString *mediaPattern = [NSString stringWithFormat:@"m=%@.*", mediaType];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:mediaPattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    __block NSString *newSDP = @"";
    __block BOOL mediaFound = NO;

    [description.sdp enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
        NSTextCheckingResult *matches = [regex firstMatchInString:line
                                                          options:0
                                                            range:NSMakeRange(0, [line length])];

        if (matches) {
            mediaFound = YES;
        } else if (mediaFound) {
            NSString *lineStart = [line substringWithRange:NSMakeRange(0, 2)];
            if (![lineStart isEqualToString:@"i="] && ![lineStart isEqualToString:@"c="]
                    && ![lineStart isEqualToString:@"b="]) {
                NSString *newLine = [NSString stringWithFormat:@"b=AS:%ld\r\n", (long)bandwidthLimit];
                newSDP = [newSDP stringByAppendingString:newLine];
                mediaFound = NO;
                L_DEBUG(@"SDP BW Updated: %@", newLine);
            }
        }

        newSDP = [newSDP stringByAppendingString:[line stringByAppendingString:@"\r\n"]];
    }];

    return [[RTCSessionDescription alloc] initWithType:description.type sdp:newSDP];
}

+ (RTCSessionDescription *)descriptionForDescription:(RTCSessionDescription *)description
                                        appendingLine:(NSString *)line
                                     afterRegexString:(NSString *)regexStr {

    NSError *regexError;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexStr
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                            error:&regexError];
    if (regexError) {
        L_ERROR(@"Fail at creating regex: %@ to append SDP line: %@", regexStr, line);
        return description;
    }

    NSTextCheckingResult *matches = [regex firstMatchInString:description.sdp
                                                      options:0
                                                        range:NSMakeRange(0, [description.sdp length])];
    if (!matches) {
        L_ERROR(@"Fail matching regex: %@ to append SDP line: %@", regexStr, line);
        return description;
    }

    NSString *replacementStr = [NSString stringWithFormat:@"%@\r\n%@",
                                [description.sdp substringWithRange:matches.range], line];
    NSString *newSDPStr = [regex stringByReplacingMatchesInString:description.sdp
                                                          options:0
                                                            range:NSMakeRange(0, [description.sdp length])
                                                     withTemplate:replacementStr];

    L_DEBUG(@"SDP regex: %@, replaced with: %@", regexStr, replacementStr);

    RTCSessionDescription *newSDP = [[RTCSessionDescription alloc] initWithType:description.type
                                                                            sdp:newSDPStr];
    return newSDP;
}

+ (RTCSessionDescription *) descriptionForDescription:(RTCSessionDescription *)description
                                 preferredVideoCodec:(NSString *)codec {
    NSString *sdpString = description.sdp;
    NSString *lineSeparator = @"\n";
    NSString *mLineSeparator = @" ";
    // Copied from PeerConnectionClient.java.
    // TODO(tkchin): Move this to a shared C++ file.
    NSMutableArray *lines =
    [NSMutableArray arrayWithArray:
     [sdpString componentsSeparatedByString:lineSeparator]];
    // Find the line starting with "m=video".
    NSInteger mLineIndex = -1;
    for (NSInteger i = 0; i < lines.count; ++i) {
        if ([lines[i] hasPrefix:@"m=video"]) {
            mLineIndex = i;
            break;
        }
    }
    if (mLineIndex == -1) {
        RTCLog(@"No m=video line, so can't prefer %@", codec);
        return description;
    }
    // An array with all payload types with name |codec|. The payload types are
    // integers in the range 96-127, but they are stored as strings here.
    NSMutableArray *codecPayloadTypes = [[NSMutableArray alloc] init];
    // a=rtpmap:<payload type> <encoding name>/<clock rate>
    // [/<encoding parameters>]
    NSString *pattern =
    [NSString stringWithFormat:@"^a=rtpmap:(\\d+) %@(/\\d+)+[\r]?$", codec];
    NSRegularExpression *regex =
    [NSRegularExpression regularExpressionWithPattern:pattern
                                              options:0
                                                error:nil];
    for (NSString *line in lines) {
        NSTextCheckingResult *codecMatches =
        [regex firstMatchInString:line
                          options:0
                            range:NSMakeRange(0, line.length)];
        if (codecMatches) {
            [codecPayloadTypes
             addObject:[line substringWithRange:[codecMatches rangeAtIndex:1]]];
        }
    }
    if ([codecPayloadTypes count] == 0) {
        RTCLog(@"No payload types with name %@", codec);
        return description;
    }
    NSArray *origMLineParts =
    [lines[mLineIndex] componentsSeparatedByString:mLineSeparator];
    // The format of ML should be: m=<media> <port> <proto> <fmt> ...
    const int kHeaderLength = 3;
    if (origMLineParts.count <= kHeaderLength) {
        RTCLogWarning(@"Wrong SDP media description format: %@", lines[mLineIndex]);
        return description;
    }
    // Split the line into header and payloadTypes.
    NSRange headerRange = NSMakeRange(0, kHeaderLength);
    NSRange payloadRange =
    NSMakeRange(kHeaderLength, origMLineParts.count - kHeaderLength);
    NSArray *header = [origMLineParts subarrayWithRange:headerRange];
    NSMutableArray *payloadTypes = [NSMutableArray
                                    arrayWithArray:[origMLineParts subarrayWithRange:payloadRange]];
    // Reconstruct the line with |codecPayloadTypes| moved to the beginning of the
    // payload types.
    NSMutableArray *newMLineParts = [NSMutableArray arrayWithCapacity:origMLineParts.count];
    [newMLineParts addObjectsFromArray:header];
    [newMLineParts addObjectsFromArray:codecPayloadTypes];
    [payloadTypes removeObjectsInArray:codecPayloadTypes];
    [newMLineParts addObjectsFromArray:payloadTypes];
    
    NSString *newMLine = [newMLineParts componentsJoinedByString:mLineSeparator];
    [lines replaceObjectAtIndex:mLineIndex
                     withObject:newMLine];
    
    NSString *mangledSdpString = [lines componentsJoinedByString:lineSeparator];
    return [[RTCSessionDescription alloc] initWithType:description.type
                                                   sdp:mangledSdpString];
}

@end

