//
//  RootModel.swift
//  SKGenerateModelTool
//
//  Created by SKGenerateModelTool on 2021/12/31.
//  Copyright © 2021 SKGenerateModelTool. All rights reserved.
//

import HandyJSON

class RootModel : HandyJSON {
    var login_status: Int = 0  
    var feed_flag: Int = 0  
    var is_use_bytedance_stream: Bool = false  
    var location: Any?  
    var tips: TipsModel?
    var action_to_last_stick: Int = 0  
    var total_number: Int = 0  
    var show_et_status: Int = 0  
    var has_more: Bool = false  
    var post_content_hint: String?  
    var last_response_extra: LastResponseExtraModel?
    var api_base_info: Any?  
    var data: [DataModel]?  
    var message: String?  
    var get_offline_pool: Bool = false  
    var show_last_read: Bool = false  
    var has_more_to_refresh: Bool = false  

    required init() {}
}

class LastResponseExtraModel : HandyJSON {
    var data: String?  

    required init() {}
}

class DataModel : HandyJSON {
    var content: String?  
    var code: String?  

    required init() {}
}

class TipsModel : HandyJSON {
    var open_url: String?  
    var display_duration: Int = 0  
    var web_url: String?  
    var package_name: String?  
    var display_info: String?  
    var app_name: String?  
    var display_template: String?  
    var download_url: String?  
    var type: String?  

    required init() {}
}
