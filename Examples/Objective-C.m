//
//  RootModel.m
//  SKGenerateModelTool
//
//  Created by SKGenerateModelTool on 2021/12/31.
//  Copyright © 2021 SKGenerateModelTool. All rights reserved.
//

#import "RootModel.h"


@implementation RootModel

+ (NSDictionary<NSString *,id> *)modelContainerPropertyGenericClass
{
     return @{
              @"last_response_extra" : LastResponseExtraModel.class,
              @"data" : DataModel.class,
              @"tips" : TipsModel.class,
             };
}

@end


@implementation LastResponseExtraModel


@end


@implementation DataModel


@end


@implementation TipsModel


@end

