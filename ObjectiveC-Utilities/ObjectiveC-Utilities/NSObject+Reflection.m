//
//  NSObject+Reflection.m
//  ObjectiveC-Utilities
//
//  Created by Tomasz Telepko on 13.11.2011.
//  Copyright 2011 softt.eu All rights reserved.
//

#import "NSObject+Reflection.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation NSObject (Reflection)

- (NSString *)formatDateForJson:(NSDate *)date {
    NSDateFormatter *jsonDateFormatter = [[NSDateFormatter alloc] init];
    jsonDateFormatter.dateFormat = @"Z";
    
    NSString *result = [NSString stringWithFormat:@"\/Date(%qi%@)\/", (long long)([date timeIntervalSince1970] * 1000), [jsonDateFormatter stringFromDate:date]];
    [jsonDateFormatter release];
    return result;
}

- (NSDictionary *)dumpToDictionary {
    NSMutableDictionary *result = [[[NSMutableDictionary alloc] init] autorelease];    
    NSDictionary *properties = [[self getProperties] retain];
    
    for (NSString *propertyName in [properties allKeys]) {
        id value = [self valueForKey:propertyName];
        
        NSMutableString *pascalCasedPropertyName = [NSMutableString stringWithString:propertyName];
        NSString *firstLetter = [[pascalCasedPropertyName substringToIndex:1] uppercaseString];
        [pascalCasedPropertyName replaceCharactersInRange:NSMakeRange(0, 1) withString:firstLetter];
        
        if (![value isKindOfClass:[NSNull class]] && value != nil) {    
            if ([value isKindOfClass:[NSDate class]]) {
                NSString *jsonDate = [self formatDateForJson:value];
                [result setObject:jsonDate forKey:pascalCasedPropertyName];
            } else {
                [result setObject:value forKey:pascalCasedPropertyName];
            }
        }        
    }
    
    [properties release];    
    return result;
}

- (void)fillFromDictionary:(NSDictionary *)dictionary withArrayMap:(NSDictionary *)map {
    NSString *typeName = [NSString stringWithCString:class_getName([self class]) encoding:NSUTF8StringEncoding];
    NSDictionary *properties = [[self getProperties] retain];
    
    for (NSString *item in [dictionary allKeys]) {
        NSMutableString *key = [NSMutableString stringWithString:item];
        
        id value = [dictionary objectForKey:key];
        
        if (![properties objectForKey:key]) { //property not found, try lowering first letter
            NSString *firstLetter = [[key substringToIndex:1] lowercaseString];
            [key replaceCharactersInRange:NSMakeRange(0, 1) withString:firstLetter];
            if (![properties objectForKey:key]) { //if still not found, give up
                continue;
            }
        }        
        
        NSString *propertyTypeString = [properties objectForKey:key];
        NSString *propertyType = nil;
        if ([[propertyTypeString substringToIndex:1] isEqualToString:@"@"]) {
            propertyType = [propertyTypeString substringWithRange:NSMakeRange(2, [propertyTypeString length] - 3)];
        }
        
        if ([value isKindOfClass:[NSDictionary class]]) { //item is an object
            id instance = [NSClassFromString(propertyType) new];
            [instance fillFromDictionary:value withArrayMap:map];
            
            [self setValue:instance forKey:key];
            [instance release];
            
        } else if ([value isKindOfClass:[NSArray class]]) { //item is a collection; map is needed to create a proper collection element type
            NSString *mapKey = [NSString stringWithFormat:@"%@:%@", typeName, item];
            NSString *itemType = [map objectForKey:mapKey];
            
            if (itemType != nil) {
                NSMutableArray *array = [NSMutableArray new];
                for (NSDictionary *subItem in value) {
                    id instance = [NSClassFromString(itemType) new];
                    [instance fillFromDictionary:subItem withArrayMap:map];
                    
                    [array addObject:instance];
                    [instance release];
                }
                
                [self setValue:array forKey:key];
                [array release];
            }
            
        } else if ([propertyType isEqualToString:@"NSDate"] && ![value isKindOfClass:[NSNull class]]) { //item is a date
            NSString *rawValue = value;
            if ([rawValue length] > 0) {
                rawValue = [rawValue substringWithRange:NSMakeRange(6, [rawValue length] - 8)];
                NSArray *parts = [rawValue componentsSeparatedByString:@"+"];
                double milliseconds = [[parts objectAtIndex:0] doubleValue];
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:milliseconds / 1000];
                [self setValue:date forKey:key];
            }
        } else { //item is a simple value
            [self setValue:value forKey:key];
        }        
    }
    
    [properties release];
}

- (NSDictionary *)getProperties {
    NSMutableDictionary *dictionary = [[[NSMutableDictionary alloc] init] autorelease];
    
    Class cl = [self class];
    while (cl != nil && cl != [NSObject class]) {
        uint count = 0;
        objc_property_t *properties = class_copyPropertyList(cl, &count);
        
        for (int i = 0; i < count; i++) {
            objc_property_t property = properties[i];
            
            NSString *propertyName = [[NSString alloc] initWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
            NSString *propertyAttributes = [[NSString alloc] initWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
            
            NSArray *parts = [propertyAttributes componentsSeparatedByString:@","];
            NSString *typeString = [[parts objectAtIndex:0] substringFromIndex:1];
            
            [dictionary setObject:typeString forKey:propertyName];
            
            [propertyName release];
            [propertyAttributes release];
        }    
        
        free(properties);   
        
        cl = [cl superclass];
    }
    
    return dictionary;
}

@end
