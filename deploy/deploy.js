const dotenv = require("dotenv")
dotenv.config()

const Web3 = require('web3')
const WETH9 = require('./uniswap-contracts/build/WETH9.json')
const UniswapV2Pair = require('./uniswap-contracts/build/UniswapV2Pair.json')
const UniswapV2Factory = require('./uniswap-contracts/build/UniswapV2Factory.json')
const UniswapV2Router01 = require('./uniswap-contracts/build/UniswapV2Router01.json')
const UniswapV2Router02 = require('./uniswap-contracts/build/UniswapV2Router02.json')


const INFURA_ENDPOINT=process.env.INFURA_ENDPOINT
const endpoint = `https://ropsten.infura.io/v3/${INFURA_ENDPOINT}`;
const MY_PRIVATE_KEY =  process.env.MY_PRIVATE_KEY


async function sendTransaction(web3, chainId, account, data, nonce, gasPrice) {
    const message = {
        from: account.address,
        gas: 5000000,
        gasPrice: gasPrice,
        data: data.startsWith('0x') ? data : '0x' + data,
        nonce: nonce,
        chainId: chainId
    }
    const transaction = await account.signTransaction(message)
    return web3.eth.sendSignedTransaction(transaction.rawTransaction)
}

(async () => {
    const options = { timeout: 1000 * 30 }
    const web3 = new Web3(new Web3.providers.HttpProvider(endpoint, options))
    const account = web3.eth.accounts.privateKeyToAccount(MY_PRIVATE_KEY)

    const chainId = await web3.eth.getChainId()
    const gasPrice = await web3.eth.getGasPrice()
    let nonce = await web3.eth.getTransactionCount(account.address)

    // deploy WETH contract
    let weth = null
    {
        const contract = new web3.eth.Contract(WETH9.abi)
        const data = contract.deploy({ data: WETH9.bytecode }).encodeABI()
        const receipt = await sendTransaction(web3, chainId, account, data, nonce, gasPrice)
        console.info('WETH:', weth = receipt.contractAddress)
        nonce = nonce + 1
    }

    // deploy UniswapV2Factory contract
    let factory = null
    {
        const contract = new web3.eth.Contract(UniswapV2Factory.abi)
        const options = { data: UniswapV2Factory.bytecode, arguments: [account.address] }
        const data = contract.deploy(options).encodeABI()
        const receipt = await sendTransaction(web3, chainId, account, data, nonce, gasPrice)
        console.info('UniswapV2Factory:', factory = receipt.contractAddress)
        nonce = nonce + 1
    }

    // deploy UniswapV2Router01 contract
    {
        const contract = new web3.eth.Contract(UniswapV2Router01.abi)
        const options = { data: UniswapV2Router01.bytecode, arguments: [factory, weth] }
        const data = contract.deploy(options).encodeABI()
        const receipt = await sendTransaction(web3, chainId, account, data, nonce, gasPrice)
        console.info('UniswapV2Router01:', receipt.contractAddress)
        nonce = nonce + 1
    }

    // deploy UniswapV2Router02 contract
    {
        const contract = new web3.eth.Contract(UniswapV2Router02.abi)
        const options = { data: UniswapV2Router02.bytecode, arguments: [factory, weth] }
        const data = contract.deploy(options).encodeABI()
        const receipt = await sendTransaction(web3, chainId, account, data, nonce, gasPrice)
        console.info('UniswapV2Router02:', receipt.contractAddress)
        nonce = nonce + 1
    }

    let data = UniswapV2Pair.bytecode
    if (!data.startsWith('0x')) data = '0x' + data
    console.info('INIT_CODE_HASH:', web3.utils.keccak256(data))
})()