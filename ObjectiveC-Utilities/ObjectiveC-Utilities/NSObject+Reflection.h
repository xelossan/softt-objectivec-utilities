//
//  NSObject+Reflection.h
//  ObjectiveC-Utilities
//
//  Created by Tomasz Telepko on 11-06-13.
//  Copyright 2011 softt.eu All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Reflection)

// Returns a dictionary containing information about object's properties.
// Each dictionary key represents object's property name, and dictionary value is a type of the property.
- (NSDictionary *)getProperties;

// Fills object's properties from dictionary, include any subobjects from dictionary.
// Each dictionary key should represent object's property name, and dictionary value - property value.
// It can be simple value, another NSDictionary (for subobjects) or NSArray for NSArray type properties.
// You can use dictionaries created from JSON using SBJson library.
//
// If object contains an array of other objects, you have to pass a dictionary containing property name to object type map.
// For example if object Country contains an array called Cities, which elements should be of type City, the map entry should be:
// key: @"Country:Cities" value: @"City"
- (void)fillFromDictionary:(NSDictionary *)dictionary withArrayMap:(NSDictionary *)map;

// Returns a dictionary containing entire object's tree data, ready to be passed to SBJson library to create JSON string.
- (NSDictionary *)dumpToDictionary;

@end