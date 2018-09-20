## BlockNotification 是一套 iOS 消息框架:
* 支持block方式监听回调
* 不需要在启动阶段对通知相关的数据结构做任何注册
* 用法简单，使用BN相关宏对BlockNotification框架下的通知进行声明及定义，即可在任意模块中做监听
* 支持回调参数检查，调用监听api时，与通知定义不匹配的回调注册不予通过，且在DEBUG编译下招聘OC异常
* 参数检查0.0.1版本只支持所有参数顺序及类型完全相同的回调注册成功
* 待添加特性:对象类型参数支持监听回调使用对应的派生类 
* 监听的observer析构后，其此前相应的通知注册会自动移除，不需要在析构时显式移除
* 支持注册通知回调时对回调block中强持有observer这种内存泄漏的情况进行检查，并在回调强持有observer且使用DEBUG环境编译时抛OC异常

## Usage

cocoapod 使用方式  
~~~~
pod 'BlockNotification','0.0.10'
~~~~

在确保头文件BlockNotificationCenter.h能正确引用到的情况下  

#### 头文件中声明  
`BN_Dec(kNotificationSpecificSubject,NSString* subjectName,int gradepoint);`


#### 实现文件中定义  
`BN_Def(kNotificationSpecificSubject,NSString* subjectName,int gradepoint);`


#### 监听
回调参数与消息定义不一致时返回NO，并在开发期DEBUG编译下抛异常提醒，同时如果回调中强持有self会在开发期DEBUG编译下抛异常提醒  
`[self observeBlockNotification:kNotificationSpecificSubject callback:^(NSString* subjectName,int gradepoint){    } queue:queue];`  
//此回调会在kNotificationSpecificSubject通知触发，即用BN_Post 触发kNotificationSpecificSubject通知时被回调  
//记住别强引用self，别显式使用self，除非定义了self的弱引用局部变量,实例变量名也要注意，最坑的，宏里面有使用到self  


#### 发送  
`BN_Post(kNotificationSpecificSubject,@"physics",5);`

#### 更便捷的通知监听方法,即可以使用@selector(on+通知名)这个方法直接传入通知回调

`[self onkNotificationSpecificSubject:^(NSString* subjectName,int gradepoint){   } queue:queue];     `
