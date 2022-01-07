//
//  RootModel.h
//  SKGenerateModelTool
//
//  Created by wushangkun on 2022/12/31.
//  Copyright © 2021 SKGenerateModelTool. All rights reserved.
//

#if __has_include(<YYModel/YYModel.h>)
#import <YYModel/YYModel.h>
#else
#import "YYModel.h"
#endif

@class LastResponseExtraModel;
@class DataModel;
@class TipsModel;

@interface RootModel : NSObject <YYModel>

@property (nonatomic, strong) LastResponseExtraModel *last_response_extra;
@property (nonatomic, strong) id api_base_info;
@property (nonatomic, assign) NSInteger show_et_status;
@property (nonatomic, strong) id location;
@property (nonatomic, copy) NSString *post_content_hint;
@property (nonatomic, assign) BOOL get_offline_pool;
@property (nonatomic, assign) BOOL is_use_bytedance_stream;
@property (nonatomic, assign) NSInteger feed_flag;
@property (nonatomic, assign) BOOL has_more;
@property (nonatomic, assign) NSInteger total_number;
@property (nonatomic, strong) TipsModel *tips;
@property (nonatomic, assign) BOOL has_more_to_refresh;
@property (nonatomic, assign) BOOL show_last_read;
@property (nonatomic, assign) NSInteger action_to_last_stick;
@property (nonatomic, assign) NSInteger login_status;
@property (nonatomic, strong) NSArray <DataModel *> *data;
@property (nonatomic, copy) NSString *message;

@end


@interface TipsModel : NSObject <YYModel>

@property (nonatomic, copy) NSString *download_url;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *web_url;
@property (nonatomic, copy) NSString *display_template;
@property (nonatomic, assign) NSInteger display_duration;
@property (nonatomic, copy) NSString *open_url;
@property (nonatomic, copy) NSString *package_name;
@property (nonatomic, copy) NSString *display_info;
@property (nonatomic, copy) NSString *app_name;

@end


@interface DataModel : NSObject <YYModel>

@property (nonatomic, copy) NSString *code;
@property (nonatomic, copy) NSString *content;

@end


@interface LastResponseExtraModel : NSObject <YYModel>

@property (nonatomic, copy) NSString *data;

@end


