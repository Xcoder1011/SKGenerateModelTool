//
//  root_model.m.dart
//  SKGenerateModelTool
//
//  Created by SKGenerateModelTool on 2021/12/31.
//  Copyright © 2021 SKGenerateModelTool. All rights reserved.
//

part of 'root_model.dart';

RootModel _$RootModelFromJson(Map<String, dynamic> json, RootModel instance) {
   if(json['is_use_bytedance_stream'] != null) {
     instance.is_use_bytedance_stream = json['is_use_bytedance_stream'];
   }
   if(json['show_et_status'] != null) {
     final show_et_status = json['show_et_status'];
     if(show_et_status is String) {
       instance.show_et_status = int.parse(show_et_status);
     } else {
       instance.show_et_status = show_et_status?.toInt();
     }
   }
   if(json['message'] != null) {
     instance.message = json['message']?.toString();
   }
   if(json['data'] != null) {
     instance.data = new List<DataModel>();
     (json['data'] as List).forEach((v) {
       instance.data.add(new DataModel().fromJson(v));
     });
   }
   if(json['has_more_to_refresh'] != null) {
     instance.has_more_to_refresh = json['has_more_to_refresh'];
   }
   if(json['location'] != null) {
     instance.location = json['location'];
   }
   if(json['tips'] != null) {
     instance.tips = new TipsModel().fromJson(json['tips']);
   }
   if(json['login_status'] != null) {
     final login_status = json['login_status'];
     if(login_status is String) {
       instance.login_status = int.parse(login_status);
     } else {
       instance.login_status = login_status?.toInt();
     }
   }
   if(json['feed_flag'] != null) {
     final feed_flag = json['feed_flag'];
     if(feed_flag is String) {
       instance.feed_flag = int.parse(feed_flag);
     } else {
       instance.feed_flag = feed_flag?.toInt();
     }
   }
   if(json['get_offline_pool'] != null) {
     instance.get_offline_pool = json['get_offline_pool'];
   }
   if(json['total_number'] != null) {
     final total_number = json['total_number'];
     if(total_number is String) {
       instance.total_number = int.parse(total_number);
     } else {
       instance.total_number = total_number?.toInt();
     }
   }
   if(json['action_to_last_stick'] != null) {
     final action_to_last_stick = json['action_to_last_stick'];
     if(action_to_last_stick is String) {
       instance.action_to_last_stick = int.parse(action_to_last_stick);
     } else {
       instance.action_to_last_stick = action_to_last_stick?.toInt();
     }
   }
   if(json['api_base_info'] != null) {
     instance.api_base_info = json['api_base_info'];
   }
   if(json['post_content_hint'] != null) {
     instance.post_content_hint = json['post_content_hint']?.toString();
   }
   if(json['has_more'] != null) {
     instance.has_more = json['has_more'];
   }
   if(json['last_response_extra'] != null) {
     instance.last_response_extra = new LastResponseExtraModel().fromJson(json['last_response_extra']);
   }
   if(json['show_last_read'] != null) {
     instance.show_last_read = json['show_last_read'];
   }
   return instance;
}

Map<String, dynamic> _$RootModelToJson(RootModel instance) {
   final Map<String, dynamic> json = new Map<String, dynamic>();
    json['is_use_bytedance_stream'] = instance.is_use_bytedance_stream;
    json['show_et_status'] = instance.show_et_status;
   json['message'] = instance.message;
   if(instance.data != null) {
     json['data'] = instance.data.map((v) => v.toJson()).toList();
   }
    json['has_more_to_refresh'] = instance.has_more_to_refresh;
   if(instance.location != null) {
     json['location'] = instance.location;
   }
   if(instance.tips != null) {
     json['tips'] = instance.tips.toJson();
   }
    json['login_status'] = instance.login_status;
    json['feed_flag'] = instance.feed_flag;
    json['get_offline_pool'] = instance.get_offline_pool;
    json['total_number'] = instance.total_number;
    json['action_to_last_stick'] = instance.action_to_last_stick;
   if(instance.api_base_info != null) {
     json['api_base_info'] = instance.api_base_info;
   }
   json['post_content_hint'] = instance.post_content_hint;
    json['has_more'] = instance.has_more;
   if(instance.last_response_extra != null) {
     json['last_response_extra'] = instance.last_response_extra.toJson();
   }
    json['show_last_read'] = instance.show_last_read;
   return json;
}

LastResponseExtraModel _$LastResponseExtraModelFromJson(Map<String, dynamic> json, LastResponseExtraModel instance) {
   if(json['data'] != null) {
     instance.data = json['data']?.toString();
   }
   return instance;
}

Map<String, dynamic> _$LastResponseExtraModelToJson(LastResponseExtraModel instance) {
   final Map<String, dynamic> json = new Map<String, dynamic>();
   json['data'] = instance.data;
   return json;
}

DataModel _$DataModelFromJson(Map<String, dynamic> json, DataModel instance) {
   if(json['code'] != null) {
     instance.code = json['code']?.toString();
   }
   if(json['content'] != null) {
     instance.content = json['content']?.toString();
   }
   return instance;
}

Map<String, dynamic> _$DataModelToJson(DataModel instance) {
   final Map<String, dynamic> json = new Map<String, dynamic>();
   json['code'] = instance.code;
   json['content'] = instance.content;
   return json;
}

TipsModel _$TipsModelFromJson(Map<String, dynamic> json, TipsModel instance) {
   if(json['package_name'] != null) {
     instance.package_name = json['package_name']?.toString();
   }
   if(json['web_url'] != null) {
     instance.web_url = json['web_url']?.toString();
   }
   if(json['open_url'] != null) {
     instance.open_url = json['open_url']?.toString();
   }
   if(json['type'] != null) {
     instance.type = json['type']?.toString();
   }
   if(json['display_info'] != null) {
     instance.display_info = json['display_info']?.toString();
   }
   if(json['display_template'] != null) {
     instance.display_template = json['display_template']?.toString();
   }
   if(json['app_name'] != null) {
     instance.app_name = json['app_name']?.toString();
   }
   if(json['display_duration'] != null) {
     final display_duration = json['display_duration'];
     if(display_duration is String) {
       instance.display_duration = int.parse(display_duration);
     } else {
       instance.display_duration = display_duration?.toInt();
     }
   }
   if(json['download_url'] != null) {
     instance.download_url = json['download_url']?.toString();
   }
   return instance;
}

Map<String, dynamic> _$TipsModelToJson(TipsModel instance) {
   final Map<String, dynamic> json = new Map<String, dynamic>();
   json['package_name'] = instance.package_name;
   json['web_url'] = instance.web_url;
   json['open_url'] = instance.open_url;
   json['type'] = instance.type;
   json['display_info'] = instance.display_info;
   json['display_template'] = instance.display_template;
   json['app_name'] = instance.app_name;
    json['display_duration'] = instance.display_duration;
   json['download_url'] = instance.download_url;
   return json;
}
