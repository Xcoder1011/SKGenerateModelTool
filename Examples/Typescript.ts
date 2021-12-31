//
//  RootModel.ts
//  SKGenerateModelTool
//
//  Created by SKGenerateModelTool on 2021/12/31.
//  Copyright © 2021 SKGenerateModelTool. All rights reserved.
//

export interface RootModel {
   message: string;  
   show_et_status: number;  
   api_base_info?: null;
   post_content_hint: string;  
   feed_flag: number;  
   get_offline_pool: boolean;  
   login_status: number;  
   tips: TipsModel;
   location?: null;
   last_response_extra: LastResponseExtraModel;
   show_last_read: boolean;  
   action_to_last_stick: number;  
   data?: (DataModel)[] | null;  
   has_more_to_refresh: boolean;  
   total_number: number;  
   is_use_bytedance_stream: boolean;  
   has_more: boolean;  
}

export interface LastResponseExtraModel {
   data: string;  
}

export interface DataModel {
   code: string;  
   content: string;  
}

export interface TipsModel {
   package_name: string;  
   display_info: string;  
   web_url: string;  
   display_template: string;  
   app_name: string;  
   display_duration: number;  
   type: string;  
   open_url: string;  
   download_url: string;  
}