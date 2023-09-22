// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./libraries/FormattedStrings.sol";
import "./libraries/TransferHelper.sol";


contract SVG_image is ERC721
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

    struct NFT {
        address owner;
        uint256 blockHeight;
        bytes32 hash;
        bool open;
        uint256 openNumber;
    }



    string  constant  _name = "GreenBTC";
    string  constant  _symbol = "GBTC";

    mapping (uint256 => Green_BTC)  public _data;
    mapping (uint256 => NFT)  public _dataNFT;
    uint256 public _lastOpenNumber;
    //// "GreenBitCoin(uint256 height,string energyStr,uint256 cellCount,string blockTime,address beneficiary,uint8 greenType)";
    event GreenBitCoin(uint256 height,string energyStr,uint256 cellCount,string blockTime,address beneficiary,uint8 greenType);


        //initialize
    // function initialize(address authorizer_)
    //     external
    //     virtual
    //     initializer
    // {
    //     __UUPSUpgradeable_init();
    //     __Ownable_init_unchained();
    //     __ERC721_init_unchained(_name, _symbol);

    //     _DOMAIN_SEPARATOR = keccak256(
    //         abi.encode(
    //             keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
    //             keccak256(bytes(_name)),
    //             keccak256(bytes(_version)),
    //             block.chainid,
    //             address(this)
    //         )
    //     );  

    //     _GREEN_BTC_TYPEHASH = keccak256("GreenBitCoin(uint256 height,string energyStr,uint256 cellCount,string blockTime,address beneficiary,uint8 greenType)");
    //     _authorizer = authorizer_;
    // }

    // function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner
    // {}

    constructor() ERC721(_name, _symbol){
        
    }

    function _sliceHashToString(bytes32 hashData, uint256 _start, uint256 _length) internal  pure returns(string memory){
        bytes memory bytesArray = new bytes(_length);
        
        for (uint256 i = 0; i < _length; i++) {
            bytesArray[i] = hashData[_start + i];
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




    function _svg_open_Data(uint256 tokenId) internal view returns(string memory){

        bytes memory imgBytes;
        bytes32 hashData = _dataNFT[tokenId].hash;

        if(hashData == bytes32(0)){

            imgBytes = abi.encodePacked(

                '<svg fill="#ccc" viewBox="-2 -3.5 24 24" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin" class="jam jam-rectangle-f"> <path d="M3 .565h14a3 3 0 0 1 3 3v10a3 3 0 0 1-3 3H3a3 3 0 0 1-3-3v-10a3 3 0 0 1 3-3z"/> </svg>'

        );

            // imgBytes = abi.encodePacked(
            //     '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" preserveAspectRatio="xMinYMin meet" fill="none"><g><rect width="100%" height="100%" fill="rgba(255, 255, 255, 0.05)" rx="10px" ry="10px"/><rect width="94%" height="94%" fill="transparent" rx="10px" ry="10px" stroke-linejoin="round" x="3%" y="3%" stroke-dasharray="1,6" stroke="white" /></g><path d="M23.9805 38.5391L60.4979 59.6224L23.9805 80.7058L23.9805 38.5391Z" fill="#2403a4"/><path d="M97 38.5391L60.4825 59.6224L97 80.7058L97 38.5391Z" fill="#03a4d8"/><path d="M60.4961 17.4609L97.0136 38.5443H60.497L60.4979 17.4609H60.4961Z" fill="#a4d8e7"/><path d="M60.4961 59.5625L97.0136 80.6459H60.497L60.4979 59.5625H60.4961Z" fill="#d8e700"/><path d="M60.497 38.5391L97.0136 38.5416L60.4961 59.625L60.497 38.5416L60.497 38.5391Z" fill="#e70095"/><path d="M60.497 80.6406L97.0136 80.6432L60.4961 101.727L60.497 80.6432L60.497 80.6406Z" fill="#009532"/><path d="M60.4979 17.4609L60.4979 38.5443H23.9805L60.4979 17.4609Z" fill="#953216"/><path d="M60.4979 59.5625L60.4979 80.6459H23.9805L60.4979 59.5625Z" fill="#3216c0"/><path d="M60.4979 38.549L60.4979 38.5469L60.4979 59.6302L23.9805 38.5469L60.4979 38.549Z" fill="#16c0a0"/><path d="M60.4979 80.6506L60.4979 80.6484L60.4979 101.732L23.9805 80.6484L60.4979 80.6506Z" fill="#c0a0fd"/></svg>'
            // );

        }else{

            imgBytes = abi.encodePacked(

                '<svg fill="#68CA4F" viewBox="-2 -3.5 24 24" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin" class="jam jam-rectangle-f"> <path d="M3 .565h14a3 3 0 0 1 3 3v10a3 3 0 0 1-3 3H3a3 3 0 0 1-3-3v-10a3 3 0 0 1 3-3z"/> </svg>'
            );
            
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


    function mintNFT(Green_BTC calldata gbtc) public {

        require(_data[gbtc.height].cellCount == 0, "only grey block can be mint");
        require(_dataNFT[gbtc.height].owner == address(0), "only owner can open box");

        _mintNFT(gbtc);
    }


    function _mintNFT(Green_BTC calldata gbtc) internal {

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

}
