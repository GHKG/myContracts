// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./libraries/FormattedStrings.sol";
import "./libraries/TransferHelper.sol";
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';


contract GreenBTC_5 is 
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

    struct SVG_PARAM {
        string symbol;
        address gbtcAddress;
        uint256 tokenId;
        string series;
        uint256 gbtcBurned;
        uint256 height;
        uint256 energy;
        uint256 blockTime;
    }
    //// "GreenBitCoin(uint256 height,string energyStr,uint256 cellCount,string blockTime,address beneficiary,uint8 greenType)";

    struct Green_BTC{
        uint256 height;
        uint256 cellCount;
        address beneficiary;
        uint8   greenType;
        string  blockTime;
        string  energyStr;
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

    struct NFT {
        address owner;
        uint256 blockHeight;
        bytes32 hash;
        bool open;
        uint256 openNumber;
    }


    string  constant  _name = "GreenBTC";
    string  constant  _symbol = "GBTC";
    string  constant  _version = "1";
    address constant _arkreenBuilder = 0xA05A9677a9216401CF6800d28005b227F7A3cFae;
    address constant _tokenNative = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    address constant _tokenART = 0x0999AFb673944a7B8E1Ef8eb0a7c6FFDc0b43E31;


    bytes32 public  _DOMAIN_SEPARATOR;
    bytes32 public  _GREEN_BTC_TYPEHASH;
    mapping (uint256 => Green_BTC)  public _data;
    address public _authorizer;

    mapping (uint256 => NFT)  public _dataNFT;
    uint256 public _lastOpenNumber;
    
    //// "GreenBitCoin(uint256 height,string energyStr,uint256 cellCount,string blockTime,address beneficiary,uint8 greenType)";
    event GreenBitCoin(uint256 height,string energyStr,uint256 cellCount,string blockTime,address beneficiary,uint8 greenType);

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'GBTC: EXPIRED');
        _;
    }

        //initialize
    function initialize(address authorizer_)
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

        _GREEN_BTC_TYPEHASH = keccak256("GreenBitCoin(uint256 height,string energyStr,uint256 cellCount,string blockTime,address beneficiary,uint8 greenType)");
        _authorizer = authorizer_;
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner
    {}


    function _svg_open_Data(uint256 tokenId) internal view returns(string memory){

        bytes memory imgBytes;
        bytes32 hashData = _dataNFT[tokenId].hash;

        if(hashData == bytes32(0)){

            imgBytes = abi.encodePacked(
                '<svg fill="#ccc" viewBox="-2 -3.5 24 24" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin" class="jam jam-rectangle-f"> <path d="M3 .565h14a3 3 0 0 1 3 3v10a3 3 0 0 1-3 3H3a3 3 0 0 1-3-3v-10a3 3 0 0 1 3-3z"/> </svg>'
            );

        }else{
            // imgBytes = abi.encodePacked(
            //     '<svg fill="#68CA4F" viewBox="-2 -3.5 24 24" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin" class="jam jam-rectangle-f"> <path d="M3 .565h14a3 3 0 0 1 3 3v10a3 3 0 0 1-3 3H3a3 3 0 0 1-3-3v-10a3 3 0 0 1 3-3z"/> </svg>'
            // );
            imgBytes = _getLuckySVGBytes(hashData);
        }
        
        return string(Base64.encode(imgBytes));
    }

    function _svg_unopen_Data(uint256 tokenId ) internal  pure  returns(string memory){

        bytes memory imgBytes = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 192 192" preserveAspectRatio="xMinYMin meet" fill="none">'
            '<style>.f{font-family:Montserrat,arial,sans-serif;dominant-baseline:middle;text-anchor:middle}</style>'
            '<path d="M96.864 172.667L33.356 136v56.833L96.863 246v-73.333zM160.4 135.997l-63.51 36.667v73.333l63.51-76.54v-33.46z"/>'
            '<path d="M96.86 99.33L33.352 62.665v73.333l63.508 36.667V99.33z" fill="#E8C684"/>'
            '<path d="M160.395 62.67L96.887 99.335v73.333l63.508-36.667V62.67z" fill="#D7A94F"/>'
            '<path d="M160.395 62.667L96.887 26 33.378 62.667l63.509 36.666 63.508-36.666z" fill="#EEDEA6"/>'
            '<text class="f" x="118" y="7" transform="rotate(30.5) skewX(-30)" fill="#98601e" font-size="16" font-weight="400">',
            tokenId.toString(),
            "</text>"
            '<text class="f" x="68" y="82" transform="skewY(26.83) scale(.92718 1.07853)" fill="rgba(255,255,255,.5)" font-size="42">?</text>'
            "</svg>"
        );

        return string(Base64.encode(imgBytes));

    }


    function _mintNFT(Green_BTC calldata gbtc) internal {

        require(_data[gbtc.height].cellCount == 0, "only grey block can be mint");
        // require(_dataNFT[gbtc.height].owner == address(0), "only owner can open box");

        Green_BTC memory green_btc = Green_BTC({
            height:gbtc.height,
            energyStr:gbtc.energyStr,
            cellCount:gbtc.cellCount,
            blockTime:gbtc.blockTime,
            beneficiary:gbtc.beneficiary,
            greenType:gbtc.greenType
        });

        _data[gbtc.height] = green_btc;

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

        bytes32 greenBTCHash = keccak256(abi.encode(_GREEN_BTC_TYPEHASH, gbtc.height, gbtc.energyStr, gbtc.cellCount, gbtc.blockTime, gbtc.beneficiary, gbtc.greenType));
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', _DOMAIN_SEPARATOR, greenBTCHash));
        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);

        require(recoveredAddress == _authorizer, "invalid singature");
    }


    function _exchangeForTokenNative(uint256 amount) internal {

        bytes4 selector = bytes4(keccak256("deposit()"));
        bytes memory callData = abi.encodeWithSelector(selector);

        (bool success, bytes memory returndata) = _tokenNative.call{value: amount}(callData);

         if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("GBTC: Error Call to deposit");
            }
        }    
    }

    function _actionBuilderBadge(bytes memory callData) internal {
        (bool success, bytes memory returndata) = _arkreenBuilder.call(callData);

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



    function authMintGreenBTCWithNative(Green_BTC calldata gbtc, Sig_PARAM calldata sig, BadgeInfo calldata badgeInfo, uint256 deadline) public  payable ensure(deadline) {

        // require(msg.value >= 5*10**16, " at least 5*10**16 weis for 1 ART");
        // require(gbtc.beneficiary == msg.sender, "only beneficiary can mint NFT");
        require(_data[gbtc.height].cellCount == 0, "only grey block can be mint");

        //verify signature
        _authVerify(gbtc, sig);
        //exchange fro warp matic from tokenNative contract
        _exchangeForTokenNative(msg.value);
        
        {
            uint128 price = _getPrice(_tokenART, _tokenNative);

            uint256 amountART = msg.value * (10**9) / price;
            // uint256 amountART = msg.value * (10**9) / (_getPrice(_tokenART, _tokenNative));

            uint256 modeAction = 0x03; //   bit0 = 1; 用户付钱为定额，能换取多少ART由Bank合约的兑换价格决定，实验中需要2个ART，根据兑换价格，需要0.1个matic
                                        //  bit1 = 1; 表示需要去Bank合约去兑换ART
            bytes memory callData = abi.encodeWithSelector(0x8D7FCEFD, _tokenNative, _tokenART, msg.value,
                                                            amountART, modeAction, deadline, badgeInfo);
            _actionBuilderBadge(abi.encodePacked(callData, msg.sender));     // Pay back to msg.sender already

            // _mintNFT(gbtc.height, gbtc.energyStr, gbtc.cellCount, gbtc.blockTime,  gbtc.beneficiary, gbtc.greenType);
            _mintNFT(gbtc);
        }

        emit GreenBitCoin(gbtc.height, gbtc.energyStr, gbtc.cellCount, gbtc.blockTime,  gbtc.beneficiary, gbtc.greenType);
    }

    function authMintGreenBTCWithApprove(Green_BTC calldata gbtc, Sig_PARAM calldata sig, BadgeInfo calldata badgeInfo, TokenPay_PARAM calldata tokenPay, uint256 deadline) public ensure(deadline){
        // require(msg.value >= 5*10**16, " at least 5*10**16 weis for 1 ART");
        // require(gbtc.beneficiary == msg.sender, "only beneficiary can mint NFT");
        require(_data[gbtc.height].cellCount == 0, "only grey block can be mint");

        //verify signature
        _authVerify(gbtc, sig);

        //避免"CompilerError: Stack too deep."
        {
                TransferHelper.safeTransferFrom(tokenPay.token, msg.sender, address(this), tokenPay.amount);


                uint128 price = _getPrice(_tokenART, tokenPay.token);

                uint256 amountART = tokenPay.amount * (10**9) / price;
                // uint256 amountART = tokenPay.amount * (10**9) /  (_getPrice(_tokenART, tokenPay.token));

                uint256 modeAction = 0x03; //   bit0 = 1; 用户付钱为定额，能换取多少ART由Bank合约的兑换价格决定
                                            //  bit1 = 1; 表示需要去Bank合约去兑换ART
                bytes memory callData = abi.encodeWithSelector(0x8D7FCEFD, tokenPay.token, _tokenART, tokenPay.amount,
                                                                amountART, modeAction, deadline, badgeInfo);
                _actionBuilderBadge(abi.encodePacked(callData, msg.sender));     // Pay back to msg.sender already

                // _mintNFT(gbtc.height, gbtc.energyStr, gbtc.cellCount, gbtc.blockTime,  gbtc.beneficiary, gbtc.greenType);
                _mintNFT(gbtc);
        }

        emit GreenBitCoin(gbtc.height, gbtc.energyStr, gbtc.cellCount, gbtc.blockTime,  gbtc.beneficiary, gbtc.greenType);
    }

    function _getPrice(address tokenART, address tokenPay) internal returns(uint128) {

        address banker;

        bytes4 selector = bytes4(keccak256("artBank()"));
        bytes memory callData = abi.encodeWithSelector(selector);

        (bool success, bytes memory returndata) = _arkreenBuilder.call(callData);
        require(success, "get artBank address failed");
        banker = abi.decode(returndata, (address));
        

        // address tokenART = 0x0999AFb673944a7B8E1Ef8eb0a7c6FFDc0b43E31;
        // address tokenPay = 0x0FA8781a83E46826621b3BC094Ea2A0212e71B23;
        // address tokenPay = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;

        selector = bytes4(keccak256("saleIncome(address,address)"));
        callData = abi.encodeWithSelector(selector, tokenART, tokenPay);

        (success, returndata) = banker.call(callData);
        require(success, "get price failed");
        (uint128 price, ) = abi.decode(returndata, (uint128, uint128));

        return price;
        
    }

    function setAuthorizer(address authAddress) public onlyOwner {
        require(authAddress != address(0), "address 0 is not allowed"); 
        _authorizer = authAddress;
    }

    function approveBuilder(address[] calldata tokens) external onlyOwner {
        require(_arkreenBuilder != address(0), "HSKESG: No Builder");
        for(uint256 i = 0; i < tokens.length; i++) {
            TransferHelper.safeApprove(tokens[i], _arkreenBuilder, type(uint256).max);
        }
    }   

    function openBox(uint256 tokenID) public {

        require(msg.sender == ownerOf(tokenID), "only owner can open box");
        require(_dataNFT[tokenID].open == false, "the box has already been opened");
        
        bytes32 random_bytes = keccak256(
            abi.encodePacked(tokenID, msg.sender,  block.number, block.timestamp, blockhash(block.number - 1), _lastOpenNumber)
        );

        uint256 luckyNum = uint256(random_bytes) % 100;
        _lastOpenNumber = luckyNum;

        if(luckyNum < 20){
            _dataNFT[tokenID].hash = random_bytes;
            _dataNFT[tokenID].open = true;
            _dataNFT[tokenID].openNumber = luckyNum;
        }else{
            _dataNFT[tokenID].open = true;
            _dataNFT[tokenID].openNumber = luckyNum;
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){

        // require(tokenId <= _totalCount && tokenId != 0, "invalid token id");
        require(_data[tokenId].height != 0, "no such token minted");

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

        if(_data[tokenID].cellCount == 0){
            return (false, false);
        }else{
            return (true, _dataNFT[tokenID].open);
        }
    }

    function _getLuckySVGBytes(bytes32 _hashData) internal  pure  returns(bytes memory){

        bytes memory imgBytes;

        imgBytes = abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" preserveAspectRatio="xMinYMin meet" fill="none">'
                '<g>'
                    '<rect width="100%" height="100%" fill="rgba(255, 255, 255, 0.05)" rx="10px" ry="10px"/>'
                    '<rect width="94%" height="94%" fill="transparent" rx="10px" ry="10px" stroke-linejoin="round" x="3%" y="3%" stroke-dasharray="1,6" stroke="white" />'
                '</g>'
                '<path d="M23.9805 38.5391L60.4979 59.6224L23.9805 80.7058L23.9805 38.5391Z" fill="#',
                _sliceHashToString(_hashData, 0, 3),
                '"/>'
                '<path d="M97 38.5391L60.4825 59.6224L97 80.7058L97 38.5391Z" fill="#',
                _sliceHashToString(_hashData, 1, 3),
                '"/>'
                '<path d="M60.4961 17.4609L97.0136 38.5443H60.497L60.4979 17.4609H60.4961Z" fill="#',
                _sliceHashToString(_hashData, 2, 3),
                '"/>'
                '<path d="M60.4961 59.5625L97.0136 80.6459H60.497L60.4979 59.5625H60.4961Z" fill="#',
                _sliceHashToString(_hashData, 3, 3)

        );

        imgBytes = abi.encodePacked(
            imgBytes,
            '"/>'
            '<path d="M60.497 38.5391L97.0136 38.5416L60.4961 59.625L60.497 38.5416L60.497 38.5391Z" fill="#',
                _sliceHashToString(_hashData, 4, 3),
            '"/>'
            '<path d="M60.497 80.6406L97.0136 80.6432L60.4961 101.727L60.497 80.6432L60.497 80.6406Z" fill="#',
            _sliceHashToString(_hashData, 5, 3),
            '"/>'
            '<path d="M60.4979 17.4609L60.4979 38.5443H23.9805L60.4979 17.4609Z" fill="#',
            _sliceHashToString(_hashData, 6, 3),
            '"/>'
            '<path d="M60.4979 59.5625L60.4979 80.6459H23.9805L60.4979 59.5625Z" fill="#',
            _sliceHashToString(_hashData, 7, 3)

        );

        imgBytes = abi.encodePacked(
            imgBytes,
            '"/>'
            '<path d="M60.4979 38.549L60.4979 38.5469L60.4979 59.6302L23.9805 38.5469L60.4979 38.549Z" fill="#',
            _sliceHashToString(_hashData, 8, 3),
            '"/>'
            '<path d="M60.4979 80.6506L60.4979 80.6484L60.4979 101.732L23.9805 80.6484L60.4979 80.6506Z" fill="#',
            _sliceHashToString(_hashData, 9, 3),
            '"/>'
            '</svg>'
        );

        return imgBytes;
        // return string(Base64.encode(imgBytes));
        // return string(imgBytes);
    }

    function _sliceHashToString(bytes32 _hash, uint256 _start, uint256 _length) internal  pure returns(string memory){
        bytes memory bytesArray = new bytes(_length);
        
        for (uint256 i = 0; i < _length; i++) {
            bytesArray[i] = _hash[_start + i];
        }
        
        return _bytesToHexString(bytesArray);
    }

    function _bytesToHexString(bytes memory _bytes) private pure returns (string memory) {
        bytes memory hexBytes = new bytes(_bytes.length * 2);
        
        for (uint256 i = 0; i < _bytes.length; i++) {
            uint256 pos = i * 2;
            uint256 val = uint256(uint8(_bytes[i]));
            
            hexBytes[pos] = _toHexChar(val / 16);
            hexBytes[pos + 1] = _toHexChar(val % 16);
        }
        
        return string(hexBytes);
    }
    
    function _toHexChar(uint256 _val) private pure returns (bytes1) {
        if (_val < 10) {
            return bytes1(uint8(_val + 48));
        } else {
            return bytes1(uint8(_val + 87));
        }
    }

}
