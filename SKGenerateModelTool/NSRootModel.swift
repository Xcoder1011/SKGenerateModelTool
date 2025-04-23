//
//  NSRootModel.swift
//  SKGenerateModelTool
//
//  Created by SHANGKUN on 2025/04/23.
//  Copyright © 2025 SKGenerateModelTool. All rights reserved.
//

struct NSRootModel: Codable {
    var resultbody: JKResultbodyModel?
    var status: String? // 1
    var message: String? // 成功
}

struct JKResultbodyModel: Codable {
    var id: Int = 0 // 1029
    var popJumpUrl: String?
    var userHaveHrReplyRights: Bool = false // true
    var cardSoftMoreDetailList: [JKCardSoftMoreDetailListModel]?
    var cardSoftList: [JKCardSoftListModel]?
    var cardRightsEndDetailList: [JKCardRightsEndDetailListModel]?
    var lastHrReplyOrderId: String?
    var hrReplyRightsLastNum: Int = 0 // 7
    var bubbleTextShowGiftIcon: Bool = false // false
    var userTwoDayNotTalked: Bool = false // false
    var scoreShowRightsLeftDayNum: Int = 0 // 0
    var canUseHrReply: Bool = false // true
    var jobMatchScore: Int = 0 // 50
    var isUserThreeDayNoTalk: Bool = false // false
    var configTextMatchScore: Int = 0 // 85
    var chatBubbleText: String?
    var userLastUseHrReplyIsToday: Bool = false // false
    var jobMatchScoreShow: Int = 0 // 50
    var applyBubbleText: String?
    var giveHrReply: Bool = false // false
    var configThresholdMatchScore: Int = 0 // 80
    var userHaveScoreShowRights: Bool = false // false
    var serviceCanUsed: Bool = false // true
    var userFebruaryAlive: Bool = false // false
}

struct JKCardSoftMoreDetailListModel: Codable {
    var rightsCount: Int = 0 // 7
    var haveRights: Bool = false // false
    var canUseExchange: Bool = false // true
    var skuId: Int = 0 // 491
    var rewardType: String? // 0
    var exchangeGoldCoins: Int = 0 // 20
    var cardType: String? // 1
    var equityId: Int = 0 // 17
}

struct JKCardRightsEndDetailListModel: Codable {
    var rightsEndSkuId: Int = 0 // 491
    var rightsEndEquityId: Int = 0 // 17
    var rightsEndCanUseExchange: Bool = false // true
    var rightsEndExchangeGoldCoins: Int = 0 // 20
    var rightsEndRightsCount: Int = 0 // 7
    var cardType: String? // 1
}

struct JKCardSoftListModel: Codable {
    var cardType: String? // 2
}
