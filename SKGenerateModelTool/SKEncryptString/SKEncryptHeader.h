//
//  SKEncryptHeader.h
//  SKGenerateModelTool
//
//  Created by shangkun on 2020/5/27.
//  Copyright © 2020 wushangkun. All rights reserved.
//
//

/////////////////////////////////////////////////////////////////////////////////////
///        https://github.com/Xcoder1011/SKGenerateModelTool
/////////////////////////////////////////////////////////////////////////////////////

/*
 
1. 只需把此头文件（SKEncryptHeader.h）加入到项目，并在pch文件中导入该头文件即可使用;
1. Just add this header file (SKEncryptHeader.h) to the project and import the header file in the pch file to use;
 
2. 加密：使用SKGenerateModelTool进行数据加密，支持自定义密钥key;
2. Encryption: Use SKGenerateModelTool for data encryption and support custom key;

3. 解密：（参考以下范例）
3. Decrypt: (refer to the following example)
 
if let string =  sk_OCString(_3596508958) {
    print("示例：解密后的数据为：\(string)")
}
 
 */

/////////////////////////////////////////////////////////////////////////////////////
///
/////////////////////////////////////////////////////////////////////////////////////


#ifndef SKEncryptHeader_h
#define SKEncryptHeader_h

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    char factor;
    char *value;
    int length;
    char *key;
    int kl;
    char decoded;
}SKEncryptString;

/// retutn decrypted C string.
/// @param data  encrypted data
static inline const char *sk_CString(const SKEncryptString *data) {
    if (data->decoded == 1) {
        return data->value;
    }
    int kl = data->kl;
    char a = 99;
    if (kl > 0) {
        char b = 100;
        for (int i = 0; i < kl; i++) {
            data->key[i] ^= (data->factor ^ b);
        }
        int cipherIndex = 0;
        for (int i = 0; i < data->length; i++) {
            cipherIndex = cipherIndex % kl;
            data->value[i] ^= (data->factor ^ a ^ data->key[cipherIndex]);
            cipherIndex++;
        }
    } else {
        for (int i = 0; i < data->length; i++) {
            data->value[i] ^= (data->factor ^ a);
        }
    }
    ((SKEncryptString *)data)->decoded = 1;
    return data->value;
}


#ifdef __OBJC__
#import <Foundation/Foundation.h>

/// retutn decrypted NSString.
/// @param data  encrypted data
static inline NSString *sk_OCString(const SKEncryptString *data)
{
    return [NSString stringWithUTF8String:sk_CString(data)];
}
#endif

#ifdef __cplusplus
}
#endif

#endif /* SKEncryptHeader_h */
