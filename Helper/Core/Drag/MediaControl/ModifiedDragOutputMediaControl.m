//
// --------------------------------------------------------------------------
// ModifiedDragOutputMediaControl.m
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2026
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

#import "ModifiedDragOutputMediaControl.h"
#import "ModificationUtility.h"
#import "SharedUtility.h"
#import "HelperUtility.h"
#import "Constants.h"
#import <Cocoa/Cocoa.h>

@implementation ModifiedDragOutputMediaControl

/// Vars

static ModifiedDragState *_drag;
static double _cumulativeX;
static double _cumulativeY;
static BOOL _eventFired;

/// Threshold for triggering a media control event (in pixels)
static const double kMediaControlThreshold = 50.0;

/// Interface

+ (void)initializeWithDragState:(ModifiedDragState *)dragStateRef {
    _drag = dragStateRef;
    _cumulativeX = 0.0;
    _cumulativeY = 0.0;
    _eventFired = NO;
}

+ (void)handleBecameInUse {
    // Reset state when drag becomes active
    _cumulativeX = 0.0;
    _cumulativeY = 0.0;
    _eventFired = NO;
}

+ (void)handleMouseInputWhileInUseWithDeltaX:(double)deltaX deltaY:(double)deltaY event:(CGEventRef)event {
    
    // Accumulate movement
    _cumulativeX += deltaX;
    _cumulativeY += deltaY;
    
    // Only fire event once per drag gesture
    if (_eventFired) {
        return;
    }
    
    // Check if threshold is crossed
    double absX = fabs(_cumulativeX);
    double absY = fabs(_cumulativeY);
    
    if (absX < kMediaControlThreshold && absY < kMediaControlThreshold) {
        return;
    }
    
    // Determine dominant direction and fire appropriate event
    MFSystemDefinedEventType eventType;
    
    if (absX > absY) {
        // Horizontal gesture
        if (_cumulativeX > 0) {
            eventType = kMFSystemEventTypeMediaForward; // Right = Next track
        } else {
            eventType = kMFSystemEventTypeMediaBack;    // Left = Previous track
        }
    } else {
        // Vertical gesture
        if (_cumulativeY > 0) {
            eventType = kMFSystemEventTypeVolumeDown;   // Down = Volume down (positive Y is down)
        } else {
            eventType = kMFSystemEventTypeVolumeUp;     // Up = Volume up (negative Y is up)
        }
    }
    
    // Post the system event
    [self postSystemDefinedEvent:eventType withModifierFlags:0];
    _eventFired = YES;
}

+ (void)handleDeactivationWhileInUseWithCancel:(BOOL)cancelation {
    // Reset state when drag ends
    _cumulativeX = 0.0;
    _cumulativeY = 0.0;
    _eventFired = NO;
}

+ (void)suspend {
    // No special handling needed for suspend
}

+ (void)unsuspend {
    // No special handling needed for unsuspend
}

#pragma mark - Helper Methods

+ (void)postSystemDefinedEvent:(MFSystemDefinedEventType)type withModifierFlags:(NSEventModifierFlags)modifierFlags {
    /// Post a system defined event for media control or volume control
    /// Based on postSystemDefinedEvent from Actions.m
    
    CGEventTapLocation tapLoc = kCGSessionEventTap;
    NSPoint loc = NSEvent.mouseLocation;
    
    NSInteger data = 0;
    data = data | kMFSystemDefinedEventBase;
    data = data | (type << 16);
    
    NSInteger downData = data;
    NSInteger upData = data | kMFSystemDefinedEventPressedMask;
    
    /// Post key down
    NSTimeInterval ts = [ModificationUtility nsTimeStamp];
    NSEvent *e = [NSEvent otherEventWithType:14 location:loc modifierFlags:modifierFlags timestamp:ts windowNumber:-1 context:nil subtype:8 data1:downData data2:-1];
    CGEventPost(tapLoc, e.CGEvent);
    
    /// Post key up
    ts = [ModificationUtility nsTimeStamp];
    e = [NSEvent otherEventWithType:14 location:loc modifierFlags:modifierFlags timestamp:ts windowNumber:-1 context:nil subtype:8 data1:upData data2:-1];
    CGEventPost(tapLoc, e.CGEvent);
}

@end
