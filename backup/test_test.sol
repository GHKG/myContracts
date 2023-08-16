    
    bytes32 constant _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(_NAME)),
                keccak256(bytes(_VERSION)),
                block.chainid,
                address(this)
            )
    );  

    bytes32 constant _TRANSFER_OWNERSHIP_TYPEHASH = keccak256(
        "TransferOwnership(address NFT_Addr, uint256 tokenId, address owner, address proxy, address ERC20_Addr,uint256 price)"
    );
    
    function transferOwnership(
        address proxy_addr,
        uint256 tokenId,
        address owner,
        address erc20_addr,
        uint256 price,
        address reciever,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {

        require(proxy_addr == msg.sender(), "only proxy contract can withdraw token");

        bytes32 typeHash = keccak256(abi.encode(_TRANSFER_OWNERSHIP_TYPEHASH, address(this), tokenId, owner, proxy_addr, erc20_addr, price));
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', _DOMAIN_SEPARATOR, typeHash));
        address recoveredAddress = ecrecover(digest, v, r, s);

        require(recoveredAddress == owner, "signer doesn't not match or singature error");

        safeTransferFrom(owner,reciever,tokenId);     
    }

struct Signature{
    uint8       v;
    bytes32     r;
    bytes32     s;     
}

struct Data {
    uint256     value;
    Signature   sig;
}

 mapping(address => (address => (uint256 =>(address => Data)))) public upShelfData;

bytes32 constant _TRANSFER_OWNERSHIP_TYPEHASH = keccak256(
    "TransferOwnership(address NFT_Addr, uint256 tokenId, address owner, address intermediary, address ERC20_Addr,uint256 price)"
);

    function onShelf(
        address nft_addr,
        uint256 tokenId,
        address owner,
        address erc20_addr,
        uint256 price,

        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {

        require(owner == msg.sender(), "only owner can sell token");
        require(price > 0, "price can not be 0");

        Siginature sig;
        sig.v = v;
        sig.r = r;
        sig.s = s;

        Data memory preserveData;
        preserveData.value = price;
        preserveData.sig = sig;


        upShelfData[nft_addr][owner][tokenId][erc20_addr] = preserveData;
        
    }

    function offShelf(
        address nft_addr,
        uint256 tokenId,
        address erc20_addr,
    ) external {

        require(upShelfData[nft_addr][msg.sender()][tokenId][erc20_addr] != 0, "no record match the token & only the owner can pull");

        delete upShelfData[nft_addr][msg.sender()][tokenId][erc20_addr];
        
    }

    function buy(
        address nft_addr,
        address owner,
        uint256 tokenId,
        address erc20_addr,
        uint256 price,

        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        
        Data memory preserveData;
        preserveData = upShelfData[nft_addr][owner][tokenId][erc20_addr];
        require(preserveData != 0, "no record match the token");

        uint8 _v = preserveData.sig.v;
        bytes32 _r = preserveData.sig.r;
        bytes32 _s = preserveData.sig.s;

        require(price >= preserveData.value, "payment not enough");

        address sender = _msgSender();
        IERC20Permit(erc20_addr).permit(sender, address(this), price, deadline,v,r,s);

        bytes4 method = bytes4(keccak256("transferOwnership(address,uint256,address,address,uint256,address,uint8,bytes32,bytes32)"));
        (bool success, bytes memory data) = address(nft_addr).call(method, address(this), tokenId, owner, erc20_addr, preserveData.value, msg.sender(), _v, _r, _s);
        
        require(success, "failed to transfer ownership");

    }