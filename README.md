
> uniswap v3版本代码研究仓库 [uniswap-v3-research](https://github.com/AarenWang/uniswap-v3-research)
# 部署uniswap到测试网

## 部署前准备
### 准备代码

### 准备测试币
测试币
```
git clone git@github.com:maticnetwork/testnet-token-contracts.git
修改truffle-config.js 在文件开始第一行增加一行  
require('dotenv').config();
cd testnet-token-contracts
编辑 .env
npm install --save truffle-hdwallet-provider

# 部署
truffle deploy --network ropsten
```

部署输出 先保留
```
 
```

部署的token地址 
https://ropsten.etherscan.io/token/0xB61c2ED9CE06FDDf98A0d0fDeb3d9A1bba66E998#balances


## 部署过程
### 部署合约
编译uniswap-v2-core

```
cd v2-code
yarn 
yarn compile
cp -r build  ../deploy/uniswap-contracts
```

编译uniswap-v2-periphery
```
cd v2-periphery
yarn 
yarn compile
cp -r build  ../deploy/uniswap-contracts
```


```
npm install dotenv --save
yarn add dotenv
```



```
npm init -f && npm install web3
```

```
node deploy.js
```


输出信息
```
WETH: 0x4101888d4e172e4aF72CEe576E41Ff833dC58f5A
UniswapV2Factory: 0x611c314F1E82ad39FC86489B5d3CE205b254251C
UniswapV2Router01: 0x0a7B893852B179A378EC9319e7698B9d0e40A72C
UniswapV2Router02: 0xe5974799A1b38587FaB858904A41f9E54a961eBB
INIT_CODE_HASH: 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f
```



### 部署前端

下载依赖，编译
``` 
yarn
```


替换地址
- 修改 uniswap-interface/src/constants/index.ts 文件中 ROUTER_ADDRESS 的值为 ${UniswapV2Router02}。
- 修改 uniswap-interface/src/state/swap/hooks.ts文件中 BAD_RECIPIENT_ADDRESSES 数组的值为 [${UniswapV2Factory}, ${UniswapV2Router01}, ${UniswapV2Router02}]。
- 修改 uniswap-interface/node_modules/@uniswap/sdk/dist/sdk.cjs.development.js 和 uniswap-interface/node_modules/@uniswap/sdk/dist/sdk.esm.js 文件中 FACTORY_ADDRESS 为 ${UniswapV2Factory}。
- 修改 uniswap-interface/node_modules/@uniswap/sdk/dist/sdk.cjs.development.js 和 uniswap-interface/node_modules/@uniswap/sdk/dist/sdk.esm.js 文件中 INIT_CODE_HASH 为 ${INIT_CODE_HASH}。
- 修改 uniswap-interface/node_modules/@uniswap/sdk/dist/sdk.cjs.development.js 和 uniswap-interface/node_modules/@uniswap/sdk/dist/sdk.esm.js 文件中全局变量 WETH，将其中 key 为 GÖRLI 的 Token 类型的地址修改为 ${WETH}。


手动修改起来非常麻烦，容易出错，写了个脚本在 deploy/replace_var.py替换操作
替换之前先动手改下python脚本，第一行到第五行

启动运行

```
yarn start
```

### 将前端部署到Netlify
Netlify提供了一个开发平台，其中包括用于Web应用程序和动态网站的构建，部署和无服务器后端服务
具体部署过程略去
