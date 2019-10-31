## 开发者类型

纯链开发者：优化链代码。

- 链代码开源之前，即为Asimov链开发团队。

纯链应用开发者：基于链数据做开发。

- 运行链节点或者接入TestNet
- 主要基于Restful API进行开发 （**AScan等应用**）
- PY SDK：PY SDK封装了Restful API，为链应用开发提供了更加便捷的测试脚本开发途径。

纯合约开发者：在Asimov上开发智能合约。

- 运行链节点或者接入TestNet
- 开发和测试合约代码，官方提供如下工具
 - Web IDE：可以在上面创建模板、部署实例、测试合约Testcase；Web IDE同时提供了一些Helper的功能如TestNet的水龙头、助记词生成等。
 - Cmd Tool：可以通过命令行实现和Web IDE一样的功能。
 - JS SDK：JS SDK封装了Restful API。Web IDE和Cmd底层基于SDK实现。JS SDK为合约开发提供了更加便捷的测试和部署脚本开发途径。

轻度DApp开发者：开发简单的DApp，仅需非常少量或者没有中心化服务器的支持。

- 运行链节点或者接入TestNet
- 基于完成的合约进行开发
- JS SDK，基于JS SDK开发简单的web应用
- 开发案例 **摇骰子游戏**

重度DApp开发者：开发复杂的DApp，需要正常的中心化服务器支持。

- 运行链节点或者接入TestNet
- 基于完成的合约进行开发
- JS SDK，基于JS SDK开发前端功能。
- Mobile SDK，Mobile SDK封装了Restful API，基于Moble SDK开发移动端功能。
- Restful API，基于Restful API开发服务端功能，也可以基于Restful API开发前端和移动端功能。
- 开发案例 **银行和稳定币功能**

## 官方工具

- 链节点的二进制运行程序，支持solo模式运行或者接入testnet运行。
- Asilink Chrome插件钱包。
- Restful API：链节点提供，最底层的API。
- JS SDK：封装Restful API，主要面向合约开发者。
- Web IDE：开发测试和部署合约的可视化网页工具。基于JS SDK开发。
- Cmd：开发测试和部署合约的命令行工具。基于JS SDK开发。
- 基础合约：封装了Asimov资产指令，使用Asimov资产指令的标准方式。
- PY SDK：封装Restful API，主要面向链应用开发者。
- AScan：基于Restful API开发的链应用，用于查询区块和交易的详细信息。
- Mobile SDK：封装Restful API，主要面向移动开发者。