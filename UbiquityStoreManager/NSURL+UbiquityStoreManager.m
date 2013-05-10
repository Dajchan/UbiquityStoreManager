/**
 * Copyright Maarten Billemont (http://www.lhunath.com, lhunath@lyndir.com)
 *
 * See the enclosed file LICENSE for license information (LGPLv3). If you did
 * not receive this file, see http://www.gnu.org/licenses/lgpl-3.0.txt
 *
 * @author   Maarten Billemont <lhunath@lyndir.com>
 * @license  http://www.gnu.org/licenses/lgpl-3.0.txt
 */

//
//  NSURL(USM).h
//  NSURL(USM)
//
//  Created by lhunath on 2013-05-08.
//  Copyright, lhunath (Maarten Billemont) 2013. All rights reserved.
//

#import "NSURL+UbiquityStoreManager.h"

@implementation NSURL(UbiquityStoreManager)

- (BOOL)downloadAndWait {

    do {
        // We use CF API here because it gives us complete control over resetting the property cache.
        // Without this, we sometimes land in an infinite "downloading" loop.
        // I've seen at least one instance where we get stuck in an infinite "downloading" loop without any download actually progressing
        // while the data is already present, which was resolved only by .. rebooting the device.
        CFURLRef cfSelf = (__bridge CFURLRef)(self);
        CFURLClearResourcePropertyCache( cfSelf );
        NSDictionary *properties = (__bridge_transfer NSDictionary *)CFURLCopyResourcePropertiesForKeys( cfSelf, (__bridge CFArrayRef)@[
                NSURLIsUbiquitousItemKey,
                NSURLUbiquitousItemHasUnresolvedConflictsKey,
                NSURLUbiquitousItemIsDownloadedKey,
                NSURLUbiquitousItemIsDownloadingKey
        ], NULL );
        if (!properties)
                // No resources available for this URL: resource doesn't exist.
            return NO;

        if (![properties[NSURLIsUbiquitousItemKey] boolValue])
                // URL is not ubiquitous: no need to wait for it.
            return YES;

        if ([properties[NSURLUbiquitousItemIsDownloadedKey] boolValue])
                // URL is downloaded: done waiting for it.
            return YES;

        if ([properties[NSURLUbiquitousItemHasUnresolvedConflictsKey] boolValue])
                // URL is in conflict: its data is present, just needs resolution.
            return YES;

        if (![properties[NSURLUbiquitousItemIsDownloadingKey] boolValue] &&
            ![[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:self error:nil])
                // Couldn't start downloading URL: resource probably disappeared.
            return NO;

        //if ([[NSData dataWithContentsOfURL:self] length])
        //    printf( "+" );
        //else
        //    printf( "." );

        [NSThread sleepForTimeInterval:0.1];
    } while (true);
}

@end
