//
//  root_model.dart
//  SKGenerateModelTool
//
//  Created by SKGenerateModelTool on 2021/12/31.
//  Copyright © 2021 SKGenerateModelTool. All rights reserved.
//

part 'root_model.m.dart';

class RootModel {
   bool is_use_bytedance_stream;  
   int show_et_status;  
   String message;  
   List<DataModel> data;  
   bool has_more_to_refresh;  
   dynamic location;  
   TipsModel tips;
   int login_status;  
   int feed_flag;  
   bool get_offline_pool;  
   int total_number;  
   int action_to_last_stick;  
   dynamic api_base_info;  
   String post_content_hint;  
   bool has_more;  
   LastResponseExtraModel last_response_extra;
   bool show_last_read;  

   RootModel fromJson(Map<String, dynamic> json) => _$RootModelFromJson(json, this);
   Map<String, dynamic> toJson() => _$RootModelToJson(this);
}

class LastResponseExtraModel {
   String data;  

   LastResponseExtraModel fromJson(Map<String, dynamic> json) => _$LastResponseExtraModelFromJson(json, this);
   Map<String, dynamic> toJson() => _$LastResponseExtraModelToJson(this);
}

class DataModel {
   String code;  
   String content;  

   DataModel fromJson(Map<String, dynamic> json) => _$DataModelFromJson(json, this);
   Map<String, dynamic> toJson() => _$DataModelToJson(this);
}

class TipsModel {
   String package_name;  
   String web_url;  
   String open_url;  
   String type;  
   String display_info;  
   String display_template;  
   String app_name;  
   int display_duration;  
   String download_url;  

   TipsModel fromJson(Map<String, dynamic> json) => _$TipsModelFromJson(json, this);
   Map<String, dynamic> toJson() => _$TipsModelToJson(this);
}
