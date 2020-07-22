# Mmrz


MmrzGUI 版本现在极少进行维护, 重点工作已经转入网页版 [Mmrz-Sync](https://github.com/zhanglintc/Mmrz-Sync). -- 2017.02.17

小程序已上线, 请扫码或搜索访问:

![wxapp](https://i.v2ex.co/f8pn6BF5l.jpeg)

## 简介:
**Mmrz** 是 **Memorize** 的缩写. 主要就是为了帮助记忆**日语**单词, 当然英语法语西班牙语随便什么语单词也可以, 只是有可能不那么适用而已. 以前用有道单词本背英语单词的时候效率很高, 因为有道单词本根据艾宾浩斯遗忘曲线按时重复提醒让你记忆单词. 后来想背日语单词却苦于没有类似的工具能达成类似的效果.

工欲善其事, 必先利其器. 趁着正在学习 Ruby 语法索性撸了一个小工具同样按照艾宾浩斯遗忘曲线进行复习提醒. 不过因为没有词库, 所以所有单词需要自行手动输入. 但是其实即使有词库也需要手动查找再添加进入单词本, 手动输入无非是多练习输入了一下日语发音而已.

## 特性:
- 根据遗忘曲线设计背诵时间
- 支持发音功能, 加深记忆
- 支持批量导入生词
- 多客户端同步背诵记录. 同步服务项目: [Mmrz-Sync](https://github.com/zhanglintc/mmrz-sync)
- 支持网页版访问, 访问地址: [mmrz.zhanglintc.co](https://mmrz.zhanglintc.co)

## 展示:
- GUI 版本:

![hidden](https://i.v2ex.co/vnxgBgwd.jpeg)</br>
![shown](https://i.v2ex.co/2B6T4T3P.jpeg)</br>
![finish](https://i.v2ex.co/7MA9u350.jpeg)</br>
![wordbook](https://i.v2ex.co/agrly2NT.jpeg)</br>

- 命令行版本:

![demo](https://i.v2ex.co/vO1aAlap.gif)

## 使用:
`git clone` 本仓库, 然后如下操作:
- GUI 版本: 输入 `ruby MmrzGUI.rbw` 运行, 或者直接双击 `MmrzGUI.rbw` 运行.
- 命令行版本: 输入 `ruby MmrzCLI.rb` 运行.

**注意事项:**

- 需要使用`Ruby 2.0.0`以上版本, 请从[官方下载](http://rubyinstaller.org/)地址获取. 如果要使用GUI版本, 安装时请**务必**勾选`Tcl/Tk`支持, 添加到`Path`路径和`rb`  `rbw`后缀名绑定.

- 可能需要手动安装`sqlite3`. 使用`gem install sqlite3`. 无法安装请参照这里的[解决方案](http://imlane.farbox.com/post/ruby-gemsjing-xiang-yuan-guan-li), 或者直接双击`autoenv.rb`.

- 添加了TTS发音支持, 默认处于关闭状态. 如果需要使用, 请下载我分享的[日语发音库](http://pan.baidu.com/s/1nugP7XR). 安装成功后即会在菜单栏中出现`Speak`选项, 点击即可发音.

- 首次运行即会在当前目录下创建`wordbook.db`数据库. 此数据库**非常重要**, 绝对**不可删除**. 否则所有单词背诵记录将完全丢失, 且无法恢复.

## 功能:
- GUI版本请参照上方的图片展示.
- 命令行版本主要实现了以下几个功能:

**- add:** 进入`Add mode`, 添加模式. 手动按照`"单词 发音(解释) 解释"`(以空格隔开)的格式添加单词到单词本. 每次最少两个数据, 最多三个数据, 否则不予添加进入数据库.

**- delete:** 根据`list`功能显示出来的编号删除某个单词. 格式为`delete wordID`. 例如`delete 3`.

**- load:** 读取指定格式文件, 添加其中每一行数据到数据库, 并进入复习流程. 为防止导入普通文件引入非单词数据, 程序只支持导入`.mmz`格式文件(随便自定义的格式). `.mmz`文件内部格式为:

```
单词1 发音1(解释1) 解释1
单词2 发音2(解释2) 解释2
...
单词N 发音N(解释N) 解释N
```

每行一个单词, 以空格或多个空格隔开. 每行最少两个数据, 最多三个数据, 否则该行不予导入.

**- list:** 显示单词本中的所有单词.

**- mmrz:** 进入`Memorize mode`, 记忆模式. **Mmrz** 会根据从单词本中取出所有提醒时间戳小于当前时间的单词用于背诵. 提醒时间戳由以下方式计算得出

```
第一次提醒(背诵0次): 当前时间 +  5分
第二次提醒(背诵1次): 当前时间 + 30分
第三次提醒(背诵2次): 当前时间 + 12时
第四次提醒(背诵3次): 当前时间 +  1天
第五次提醒(背诵4次): 当前时间 +  2天
第六次提醒(背诵5次): 当前时间 +  4天
第七次提醒(背诵6次): 当前时间 +  7天
第八次提醒(背诵7次): 当前时间 + 15天
```

背诵过程中首先只显示单词词面, 隐藏发音或解释. 用户需要尽力回忆隐藏部分内容. 之后按`Space`显示作为隐藏部分的发音或解释. 此时用户可以选择:

`yes:` 表示已经记住, 背诵成功次数`+1`, 从当前背诵循环删除, 重新计算提醒时间戳, 更新数据库以待下次背诵.

`no:` 表示没有记住, 在当次取出的单词全部背诵完毕一次后, 再次出现进行背诵, 直到用户选择`yes`为止. 此时重新计算提醒时间戳, 更新数据库, 背诵成功次数`+0`.

`pass:` 表示已经极其熟悉, 直接将背诵次数设置为`8`, 从此不再进入背诵流程.



