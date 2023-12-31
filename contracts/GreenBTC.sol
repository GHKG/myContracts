// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';


import "./libraries/FormattedStrings.sol";
import "./libraries/TransferHelper.sol";

import './interfaces/IGreenBTCImage.sol';


contract GreenBTC is 
    ContextUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ERC721Upgradeable
{

    // using DateTime for uint256;
    // using Strings for string;
    using Strings for uint256;
    using Strings for address;
    using FormattedStrings for uint256;


    struct Green_BTC{
        uint256 height;
        uint256 ARTCount;
        address beneficiary;
        uint8   greenType;
        string  blockTime;
        string  energyStr;
    }

    struct NFT {
        address owner;
        uint256 blockHeight;
        bytes32 hash;
        bool open;
        uint256 openNumber;
    }

    struct Sig_PARAM {
        uint8       v;
        bytes32     r;
        bytes32     s;              
    }

    struct TokenPay_PARAM{
        address token;
        uint256 amount;
    }


    struct BadgeInfo {
        address     beneficiary;
        string      offsetEntityID;
        string      beneficiaryID;
        string      offsetMessage;
    }


    //keccak256("GreenBitCoin(uint256 height,string energyStr,uint256 artCount,string blockTime,address beneficiary,uint8 greenType)");
    bytes32 constant _GREEN_BTC_TYPEHASH = 0x2cc287d531f97592968321a2680791d868f5cafdc02c8f9f059c431e7ef0f086;
    string  constant  _name = "GreenBTC";
    string  constant  _symbol = "GBTC";
    string  constant  _version = "1";

    // address constant _arkreenBuilder = 0xA05A9677a9216401CF6800d28005b227F7A3cFae;
    // address constant _tokenNative = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    // address constant _tokenART = 0x0999AFb673944a7B8E1Ef8eb0a7c6FFDc0b43E31;


    bytes32 public  _DOMAIN_SEPARATOR;

    mapping (uint256 => Green_BTC)  public _dataGBTC;
    mapping (uint256 => NFT)  public _dataNFT;

    address public _manager;
    address public _authorizer;

    address public _greenBtcImageContract;
    address public _arkreenBuilderContract;
    address public _exchangeARTContract;//用于其他代币（usdc、usdt等）进行绿化时，兑换ART的地址


    event GreenBitCoin(uint256 height,string energyStr,uint256 ARTCount,string blockTime,address beneficiary,uint8 greenType);
    event OpneBox(uint256  height, address  owner, uint256 blockNumber, uint256 blockTime, bytes32 lastBlockHash, uint256 openNumber);

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'GBTC: EXPIRED');
        _;
    }

    modifier onlyManager(){
        require(msg.sender == _manager, 'GBTC: only manager allowed');
        _;
    }

    //initialize
    function initialize(address authorizer_, address arkreenBuilder_, address exchangeART_)
        external
        virtual
        initializer
    {
        __UUPSUpgradeable_init();
        __Ownable_init_unchained();
        __ERC721_init_unchained(_name, _symbol);

        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(_name)),
                keccak256(bytes(_version)),
                block.chainid,
                address(this)
            )
        );  


        // _manager = msg.sender;
        _manager = owner();
        _authorizer = authorizer_;
        _arkreenBuilderContract = arkreenBuilder_;
        _exchangeARTContract = exchangeART_;
       
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner
    {}

    function setManager(address newManager) public onlyOwner{
        require(newManager != address(0), "GBTC: address 0 is not allowed"); 
        _manager = newManager;
    }

    function setAuthorizer(address newAuthAddress) public onlyManager {
        require(newAuthAddress != address(0), "GBTC: address 0 is not allowed"); 
        _authorizer = newAuthAddress;
    }

    function setImageContractAddress(address newImageContractAddress) public onlyManager {
        require(newImageContractAddress != address(0), 'GBTC: address 0 is not allowed');
        _greenBtcImageContract = newImageContractAddress;
    }

    function setExchangeARTContractAddress(address newExchangeARTContract) public onlyManager {
        require(newExchangeARTContract != address(0), 'GBTC: address 0 is not allowed');
        _greenBtcImageContract = newExchangeARTContract;
    }

    function approveBuilder(address[] calldata tokens) public onlyManager {
        require(_arkreenBuilderContract != address(0), "GBTC: No Builder");
        for(uint256 i = 0; i < tokens.length; i++) {
            TransferHelper.safeApprove(tokens[i], _arkreenBuilderContract, type(uint256).max);
        }
    }   





    // function authMintGreenBTCWithNative(Green_BTC calldata gbtc, Sig_PARAM calldata sig, BadgeInfo calldata badgeInfo, uint256 deadline) public  payable ensure(deadline) {

    //     require(_dataGBTC[gbtc.height].ARTCount == 0, "GBTC: only grey block can be mint");

    //     //verify signature
    //     _authVerify(gbtc, sig);

    //     //exchange for warp matic from tokenNative contract
    //     _exchangeForTokenNative(msg.value);
        
    //     //避免"CompilerError: Stack too deep."
    //     {
    //         uint128 price = _getPrice(_tokenART, _tokenNative);

    //         uint256 amountART = msg.value * (10**9) / price;
    //         // uint256 amountART = msg.value * (10**9) / (_getPrice(_tokenART, _tokenNative));

    //         uint256 modeAction = 0x03; //   bit0 = 1; 用户付钱为定额，能换取多少ART由Bank合约的兑换价格决定，实验中需要2个ART，根据兑换价格，需要0.1个matic
    //                                     //  bit1 = 1; 表示需要去Bank合约去兑换ART
    //         bytes memory callData = abi.encodeWithSelector(0x8D7FCEFD, _tokenNative, _tokenART, msg.value,
    //                                                         amountART, modeAction, deadline, badgeInfo);
    //         _actionBuilderBadge(abi.encodePacked(callData, gbtc.beneficiary));     // Pay back to msg.sender already

    //         _mintNFT(gbtc);
    //     }

    //     emit GreenBitCoin(gbtc.height, gbtc.energyStr, gbtc.cellCount, gbtc.blockTime,  gbtc.beneficiary, gbtc.greenType);
    // }

    function authMintGreenBTCWithApprove(Green_BTC calldata gbtc, Sig_PARAM calldata sig, BadgeInfo calldata badgeInfo, TokenPay_PARAM calldata tokenPay, uint256 deadline) public ensure(deadline){

        require(_dataGBTC[gbtc.height].ARTCount == 0, "GBTC: only grey block can be mint");

        //verify signature
        _authVerify(gbtc, sig);

        //避免"CompilerError: Stack too deep."
        {
                TransferHelper.safeTransferFrom(tokenPay.token, msg.sender, address(this), tokenPay.amount);


                uint128 price = _getPrice(_exchangeARTContract, tokenPay.token);

                uint256 amountART = tokenPay.amount * (10**9) / price;
                // uint256 amountART = tokenPay.amount * (10**9) /  (_getPrice(_tokenART, tokenPay.token));

                uint256 modeAction = 0x03; //   bit0 = 1; 用户付钱为定额，能换取多少ART由Bank合约的兑换价格决定
                                            //  bit1 = 1; 表示需要去Bank合约去兑换ART
                bytes memory callData = abi.encodeWithSelector(0x8D7FCEFD, tokenPay.token, _exchangeARTContract, tokenPay.amount,
                                                                amountART, modeAction, deadline, badgeInfo);
                _actionBuilderBadge(abi.encodePacked(callData, gbtc.beneficiary));     // Pay back to msg.sender already


                _mintNFT(gbtc);
        }

        emit GreenBitCoin(gbtc.height, gbtc.energyStr, gbtc.ARTCount, gbtc.blockTime,  gbtc.beneficiary, gbtc.greenType);
    }


    function authMintGreenBTCWithART(
        Green_BTC calldata gbtc, 
        Sig_PARAM calldata sig, 
        BadgeInfo calldata badgeInfo,
        address tokenART, 
        uint256 amountART, 
        uint256 deadline)  public  ensure(deadline) 
    {
        require(_dataGBTC[gbtc.height].ARTCount == 0, "GBTC: only grey block can be mint");
        require(gbtc.ARTCount <= amountART, "GBTC: not enough ART"); 
        //verify signature
        _authVerify(gbtc, sig);

        // Transfer payement 
        TransferHelper.safeTransferFrom(tokenART, msg.sender, address(this), amountART);

        // actionBuilderBadgeWithART(address,uint256,uint256,(address,string,string,string)): 0x6E556DF8
        bytes memory callData = abi.encodeWithSelector(0x6E556DF8, tokenART, amountART, deadline, badgeInfo);

        _actionBuilderBadge(abi.encodePacked(callData, gbtc.beneficiary));

        _mintNFT(gbtc);

        emit GreenBitCoin(gbtc.height, gbtc.energyStr, gbtc.ARTCount, gbtc.blockTime,  gbtc.beneficiary, gbtc.greenType);
    }

    function openBox(uint256 tokenID) public {

        require(msg.sender == ownerOf(tokenID), "GBTC: only box owner can open box");
        require(_dataNFT[tokenID].open == false, "GBTC: the box has already been opened");
        
        bytes32 random_bytes = keccak256(
            abi.encodePacked(tokenID, msg.sender,  block.number, block.timestamp, blockhash(block.number - 1))
        );

        uint256 luckyNum = uint256(random_bytes) % 100;

        if(luckyNum < 20){
            _dataNFT[tokenID].hash = random_bytes;
            _dataNFT[tokenID].open = true;
            _dataNFT[tokenID].openNumber = luckyNum;
        }else{
            _dataNFT[tokenID].open = true;
            _dataNFT[tokenID].openNumber = luckyNum;
        }


        emit OpneBox(tokenID, msg.sender,block.number, block.timestamp, blockhash(block.number - 1), luckyNum);

    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){

        // require(tokenId <= _totalCount && tokenId != 0, "invalid token id");
        require(_dataGBTC[tokenId].height != 0, "GBTC: no such token minted");

        string memory svgData;
        if(_dataNFT[tokenId].open == false){
            svgData = _svg_unopen_Data(tokenId);
        }else{
            svgData = _svg_open_Data(tokenId);
        }
        

        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "Green BTC #',
            tokenId.toString(),
            '",',
            '"description": "GreenBTC: Green Bit Coin",',
            '"image": "',
            "data:image/svg+xml;base64,",
            svgData,
            '"'
            "}"
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(dataURI)));
    }


    function isUnPacking(uint256 tokenID) public view returns(bool, bool) {

        if(_dataGBTC[tokenID].ARTCount == 0){
            return (false, false);
        }else{
            return (true, _dataNFT[tokenID].open);
        }
    }

    function _svg_open_Data(uint256 tokenId) internal view  returns(string memory openData){

        bytes32 hashData = _dataNFT[tokenId].hash;

        if(hashData == bytes32(0)){

            //此处使用staticcall模式进行调用，原因：_imageContract合约的getCertificateSVGBytes函数使用struct Green_BTC
            //作为参数，如果不使用staticcall，则必须在本合约、接口合约、目标合约之间协调struct Green_BTC的定义。本合约不希望
            //将struct Green_BTC的定义独立出去(至少目前不希望)，所以此处使用staticcall进行处理，虽然稍显繁琐，但保留本合约的
            //独立性，以及灵活性。
            bytes4 selector = bytes4(keccak256("getCertificateSVGBytes((uint256,uint256,address,uint8,string,string))"));
            bytes memory callData = abi.encodeWithSelector(selector, _dataGBTC[tokenId]);

            (bool success, bytes memory returndata) = _greenBtcImageContract.staticcall(callData);
            require(success, "GBTC: call image contract failed");
            openData = abi.decode(returndata, (string));


        }else{

            // bytes4 selector = bytes4(keccak256("getGreenTreeSVGBytes()"));
            // bytes memory callData = abi.encodeWithSelector(selector);

            // (bool success, bytes memory returndata) = _imageContract.staticcall(callData);
            // require(success, "call image contract failed");
            // openData = abi.decode(returndata, (string));

            openData = IGreenBTCImage(_greenBtcImageContract).getGreenTreeSVGBytes();
        }
        

    }

    function _svg_unopen_Data(uint256 tokenId ) internal view returns(string memory){

        // bytes4 selector = bytes4(keccak256("getBlindBoxSVGBytes(uint256)"));
        // bytes memory callData = abi.encodeWithSelector(selector, tokenId);

        // (bool success, bytes memory returndata) = _imageContract.staticcall(callData);
        // require(success, "call image contract failed");
        // return abi.decode(returndata, (string));

        return IGreenBTCImage(_greenBtcImageContract).getBlindBoxSVGBytes(tokenId);

    }


    function _mintNFT(Green_BTC calldata gbtc) internal {

        require(_dataGBTC[gbtc.height].ARTCount == 0, "GBTC: only grey block can be mint");
        // require(_dataNFT[gbtc.height].owner == address(0), "only owner can open box");

        Green_BTC memory green_btc = Green_BTC({
            height:gbtc.height,
            energyStr:gbtc.energyStr,
            ARTCount:gbtc.ARTCount,
            blockTime:gbtc.blockTime,
            beneficiary:gbtc.beneficiary,
            greenType:gbtc.greenType
        });

        _dataGBTC[gbtc.height] = green_btc;


        NFT memory nft = NFT({
            owner:gbtc.beneficiary,
            blockHeight: gbtc.height,
            hash:bytes32(0),
            open:false,
            openNumber:0
        });
        _dataNFT[gbtc.height] = nft;

        _mint(gbtc.beneficiary, gbtc.height);
    }



    function _authVerify(Green_BTC calldata gbtc, Sig_PARAM calldata sig) internal view {

        bytes32 greenBTCHash = keccak256(abi.encode(_GREEN_BTC_TYPEHASH, gbtc.height, gbtc.energyStr, gbtc.ARTCount, gbtc.blockTime, gbtc.beneficiary, gbtc.greenType));
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', _DOMAIN_SEPARATOR, greenBTCHash));
        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);

        require(recoveredAddress == _authorizer, "GBTC: invalid singature");
    }


    // function _exchangeForTokenNative(uint256 amount) internal {

    //     bytes4 selector = bytes4(keccak256("deposit()"));
    //     bytes memory callData = abi.encodeWithSelector(selector);

    //     (bool success, bytes memory returndata) = _tokenNative.call{value: amount}(callData);

    //      if (!success) {
    //         if (returndata.length > 0) {
    //             // solhint-disable-next-line no-inline-assembly
    //             assembly {
    //                 let returndata_size := mload(returndata)
    //                 revert(add(32, returndata), returndata_size)
    //             }
    //         } else {
    //             revert("GBTC: Error Call to deposit");
    //         }
    //     }    
    // }

    function _actionBuilderBadge(bytes memory callData) internal {
        (bool success, bytes memory returndata) = _arkreenBuilderContract.call(callData);

         if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("GBTC: Error Call to actionBuilderBadge");
            }
        }        
    }

    function _getPrice(address tokenART, address tokenPay) internal view returns(uint128) {

        address banker;

        bytes4 selector = bytes4(keccak256("artBank()"));
        bytes memory callData = abi.encodeWithSelector(selector);

        (bool success, bytes memory returndata) = _arkreenBuilderContract.staticcall(callData);
        require(success, "GBTC: get artBank address failed");
        banker = abi.decode(returndata, (address));
        

        // address tokenART = 0x0999AFb673944a7B8E1Ef8eb0a7c6FFDc0b43E31;
        // address tokenPay = 0x0FA8781a83E46826621b3BC094Ea2A0212e71B23;
        // address tokenPay = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;

        selector = bytes4(keccak256("saleIncome(address,address)"));
        callData = abi.encodeWithSelector(selector, tokenART, tokenPay);

        (success, returndata) = banker.staticcall(callData);
        require(success, "GBTC: get price failed");
        (uint128 price, ) = abi.decode(returndata, (uint128, uint128));

        return price;
        
    }





}
