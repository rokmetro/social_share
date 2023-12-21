//
//  Created by Shekar Mudaliyar on 12/12/19.
//  Copyright © 2019 Shekar Mudaliyar. All rights reserved.
//

#import "SocialSharePlugin.h"
#include <objc/runtime.h>

NSString* _stringValue(NSObject* value);

@implementation SocialSharePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"social_share" binaryMessenger:[registrar messenger]];
  SocialSharePlugin* instance = [[SocialSharePlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"shareInstagramStory" isEqualToString:call.method] || [@"shareFacebookStory" isEqualToString:call.method]) {

        NSString *destination;
        NSString *stories;
        if ([@"shareInstagramStory" isEqualToString:call.method]) {
            destination = @"com.instagram.sharedSticker";
            stories = @"instagram-stories";
        } else {
            destination = @"com.facebook.sharedSticker";
            stories = @"facebook-stories";
        }

        NSString *stickerImage = _stringValue(call.arguments[@"stickerImage"]);
        NSString *backgroundTopColor = _stringValue(call.arguments[@"backgroundTopColor"]);
        NSString *backgroundBottomColor = _stringValue(call.arguments[@"backgroundBottomColor"]);
        NSString *attributionURL = _stringValue(call.arguments[@"attributionURL"]);
        NSString *backgroundImage = _stringValue(call.arguments[@"backgroundImage"]);
        NSString *backgroundVideo = _stringValue(call.arguments[@"backgroundVideo"]);
        NSString *appId = _stringValue(call.arguments[@"appId"]);
        

        NSFileManager *fileManager = [NSFileManager defaultManager];

        if (appId.length == 0) {
            NSString *path = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
            NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
            appId = _stringValue([dict objectForKey:@"FacebookAppID"]);
        }
        
        // Assign background image asset and attribution link URL to pasteboard
        NSMutableDictionary *pasteboardItems = [[NSMutableDictionary alloc] init];

        if ( (0 < stickerImage.length) && [fileManager fileExistsAtPath: stickerImage]) {
           NSData *imgShare = [[NSData alloc] initWithContentsOfFile:stickerImage];
           [pasteboardItems setObject:imgShare forKey:[NSString stringWithFormat:@"%@.stickerImage", destination]];
        }
        
        if (0 < backgroundTopColor.length) {
            [pasteboardItems setObject:backgroundTopColor forKey:[NSString stringWithFormat:@"%@.backgroundTopColor", destination]];
        }
        
        if (0 < backgroundBottomColor.length) {
            [pasteboardItems setObject:backgroundBottomColor forKey:[NSString stringWithFormat:@"%@.backgroundBottomColor",destination]];
        }
        
        if (0 < attributionURL.length) {
            [pasteboardItems setObject:attributionURL forKey:[NSString stringWithFormat:@"%@.contentURL", destination]];
        }
        
        if ((0 < appId.length) && [@"shareFacebookStory" isEqualToString:call.method]) {
            [pasteboardItems setObject:appId forKey:[NSString stringWithFormat:@"%@.appID", destination]];
        }
        
        //if you have a background image
        if ((0 < backgroundImage.length) && [fileManager fileExistsAtPath: backgroundImage]) {
            NSData *imgBackgroundShare = [[NSData alloc] initWithContentsOfFile:backgroundImage];
            [pasteboardItems setObject:imgBackgroundShare forKey:[NSString stringWithFormat:@"%@.backgroundImage", destination]];
        }
        //if you have a background video
        if ((0 < backgroundVideo.length) && [fileManager fileExistsAtPath: backgroundVideo]) {
            NSData *videoBackgroundShare = [[NSData alloc] initWithContentsOfFile:backgroundVideo options:NSDataReadingMappedIfSafe error:nil];
            [pasteboardItems setObject:videoBackgroundShare forKey:[NSString stringWithFormat:@"%@.backgroundVideo",destination]];
        }

        NSURL *urlScheme = [NSURL URLWithString:[NSString stringWithFormat:@"%@://share?source_application=%@", stories, appId]];
        
        if ((urlScheme != nil) && [[UIApplication sharedApplication] canOpenURL:urlScheme]) {

            if (@available(iOS 10.0, *)) {
            NSDictionary *pasteboardOptions = @{UIPasteboardOptionExpirationDate : [[NSDate date] dateByAddingTimeInterval:60 * 5]};
            // This call is iOS 10+, can use 'setItems' depending on what versions you support
            [[UIPasteboard generalPasteboard] setItems:@[pasteboardItems] options:pasteboardOptions];

            [[UIApplication sharedApplication] openURL:urlScheme options:@{} completionHandler:nil];
              result(@"success");
            } else {
                result(@"error");
            }
        } else {
            result(@"error");
        }
    }
    else if ([@"copyToClipboard" isEqualToString:call.method]) {
        
        NSString *content = _stringValue(call.arguments[@"content"]);
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        //assigning content to pasteboard
         if (0 < content.length) {
            pasteboard.string = content;
        }
        //assigning image to pasteboard
        NSString *image = _stringValue(call.arguments[@"image"]);
        if ((0 < image.length) && [[NSFileManager defaultManager] fileExistsAtPath: image]) {
            UIImage *imageData = [[UIImage alloc] initWithContentsOfFile:image];
            pasteboard.image = imageData;
        }
        
        result(@"success");
        
    } else if ([@"shareTwitter" isEqualToString:call.method]) {
        NSString *captionText = _stringValue(call.arguments[@"captionText"]);
        
        NSString *urlSchemeTwitter = [NSString stringWithFormat:@"twitter://post?message=%@",captionText];
        NSString* urlTextEscaped = [urlSchemeTwitter stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURL *urlSchemeSend = [NSURL URLWithString:urlTextEscaped];
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:urlSchemeSend options:@{} completionHandler:nil];
            result(@"success");
        } else {
            result(@"error");
        }
    
    } else if ([@"shareSms" isEqualToString:call.method]) {
        NSString *msg = _stringValue(call.arguments[@"message"]);
        NSString *urlLink = _stringValue(call.arguments[@"urlLink"]);
        NSString *trailingText = _stringValue(call.arguments[@"trailingText"]);
        
        NSMutableString *smsBody = [[NSMutableString alloc] init];
        if (0 < msg.length) {
	        [smsBody appendString: msg];
				}
				if (0 < urlLink.length) {
	        [smsBody appendString: urlLink];
				}
				if (0 < trailingText.length) {
	        [smsBody appendString: trailingText];
				}
        NSString *smsBodyEscaped = [smsBody stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
				NSString *smsUrlString = [NSString stringWithFormat:@"sms:&body=%@", smsBodyEscaped];
        NSURL *smsUrl = [NSURL URLWithString: smsUrlString];
				if ((smsUrl != nil) && [[UIApplication sharedApplication] canOpenURL:smsUrl]) {
						if (@available(iOS 10.0, *)) {
								[[UIApplication sharedApplication] openURL:smsUrl options:@{} completionHandler:nil];
								result(@"success");
						} else {
								result(@"error");
						}
				} else {
					result(@"error");
				}
    } else if ([@"shareSlack" isEqualToString:call.method]) {
        //NSString *content = call.arguments[@"content"];
        result([NSNumber numberWithBool:YES]);
    } else if ([@"shareWhatsapp" isEqualToString:call.method]) {
        NSString *content = _stringValue(call.arguments[@"content"]);
        NSString * urlWhats = [NSString stringWithFormat:@"whatsapp://send?text=%@",content];
        NSURL * whatsappURL = [NSURL URLWithString:[urlWhats stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        if ((whatsappURL != nil) && [[UIApplication sharedApplication] canOpenURL: whatsappURL]) {
            [[UIApplication sharedApplication] openURL: whatsappURL];
            result(@"success");
        } else {
            result(@"error");
        }
        result([NSNumber numberWithBool:YES]);
    } else if ([@"shareTelegram" isEqualToString:call.method]) {
        NSString *content = _stringValue(call.arguments[@"content"]);
        NSString * urlScheme = [NSString stringWithFormat:@"tg://msg?text=%@",content];
        NSURL * telegramURL = [NSURL URLWithString:[urlScheme stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        if ((telegramURL != nil) && [[UIApplication sharedApplication] canOpenURL: telegramURL]) {
            [[UIApplication sharedApplication] openURL: telegramURL];
            result(@"success");
        } else {
            result(@"error");
        }
        result([NSNumber numberWithBool:YES]);
    } else if ([@"shareOptions" isEqualToString:call.method]) {
        NSString *content = _stringValue(call.arguments[@"content"]);
        NSString *image = _stringValue(call.arguments[@"image"]);
        NSMutableArray *objectsToShare = [[NSMutableArray alloc] init];
        
				//checking if it contains text
        if (0 < content.length) {
        	[objectsToShare addObject:content];
        }
				//checking if it contains image file
        if (0 < image.length) {
						//when image file is included
						NSFileManager *fileManager = [NSFileManager defaultManager];
						BOOL isFileExist = [fileManager fileExistsAtPath: image];
						UIImage *imgShare = isFileExist ? [[UIImage alloc] initWithContentsOfFile:image] : nil;
						if (imgShare != nil) {
		        	[objectsToShare addObject:imgShare];
						}
				}
				
				if (0 < objectsToShare.count) {
						UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
						UIViewController *controller =[UIApplication sharedApplication].keyWindow.rootViewController;
                        activityVC.popoverPresentationController.sourceView = [UIApplication sharedApplication].keyWindow;
                        activityVC.popoverPresentationController.sourceRect = CGRectMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height/4, 0, 0);
                        [controller presentViewController:activityVC animated:YES completion:nil];
						result([NSNumber numberWithBool:YES]);
				}
				else {
						result([NSNumber numberWithBool:NO]);
				}

    } else if ([@"checkInstalledApps" isEqualToString:call.method]) {
        NSMutableDictionary *installedApps = [[NSMutableDictionary alloc] init];
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"instagram-stories://"]]) {
            [installedApps setObject:[NSNumber numberWithBool: YES] forKey:@"instagram"];
        } else {
            [installedApps setObject:[NSNumber numberWithBool: NO] forKey:@"instagram"];
        }

        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"facebook-stories://"]]) {
            [installedApps setObject:[NSNumber numberWithBool: YES] forKey:@"facebook"];
        } else {
            [installedApps setObject:[NSNumber numberWithBool: NO] forKey:@"facebook"];
        }

        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
            [installedApps setObject:[NSNumber numberWithBool: YES] forKey:@"twitter"];
        } else {
            [installedApps setObject:[NSNumber numberWithBool: NO] forKey:@"twitter"];
        }

        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"sms://"]]) {
            [installedApps setObject:[NSNumber numberWithBool: YES] forKey:@"sms"];
        } else {
            [installedApps setObject:[NSNumber numberWithBool: NO] forKey:@"sms"];
        }

        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"whatsapp://"]]) {
            [installedApps setObject:[NSNumber numberWithBool: YES] forKey:@"whatsapp"];
        } else {
            [installedApps setObject:[NSNumber numberWithBool: NO] forKey:@"whatsapp"];
        }

        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tg://"]]) {
            [installedApps setObject:[NSNumber numberWithBool: YES] forKey:@"telegram"];
        } else {
            [installedApps setObject:[NSNumber numberWithBool: NO] forKey:@"telegram"];
        }
        result(installedApps);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end

NSString* _stringValue(NSObject* value) {
	return [value isKindOfClass:[NSString class]] ? value : nil;
}
