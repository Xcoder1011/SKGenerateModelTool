//
//  EncryptExampleModel.m
//  SKGenerateModelTool
//
//  Created by shangkun on 2020/7/16.
//  Copyright © 2020 wushangkun. All rights reserved.
//

#import "EncryptExampleModel.h"

/** 需要加密的重要字符，比如AppKey、AppSecret、AppID、数据库密码等 */
const SKEncryptString * const _3596508958 = &(SKEncryptString){
       .factor = (char)9,
       .value = (char[]){-125,-10,-22,-126,-52,-21,-113,-32,-54,-113,-59,-20,-115,-16,-18,-125,-19,-25,-126,-52,-21,-113,-57,-3,-115,-58,-52,-123,-42,-26,-116,-59,-2,-113,-52,-24,43,26,26,33,15,19,-119,-22,-21,43,26,26,57,15,9,24,15,30,-119,-22,-21,43,26,26,35,46,-119,-22,-21,-116,-1,-38,-116,-25,-60,-113,-48,-7,-113,-59,-20,-115,-54,-21,-115,-57,-29,0},
       .length = 83,
};

/** Important characters that need to be encrypted, such as appkey, appsecret, appid, database password, etc */
const SKEncryptString * const _4038772756 = &(SKEncryptString){
       .factor = (char)100,
       .value = (char[]){57,31,4,0,20,29,1,2,6,73,19,26,21,29,7,10,20,9,0,26,80,6,28,14,18,73,14,9,23,13,80,6,27,79,4,12,64,9,28,10,2,11,4,27,3,13,76,76,1,28,19,26,84,14,21,73,1,28,2,2,21,11,88,79,7,25,16,31,23,10,2,23,0,67,70,8,16,28,27,13,92,82,16,14,18,8,2,13,1,12,80,2,21,28,21,30,15,30,22,69,80,23,0,12,0},
       .length = 104,
       .key = (char[]){119,117,115,104,97,110,103,107,117,110,0},
       .kl = 10
};

/** appkeyhdfoashiodfowehfowefjqwehgpqegpifhwappkey */
const SKEncryptString * const _3908173925 = &(SKEncryptString){
       .factor = (char)50,
       .value = (char[]){4,20,23,14,1,30,13,0,1,10,5,20,13,13,8,1,2,8,18,1,15,3,11,16,0,2,13,20,19,2,13,3,23,20,1,0,21,13,1,13,19,6,21,20,12,0,29,0},
       .length = 47,
       .key = (char[]){98,99,96,0},
       .kl = 3
};

/** Swift版：https://github.com/Xcoder1011/SKGenerateModelTool */
const SKEncryptString * const _1242105574 = &(SKEncryptString){
       .factor = (char)24,
       .value = (char[]){40,12,18,29,15,-100,-14,-13,-108,-57,-31,19,15,15,11,8,65,84,84,28,18,15,19,14,25,85,24,20,22,84,35,24,20,31,30,9,74,75,74,74,84,40,48,60,30,21,30,9,26,15,30,54,20,31,30,23,47,20,20,23,0},
       .length = 60,
};
