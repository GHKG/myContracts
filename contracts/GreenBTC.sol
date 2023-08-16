// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./libraries/FormattedStrings.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract GreenBTC is ERC721{

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

    uint256 public _totalCount;

    mapping (uint256 => SVG_PARAM) public _data;

    constructor(string memory name_, string memory symbol_)ERC721(name_, symbol_){
        _totalCount = 0;
    }

    string private constant _STYLE =
        "<style> "
        ".base {fill: #ededed;font-family:Montserrat,arial,sans-serif;font-size:30px;font-weight:400;} "
        ".series {text-transform: uppercase} "
        ".logo {font-size:200px;font-weight:100;} "
        ".meta {font-size:12px;} "
        ".small {font-size:8px;} "
        ".burn {font-weight:500;font-size:16px;} }"
        "</style>";

    string private constant _COLLECTOR =
        "<g>"
        "<path "
        'stroke="#ededed" '
        'fill="none" '
        'transform="translate(265,418)" '
        'd="m 0 0 L -20 -30 L -12.5 -38.5 l 6.5 7 L 0 -38.5 L 6.56 -31.32 L 12.5 -38.5 L 20 -30 L 0 0 L -7.345 -29.955 L 0 -38.5 L 7.67 -30.04 L 0 0 Z M 0 0 L -20.055 -29.955 l 7.555 -8.545 l 24.965 -0.015 L 20 -30 L -20.055 -29.955"/>'
        "</g>";

    string private constant _LIMITED =
        "<g> "
        '<path fill="#ededed" '
        'transform="scale(0.4) translate(600, 940)" '
        'd="M66,38.09q.06.9.18,1.71v.05c1,7.08,4.63,11.39,9.59,13.81,5.18,2.53,11.83,3.09,18.48,2.61,1.49-.11,3-.27,4.39-.47l1.59-.2c4.78-.61,11.47-1.48,13.35-5.06,1.16-2.2,1-5,0-8a38.85,38.85,0,0,0-6.89-11.73A32.24,32.24,0,0,0,95,21.46,21.2,21.2,0,0,0,82.3,20a23.53,23.53,0,0,0-12.75,7,15.66,15.66,0,0,0-2.35,3.46h0a20.83,20.83,0,0,0-1,2.83l-.06.2,0,.12A12,12,0,0,0,66,37.9l0,.19Zm26.9-3.63a5.51,5.51,0,0,1,2.53-4.39,14.19,14.19,0,0,0-5.77-.59h-.16l.06.51a5.57,5.57,0,0,0,2.89,4.22,4.92,4.92,0,0,0,.45.24ZM88.62,28l.94-.09a13.8,13.8,0,0,1,8,1.43,7.88,7.88,0,0,1,3.92,6.19l0,.43a.78.78,0,0,1-.66.84A19.23,19.23,0,0,1,98,37a12.92,12.92,0,0,1-6.31-1.44A7.08,7.08,0,0,1,88,30.23a10.85,10.85,0,0,1-.1-1.44.8.8,0,0,1,.69-.78ZM14.15,10c-.06-5.86,3.44-8.49,8-9.49C26.26-.44,31.24.16,34.73.7A111.14,111.14,0,0,1,56.55,6.4a130.26,130.26,0,0,1,22,10.8,26.25,26.25,0,0,1,3-.78,24.72,24.72,0,0,1,14.83,1.69,36,36,0,0,1,13.09,10.42,42.42,42.42,0,0,1,7.54,12.92c1.25,3.81,1.45,7.6-.23,10.79-2.77,5.25-10.56,6.27-16.12,7l-1.23.16a54.53,54.53,0,0,1-2.81,12.06A108.62,108.62,0,0,1,91.3,84v25.29a9.67,9.67,0,0,1,9.25,10.49c0,.41,0,.81,0,1.18a1.84,1.84,0,0,1-1.84,1.81H86.12a8.8,8.8,0,0,1-5.1-1.56,10.82,10.82,0,0,1-3.35-4,2.13,2.13,0,0,1-.2-.46L73.53,103q-2.73,2.13-5.76,4.16c-1.2.8-2.43,1.59-3.69,2.35l.6.16a8.28,8.28,0,0,1,5.07,4,15.38,15.38,0,0,1,1.71,7.11V121a1.83,1.83,0,0,1-1.83,1.83h-53c-2.58.09-4.47-.52-5.75-1.73A6.49,6.49,0,0,1,9.11,116v-11.2a42.61,42.61,0,0,1-6.34-11A38.79,38.79,0,0,1,1.11,70.29,37,37,0,0,1,13.6,50.54l.1-.09a41.08,41.08,0,0,1,11-6.38c7.39-2.9,17.93-2.77,26-2.68,5.21.06,9.34.11,10.19-.49a4.8,4.8,0,0,0,1-.91,5.11,5.11,0,0,0,.56-.84c0-.26,0-.52-.07-.78a16,16,0,0,1-.06-4.2,98.51,98.51,0,0,0-18.76-3.68c-7.48-.83-15.44-1.19-23.47-1.41l-1.35,0c-2.59,0-4.86,0-7.46-1.67A9,9,0,0,1,8,23.68a9.67,9.67,0,0,1-.91-5A10.91,10.91,0,0,1,8.49,14a8.74,8.74,0,0,1,3.37-3.29A8.2,8.2,0,0,1,14.15,10ZM69.14,22a54.75,54.75,0,0,1,4.94-3.24,124.88,124.88,0,0,0-18.8-9A106.89,106.89,0,0,0,34.17,4.31C31,3.81,26.44,3.25,22.89,4c-2.55.56-4.59,1.92-5,4.79a134.49,134.49,0,0,1,26.3,3.8,115.69,115.69,0,0,1,25,9.4ZM64,28.65c.21-.44.42-.86.66-1.28a15.26,15.26,0,0,1,1.73-2.47,146.24,146.24,0,0,0-14.92-6.2,97.69,97.69,0,0,0-15.34-4A123.57,123.57,0,0,0,21.07,13.2c-3.39-.08-6.3.08-7.47.72a5.21,5.21,0,0,0-2,1.94,7.3,7.3,0,0,0-1,3.12,6.1,6.1,0,0,0,.55,3.11,5.43,5.43,0,0,0,2,2.21c1.73,1.09,3.5,1.1,5.51,1.12h1.43c8.16.23,16.23.59,23.78,1.42a103.41,103.41,0,0,1,19.22,3.76,17.84,17.84,0,0,1,.85-2Zm-.76,15.06-.21.16c-1.82,1.3-6.48,1.24-12.35,1.17C42.91,45,32.79,44.83,26,47.47a37.41,37.41,0,0,0-10,5.81l-.1.08A33.44,33.44,0,0,0,4.66,71.17a35.14,35.14,0,0,0,1.5,21.32A39.47,39.47,0,0,0,12.35,103a1.82,1.82,0,0,1,.42,1.16v12a3.05,3.05,0,0,0,.68,2.37,4.28,4.28,0,0,0,3.16.73H67.68a10,10,0,0,0-1.11-3.69,4.7,4.7,0,0,0-2.87-2.32,15.08,15.08,0,0,0-4.4-.38h-26a1.83,1.83,0,0,1-.15-3.65c5.73-.72,10.35-2.74,13.57-6.25,3.06-3.34,4.91-8.1,5.33-14.45v-.13A18.88,18.88,0,0,0,46.35,75a20.22,20.22,0,0,0-7.41-4.42,23.54,23.54,0,0,0-8.52-1.25c-4.7.19-9.11,1.83-12,4.83a1.83,1.83,0,0,1-2.65-2.52c3.53-3.71,8.86-5.73,14.47-6a27.05,27.05,0,0,1,9.85,1.44,24,24,0,0,1,8.74,5.23,22.48,22.48,0,0,1,6.85,15.82v.08a2.17,2.17,0,0,1,0,.36c-.47,7.25-2.66,12.77-6.3,16.75a21.24,21.24,0,0,1-4.62,3.77H57.35q4.44-2.39,8.39-5c2.68-1.79,5.22-3.69,7.63-5.67a1.82,1.82,0,0,1,2.57.24,1.69,1.69,0,0,1,.35.66L81,115.62a7,7,0,0,0,2.16,2.62,5.06,5.06,0,0,0,3,.9H96.88a6.56,6.56,0,0,0-1.68-4.38,7.19,7.19,0,0,0-4.74-1.83c-.36,0-.69,0-1,0a1.83,1.83,0,0,1-1.83-1.83V83.6a1.75,1.75,0,0,1,.23-.88,105.11,105.11,0,0,0,5.34-12.46,52,52,0,0,0,2.55-10.44l-1.23.1c-7.23.52-14.52-.12-20.34-3A20,20,0,0,1,63.26,43.71Z"/>'
        "</g>";

    string private constant _APEX =
        '<g transform="scale(0.5) translate(533, 790)">'
        '<circle r="39" stroke="#ededed" fill="transparent"/>'
        '<path fill="#ededed" '
        'd="M0,38 a38,38 0 0 1 0,-76 a19,19 0 0 1 0,38 a19,19 0 0 0 0,38 z m -5 -57 a 5,5 0 1,0 10,0 a 5,5 0 1,0 -10,0 z" '
        'fill-rule="evenodd"/>'
        '<path fill="#ededed" '
        'd="m -5, 19 a 5,5 0 1,0 10,0 a 5,5 0 1,0 -10,0"/>'
        "</g>";

    string private constant _LOGO =
        '<path fill="#ededed" '
        'd="M122.7,227.1 l-4.8,0l55.8,-74l0,3.2l-51.8,-69.2l5,0l48.8,65.4l-1.2,0l48.8,-65.4l4.8,0l-51.2,68.4l0,-1.6l55.2,73.2l-5,0l-52.8,-70.2l1.2,0l-52.8,70.2z" '
        'vector-effect="non-scaling-stroke" />';

    string private constant _GRADIENT = 
        '<linearGradient x1="100%" y1="100%" x2="0%" y2="0%" id="g0">'
            '<stop stop-color="hsl(169, 75%, 45%)" stop-opacity="1" offset="10%" />'
            '<stop stop-color="hsl(210, 75%, 45%)" stop-opacity="1" offset="50%" />'
            '<stop stop-color="hsl(305, 75%, 45%)" stop-opacity="1" offset="90%" />'
        '</linearGradient>';


    function mintNFT(string memory series_, uint256 gbtcBurned_, uint256 height_, uint256 energy_,uint256 blockTime_) public {

        uint256 tokenId = ++_totalCount ;

        SVG_PARAM memory svg_param = SVG_PARAM({
            symbol : symbol(),
            gbtcAddress: msg.sender,
            tokenId: tokenId,
            series: series_,
            gbtcBurned:gbtcBurned_,
            height:height_,
            energy:energy_,
            blockTime:blockTime_
        });

        _mint(msg.sender, tokenId);
        _data[tokenId] = svg_param;
    }

    function svgData(SVG_PARAM memory param) internal   pure returns(string memory){

        bytes memory graphics = abi.encodePacked(defs(), _STYLE, g(1), _LOGO, _APEX);
        bytes memory metadata = abi.encodePacked(
            contractData(param.symbol, param.gbtcAddress),
            meta1(param.tokenId, param.series, param.gbtcBurned,param.height,param.energy),
            meta2(param.blockTime)
            // quote(idx),
            // stamp(params.redeemed)
        );
        
        
        bytes memory imgBytes = abi.encodePacked(
                "<svg "
                'xmlns="http://www.w3.org/2000/svg" '
                'preserveAspectRatio="xMinYMin meet" '
                'viewBox="0 0 350 566">',
                graphics,
                metadata,
                "</svg>"
            );

        return string(Base64.encode(imgBytes));

    }

    function _attributes( SVG_PARAM memory param) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                "[",
                '{"trait_type":"Series","value":"',
                param.series,
                '"},',
                '{"trait_type":"Burned","value":"',
                param.gbtcBurned.toString(),
                '"},',
                '{"trait_type":"height","value":"',
                param.height.toString(),
                '"},',
                '{"trait_type":"energy","value":"',
                param.energy.toString(),
                '"},',
                '{"trait_type":"blockTime","value":"',
                param.blockTime.toString(),
                '"}',
                "]"
            );
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){

        require(tokenId <= _totalCount && tokenId != 0, "invalid token id");

        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "Green BTC #',
            tokenId.toString(),
            '",',
            '"description": "GreenBTC: Green Bit Coin",',
            '"image": "',
            "data:image/svg+xml;base64,",
            svgData(_data[tokenId]),
            '",',
            '"attributes": ',
            _attributes(_data[tokenId]),
            "}"
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(dataURI)));
    }


    function defs() internal pure returns (bytes memory) {
        return abi.encodePacked("<defs>", _GRADIENT, "</defs>");
    }

    function border() internal pure returns (string memory) {
        return
            "<rect "
            'width="94%" '
            'height="96%" '
            'fill="transparent" '
            'rx="10px" '
            'ry="10px" '
            'stroke-linejoin="round" '
            'x="3%" '
            'y="2%" '
            'stroke-dasharray="1,6" '
            'stroke="white" '
            "/>";
    }

    function rect(uint256 id) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                "<rect "
                'width="100%" '
                'height="100%" '
                'fill="url(#g',
                id.toString(),
                ')" '
                'rx="10px" '
                'ry="10px" '
                'stroke-linejoin="round" '
                "/>"
            );
    }

    function g(uint256 gradientsCount) internal pure returns (bytes memory) {
        string memory background = "";
        for (uint256 i = 0; i < gradientsCount; i++) {
            background = string.concat(background, string(rect(i)));//???????
            // background = string(string.concat(bytes("aaa")));
        }
        return abi.encodePacked("<g>", background, border(), "</g>");
    }


    function contractData(string memory symbol, address xenAddress) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                "<text "
                'x="50%" '
                'y="5%" '
                'class="base small" '
                'dominant-baseline="middle" '
                'text-anchor="middle">',
                symbol,
                unicode"・",
                xenAddress.toHexString(),
                "</text>"
            );
    }


    function meta1(
        uint256 tokenId,
        string memory series,
        uint256 xenBurned,
        uint256 height,
        uint256 energy
    ) internal pure returns (bytes memory) {
        bytes memory part1 = abi.encodePacked(
            "<text "
            'x="50%" '
            'y="50%" '
            'class="base " '
            'dominant-baseline="middle" '
            'text-anchor="middle">'
            "Green-BTC"//////
            "</text>"
            "<text "
            'x="50%" '
            'y="56%" '
            'class="base burn" '
            'text-anchor="middle" '
            'dominant-baseline="middle"> ',
            // xenBurned > 0 ? string.concat((xenBurned / 10**18).toFormattedString(), " X") : "",
            string.concat("height : ", height.toString()),//////
            "</text>"
            "<text "
            'x="18%" '
            'y="62%" '
            'class="base meta" '
            'dominant-baseline="middle"> '
            "#",
            tokenId.toString(),//////
            "</text>"
            "<text "
            'x="82%" '
            'y="62%" '
            'class="base meta series" '
            'dominant-baseline="middle" '
            'text-anchor="end" >',
            series,//////
            "</text>"
        );
        bytes memory part2 = abi.encodePacked(
            "<text "
            'x="18%" '
            'y="68%" '
            'class="base meta" '
            'dominant-baseline="middle" >'
            "Energy: ",
            energy.toString(),/////
            "</text>"
            "<text "
            'x="18%" '
            'y="72%" '
            'class="base meta" '
            'dominant-baseline="middle" >'
            "ART Burned: ",
            xenBurned.toString(),
            "</text>"
        );
        return abi.encodePacked(part1, part2);
    }

    function meta2(
        // uint256 maturityTs,
        // uint256 amp,
        // uint256 term,
        // uint256 rank,
        // uint256 count
        uint256 blockTime
    ) internal pure returns (bytes memory) {
        bytes memory part3 = abi.encodePacked(
            "<text "
            'x="18%" '
            'y="76%" '
            'class="base meta" '
            'dominant-baseline="middle" >'
            "BlockTime: ",
            blockTime.toString(),
            "</text>"
            // "<text "
            // 'x="18%" '
            // 'y="80%" '
            // 'class="base meta" '
            // 'dominant-baseline="middle" >'
            // "Term: ",
            // term.toString()
        );
        // bytes memory part4 = abi.encodePacked(
        //     " days"
        //     "</text>"
        //     "<text "
        //     'x="18%" '
        //     'y="84%" '
        //     'class="base meta" '
        //     'dominant-baseline="middle" >'
        //     "cRank: ",
        //     rankAndCount(rank, count),
        //     "</text>"
        //     "<text "
        //     'x="18%" '
        //     'y="88%" '
        //     'class="base meta" '
        //     'dominant-baseline="middle" >'
        //     "Maturity: ",
        //     maturityTs.asString(),
        //     "</text>"
        // );
        return abi.encodePacked(part3);
    }


 
}