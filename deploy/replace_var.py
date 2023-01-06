V2_FACTORY_ADDRESS="0x611c314F1E82ad39FC86489B5d3CE205b254251C"
V2_ROUTER_01_ADDRESS="0x0a7B893852B179A378EC9319e7698B9d0e40A72C"
V2_ROUTER_02_ADDRESS="0xe5974799A1b38587FaB858904A41f9E54a961eBB"
INIT_CODE_HASH="0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
WETH_ADDRESS="0x4101888d4e172e4aF72CEe576E41Ff833dC58f5A"

OLD_V2_FACTORY_ADDRESS="0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f"
OLD_V2_ROUTER_01_ADDRESS="0xf164fC0Ec4E93095b804a4795bBe1e041497b92a"
OLD_V2_ROUTER_02_ADDRESS="0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D" 
OLD_INIT_CODE_HASH="0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
OLD_WETH_ADDRESS="0xc778417E063141139Fce010982780140Aa0cD5Ab"


def repleace_str_at_file(path,old_str,new_str):
    f = open(path,"rt");
    data = f.read()
    data = data.replace(old_str, new_str)
    f.close()
    f = open(path, "wt")
    f.write(data)
    f.close();


if __name__ == "__main__":
    repleace_str_at_file("../uniswap-interface/src/constants/index.ts",OLD_V2_ROUTER_02_ADDRESS,V2_ROUTER_02_ADDRESS);
    repleace_str_at_file("../uniswap-interface/src/state/swap/hooks.ts",OLD_V2_FACTORY_ADDRESS,V2_ROUTER_02_ADDRESS);
    repleace_str_at_file("../uniswap-interface/src/state/swap/hooks.ts",OLD_V2_ROUTER_01_ADDRESS,V2_ROUTER_01_ADDRESS);
    repleace_str_at_file("../uniswap-interface/src/state/swap/hooks.ts",OLD_V2_ROUTER_02_ADDRESS,V2_ROUTER_02_ADDRESS);

    repleace_str_at_file("../uniswap-interface/node_modules/@uniswap/sdk/dist/sdk.cjs.development.js",OLD_V2_FACTORY_ADDRESS,V2_FACTORY_ADDRESS);
    repleace_str_at_file("../uniswap-interface/node_modules/@uniswap/sdk/dist/sdk.esm.js",OLD_V2_FACTORY_ADDRESS,V2_FACTORY_ADDRESS);

    repleace_str_at_file("../uniswap-interface/node_modules/@uniswap/sdk/dist/sdk.cjs.development.js",OLD_INIT_CODE_HASH,INIT_CODE_HASH);
    repleace_str_at_file("../uniswap-interface/node_modules/@uniswap/sdk/dist/sdk.esm.js",OLD_INIT_CODE_HASH,INIT_CODE_HASH);

    # the OLD_WETH_ADDRESS is ropsten WETH address, so only repalce ropsten network 
    repleace_str_at_file("../uniswap-interface/node_modules/@uniswap/sdk/dist/sdk.cjs.development.js",OLD_WETH_ADDRESS,WETH_ADDRESS);
    repleace_str_at_file("../uniswap-interface/node_modules/@uniswap/sdk/dist/sdk.esm.js",OLD_WETH_ADDRESS,WETH_ADDRESS);
