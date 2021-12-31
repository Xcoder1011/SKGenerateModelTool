//
//  RootModel.h
//  SKGenerateModelTool
//
//  Created by SKGenerateModelTool on 2021/12/31.
//  Copyright © 2021 SKGenerateModelTool. All rights reserved.
//

#import "YYModel.h"

@class TipsModel;
@class DataModel;
@class LastResponseExtraModel;

@interface RootModel : YYModel

@property (nonatomic, assign) BOOL show_last_read;
@property (nonatomic, assign) NSInteger action_to_last_stick;
@property (nonatomic, copy) NSString *post_content_hint;
@property (nonatomic, assign) NSInteger total_number;
@property (nonatomic, strong) id location;
@property (nonatomic, assign) BOOL has_more_to_refresh;
@property (nonatomic, assign) BOOL get_offline_pool;
@property (nonatomic, strong) TipsModel *tips;
@property (nonatomic, assign) NSInteger feed_flag;
@property (nonatomic, strong) id api_base_info;
@property (nonatomic, assign) NSInteger login_status;
@property (nonatomic, assign) BOOL is_use_bytedance_stream;
@property (nonatomic, strong) NSArray <DataModel *> *data;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, strong) LastResponseExtraModel *last_response_extra;
@property (nonatomic, assign) NSInteger show_et_status;
@property (nonatomic, assign) BOOL has_more;

@end


@interface LastResponseExtraModel : YYModel

@property (nonatomic, copy) NSString *data;

@end


@interface DataModel : YYModel

@property (nonatomic, copy) NSString *code;
@property (nonatomic, copy) NSString *content;

@end


@interface TipsModel : YYModel

@property (nonatomic, assign) NSInteger display_duration;
@property (nonatomic, copy) NSString *display_template;
@property (nonatomic, copy) NSString *app_name;
@property (nonatomic, copy) NSString *download_url;
@property (nonatomic, copy) NSString *open_url;
@property (nonatomic, copy) NSString *display_info;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *web_url;
@property (nonatomic, copy) NSString *package_name;

@end

