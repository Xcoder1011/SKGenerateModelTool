# SKGenerateModelTool


- #####支持通过URL链接或json字符串一键生成model文件
- #####支持字符串加密（可设置不同的密钥，开发者可自行修改加密算法）
- #####支持自定义model父类、自定义model前缀、自定义文件名、自定义作者名
- #####支持OC / Swift 
- #####支持自定义输出文件夹路径
- #####兼容YYModel / MJExtension / HandyJSON解析
- #####兼容服务端返回“id”字段
- #####支持类驼峰命名

- Supports one-click generation of model files through URL links or json strings
- Support string encryption (different keys can be set, developers can modify the encryption algorithm)
- Support custom model parent class, custom model prefix, custom file name, custom author name
- Support OC / Swift
- Support custom output folder path
- Compatible with YYModel / MJExtension analysis
- Compatible server returns "id" field
- Supports hump naming

![SKGenerateModelTool](https://upload-images.jianshu.io/upload_images/1129777-9c130b4ce345ddf9.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

###### 生成Model
![生成Model](https://upload-images.jianshu.io/upload_images/1129777-51a3b41012e11c96.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

###### 字符串加密示例
![字符串加密示例](https://upload-images.jianshu.io/upload_images/1129777-1fc076f8a5f16768.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

加密后的内容添加到项目中（声明和定义可以分别放.h和.m），因为代码依赖SKEncryptString结构体，所以需要导入头文件**SKEncryptHeader.h**引用。

> 只需把此头文件（SKEncryptHeader.h）加入到项目，并在pch文件中导入该头文件即可使用;
Just add this header file (SKEncryptHeader.h) to the project and import the header file in the pch file to use;

![SKEncryptHeader.h](https://upload-images.jianshu.io/upload_images/1129777-aa68b75c0934fc6c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

加密后的数据申明：

```
/** 需要加密的重要字符，比如AppKey、AppSecret、AppID、数据库密码等 */
extern const SKEncryptString * const _3596508958;

/** Important characters that need to be encrypted, such as appkey, appsecret, appid, database password, etc */
extern const SKEncryptString * const _4038772756;

/** appkeyhdfoashiodfowehfowefjqwehgpqegpifhwappkey */
extern const SKEncryptString * const _3908173925;
```

定义：
```
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
```

使用时
```
        if let string =  sk_OCString(_3596508958) {
            print("示例：解密后的数据为：\(string)")
        }
        if let string =  sk_OCString(_4038772756) {
            print("The decrypted data is：\(string)")
        }
```

Tip：本工具仅用到简单的XOR加密算法，开发者可自行下载项目进行加密算法修改，另外也可直接下载项目里的dmg文件进行安装使用。
