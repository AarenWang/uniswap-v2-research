pragma solidity =0.5.16;

import './interfaces/IUniswapV2Pair.sol';
import './UniswapV2ERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IERC20.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Callee.sol';

contract UniswapV2Pair is IUniswapV2Pair, UniswapV2ERC20 {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;  //解决
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    //kLast保存上次流动性变更之后的 uint(reserve0).mul(reserve1)
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

/**
*  Pari有四个事件类型 Mint Burt Swap Sync

 */
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
            
    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    //工厂合约在创建配对合约时调用
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    // 更新储备 on the first call per block,价格累加器 
    /**
     * 更新储备和余额，储备和余额是什么关系
     * 储备和余额数值相等，但是位数不一样，储备只有112位,余额256位(unit和int其实是uint256,int是int256)
     */
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    // 如果平台协议费用打开费用开关打开
    /**
     * 如果费用开关打开， 
     */
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings    kLast =  reserve0 * reserve1
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));   // totalSupply * (sqrt(new k) - sqrt(old_k))
                    uint denominator = rootK.mul(5).add(rootKLast);  // new_k * 5 + old_k
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity); //给平台费地址铸造LP Token
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    // 
    /**
     *  几个问题 
     *    1. 储备reserves和余额balance是什么关系？ (储备更新频率低，balance更新频率高，比如铸造流动性时，交易对token0和token1的balance已经更新，reserves还未更新) 
     *    2. mint出来是啥  ｜  铸造流动性,uniswap 内部的ERC20代币，表示份额
     *    3. mint数量如何计算     
     *       3.1 公式1 liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
     *       3.2 公式2 liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
     *    4.
     */
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);  //计算本次添加流动性，token 0数量
        uint amount1 = balance1.sub(_reserve1);  //计算本次添加流动性，token 1数量

        bool feeOn = _mintFee(_reserve0, _reserve1);
        //totalSupply 是该交易对的LP token数量
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee  
        //交易对是否有流动性token时，计算本次新铸造流动性token 方法不一样
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity); //调用ERC20的 mint方法

        // balance和reserver再次平衡
        _update(balance0, balance1, _reserve0, _reserve1); 
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    /**
     * 销毁流动性Token,这个方法被Router合约调用之前，Router合约已经将LP token从LP地址转到交易对合约上(因此参数没有销毁的LP token数量)
     *  返回流动性提供者的剩余Token1和Token2的数量
     *  1）查找当前交易对合约token0和token1存量，查找当前交易对地址的LO Token数量 
     *  2）根据token0和token1贮备量，铸造手续费 
     *  3）将作为流动性提供的token1和token2，转到LP提供者地址
     *  4）更新token1,和token2的余额和储备数量
     *  5）生成Burn事件
     */
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this)); //交易对持有的token A数量
        uint balance1 = IERC20(_token1).balanceOf(address(this)); //交易对持有的token B数量
        uint liquidity = balanceOf[address(this)];  //这个LP token是Routern合约已经调用转账方法，转到交易对合约

        bool feeOn = _mintFee(_reserve0, _reserve1);  // 根据token0和token1贮备量，铸造手续费 
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);   //调用ERC20 的销毁方法
        _safeTransfer(_token0, to, amount0);  //撤出流动性，将token1转回到LP提供者
        _safeTransfer(_token1, to, amount1);  //撤出流动性，将token2转回到LP提供者
        balance0 = IERC20(_token0).balanceOf(address(this)); //转走之后，从新获取token1余额
        balance1 = IERC20(_token1).balanceOf(address(this)); //转走之后，从新获取token2余额

        _update(balance0, balance1, _reserve0, _reserve1);  //更新token1,和token2的余额和储备数量
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    /**
     * 这个方法供路由合约调用的交换方法调用，路由合约交换方法的path是一个数组，该数值长度大于等于2，如果是长度是2，则一个交易对token1和token2直接互换
     * 如果path长度大于2，这间接互换比如path=[token1_address,token2_address,token3_adderess],则通过token1换token2，再用token2换token3，实现token1换token3的目标
     *  这个方法是供直接交易对token1换token2,也支持间token1换token2，再用token2换token3，token1换token2时，to地址是{token2和3交易对合约地址}
     */
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
            // amount0Out  amoun10Out 总有一个值为0
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens  
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data); //这个是干啥
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
            uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
            require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}
