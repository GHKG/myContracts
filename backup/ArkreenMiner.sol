// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol';
//import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';

import '@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol';
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "./interfaces/IERC20.sol";
// import "./interfaces/IERC20Permit.sol";
import "./types/ArkreenMinerTypesV10.sol";

contract ArkreenMiner is
    OwnableUpgradeable,
    UUPSUpgradeable,
    ERC721EnumerableUpgradeable
{
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    // Public variables
    string public constant NAME = 'Arkreen Miner';
    string public constant SYMBOL = 'AKREM';
    string public constant VERSION = '1';

    address public tokenAKRE;                       // Token adddress of AKRE
    uint256 public totalGameMiner;                  // Total amount of game miner
    uint256 public capGameMinerAirdrop;             // Total amount of game miner that can airdropped
    uint256 public counterGameMinerAirdrop;         // counter of game miner that can airdropped
    uint256 public indexGameMinerWithdraw;          // start index withdrawing the pending game miner

    // Enumerable All airdropped game tokens still in Pending status
    EnumerableSetUpgradeable.UintSet private allPendingGameMiners;

    // All registered miner manufactures
    mapping(address => bool) public AllManufactures;

    // Timestamp indicating Arkreen normal launch state 
    uint256 public timestampFormalLaunch;
    
    // All miner infos
    mapping(uint256 => Miner) public AllMinerInfo;

    // All managers with various privilege
    mapping(uint256 => address) public AllManagers;
     
    bytes32 public DOMAIN_SEPARATOR;

    // Mapping from miner address to the respective token ID
    mapping(address => uint256) public AllMinersToken;

    string public baseURI;

    // Miner white list mapping from miner address to miner type
    mapping(address => uint8) public whiteListMiner;

    // Constants
    // keccak256("GameMinerOnboard(address owner,address miners,bool bAirDrop,uint256 deadline)");
    bytes32 public constant GAME_MINER_TYPEHASH = 0xB0C08E369CF9D149F7E973AF789B8C94B7DA6DCC0A8B1F5F10F1820FB6224C11;  
    uint256 public constant DURATION_ACTIVATE = 3600 * 24 * 30;    // Game miner needs to be activated with 1 month
    uint256 public constant INIT_CAP_AIRDROP = 10000;              // Cap of Game miner airdrop

    // keccak256("RemoteMinerOnboard(address owner,address miners,address token,uint256 price,uint256 deadline)");
    bytes32 public constant REMOTE_MINER_TYPEHASH = 0xE397EAA556C649D10F65393AC1D09D5AA50D72547C850822C207516865E89E32;      

    // keccak256('StandardMinerOnboard(address owner,address miner,bool bAirDrop,uint256 deadline)')
    bytes32 public constant STANDARD_MINER_TYPEHASH = 0x73F94559854A7E6267266A158D1576CBCAFFD8AE930E61FB632F9EC576D2BB37;

    // Events
    event GameMinerAirdropped(uint256 timestamp, uint256 amount);
    event GameMinerOnboarded(address indexed owner, address[] miners);
    event MinerOnboarded(address indexed owner, address indexed miner);
    event VitualMinersInBatch(address[] owners, address[] miners);

    modifier ensure(uint256 deadline) {
        require(block.timestamp <= deadline, 'Arkreen Miner: EXPIRED');
        _;
    }

    modifier isGamingPhase() {
        require(block.timestamp < timestampFormalLaunch, 'Arkreen Miner: Gaming Phase Ended');
        _;
    }

    modifier onlyMinerManager() {
        require(_msgSender() == AllManagers[uint256(MinerManagerType.Miner_Manager)], 'Arkreen Miner: Not Miner Manager');
        _;
    }    

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _tokenAKRE, address _minerManager, address _minerAuthority)
        external
        virtual
        initializer
    {
        __Ownable_init_unchained();
        __UUPSUpgradeable_init();
        __ERC721_init_unchained(NAME, SYMBOL);
        tokenAKRE = _tokenAKRE;
        AllManagers[uint256(MinerManagerType.Miner_Manager)] = _minerManager;
        AllManagers[uint256(MinerManagerType.Register_Authority)] = _minerAuthority;
        timestampFormalLaunch = type(uint64).max;    // To flag in gaming phase
        capGameMinerAirdrop = INIT_CAP_AIRDROP;
        baseURI = 'https://www.arkreen.com/miners/';

     

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                // keccak256(bytes("Arkreen Miner")),
                keccak256(bytes(NAME)),
                keccak256(bytes(VERSION)),
                block.chainid,
                address(this)
            )
        );  
    }

    function postUpdate() 
      external onlyProxy onlyOwner reinitializer(2) {
        __ERC721_init_unchained(NAME, SYMBOL);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
        onlyOwner
    {}


    /**
     * @dev Mint game miners to the user who has just ordered some mining virtual/DTU Miners. 
     * @param receiver address receiving the game miner tokens
     * @param miners address of the game miners    
     */
    function OrderMiners(
        address receiver,
        address[] memory miners,
        Signature calldata permitToPay
    ) external onlyMinerManager {

        // Permit payment
        IERC20Permit(permitToPay.token).permit(receiver, address(this), 
                                        permitToPay.value, permitToPay.deadline, permitToPay.v, permitToPay.r, permitToPay.s);

        // Game miner only can be minted before the time of formal lauch date
        if (block.timestamp < (timestampFormalLaunch)) {
            require(miners.length != 0, 'Arkreen Miner: Null Game Miner');

            // Default miner info
            Miner memory tmpMiner;
            tmpMiner.mType = MinerType.GameMiner;
            tmpMiner.mStatus = MinerStatus.Normal;
            tmpMiner.timestamp = uint32(block.timestamp);

            //slither-disable-next-line uninitialized-local
            for(uint256 index; index < miners.length; index++) {
                // Mint game miner one by one
                tmpMiner.mAddress = miners[index];
                require(AllMinersToken[tmpMiner.mAddress] == 0, "Arkreen Miner: Miner Repeated");
                uint256 gMinerID = totalSupply() + 1 ;               
                _safeMint(receiver, gMinerID);
                AllMinersToken[tmpMiner.mAddress] = gMinerID;
                AllMinerInfo[gMinerID] = tmpMiner;

                // increase the counter of total game miner 
                totalGameMiner += 1;        
            }

            // emit the game minting event
            emit GameMinerOnboarded(receiver,  miners);
        } else {
            require(miners.length == 0, 'Arkreen Miner: Game Miner Not Allowed');
        }
        
        // Transfer onboarding fee
        TransferHelper.safeTransferFrom(permitToPay.token, receiver, address(this), permitToPay.value);
    }

    /**
     * @dev Airdrop game miners to the users
     * @param receivers address receiving the game miner tokens
     * @param miners address of the airdropped game miners. If miners is null,
     * withdraw the pending game miners and send to the new receivers
     */
    function AirdropMiners(
        address[] memory receivers,
        address[] memory miners
    ) external isGamingPhase onlyOwner {

        if(miners.length == 0) {
            // Re-airdrop pending game miners to new receivers 
            require(counterGameMinerAirdrop >= capGameMinerAirdrop, 'Game Miner: Airdrop Not Full'); 
            require(receivers.length <= allPendingGameMiners.length(), 'Game Miner: Two Much Airdrop Receiver'); 

            // Start from last ended position
            uint256 withdrawFrom = indexGameMinerWithdraw;

            // Counter to protect against endless loop
            uint256 counterHandled = 0;

            uint256 tokenIDWithdraw;
            for(uint256 index = 0; index < receivers.length; index++) {
                while(true) {
                    // Wrap to head if overflowed due to game miner onboarded
                    if(withdrawFrom >= allPendingGameMiners.length()) {
                        withdrawFrom = 0;
                    }  

                    // Check if the claim deadline is passed
                    tokenIDWithdraw = allPendingGameMiners.at(withdrawFrom);
                    if( block.timestamp >= AllMinerInfo[tokenIDWithdraw].timestamp) {
                        break;
                    }

                    // skip to next game miner
                    withdrawFrom += 1;
                    counterHandled += 1;
                    require(counterHandled < allPendingGameMiners.length(), 'Game Miner: Two Much Airdrop');                     
                }

                // Check the receiver to avoid repeating airdrop
                address owner = receivers[index];
                require( !owner.isContract(), 'Game Miner: Only EOA Address Allowed' );
                require( balanceOf(owner) == 0, 'Game Miner: Airdrop Repeated' );

                // Withdraw the pending game miner, and transfer to the new receiver
                address ownerOld = ownerOf(tokenIDWithdraw);

                _transfer(ownerOld, owner, tokenIDWithdraw);

                // Update the new deadline to the claimed game miner
                AllMinerInfo[tokenIDWithdraw].timestamp = uint32(block.timestamp + DURATION_ACTIVATE);

                // pointer to next pending game miner
                withdrawFrom += 1;
            }

            // Save the new index for the next time airdrop
            indexGameMinerWithdraw = withdrawFrom;

        } else {
            // Fresh airdrop
            require(receivers.length == miners.length, 'Game Miner: Wrong Input'); 
            require((counterGameMinerAirdrop + receivers.length) <= capGameMinerAirdrop, 'Game Miner: Airdrop Overflowed'); 

            // Default airdropped game miner info
            Miner memory miner;
            miner.mType = MinerType.GameMiner;
            miner.mStatus = MinerStatus.Pending;
            miner.timestamp = uint32(block.timestamp + DURATION_ACTIVATE);
            
            for(uint256 index; index < receivers.length; index++) {
                // Check the receiver to avoid repeating airdrop
                address owner = receivers[index];
                require( !owner.isContract(), 'Game Miner: Only EOA Address Allowed' );
                require( balanceOf(owner) == 0, 'Game Miner: Airdrop Repeated' );

                uint256 gMinerID = totalSupply() + 1;        
                _safeMint(owner, gMinerID);
                miner.mAddress = miners[index];
                AllMinersToken[miner.mAddress] = gMinerID;
                AllMinerInfo[gMinerID] = miner;

                // increase the counter of total game miner 
                totalGameMiner += 1;

                // Add to the pending airdrop set
                allPendingGameMiners.add(gMinerID);
                counterGameMinerAirdrop += 1;
            }
        }

        emit GameMinerAirdropped(block.timestamp, receivers.length);
    }

    /**
     * @dev Onboarding game miner, an airdropped one, or a new applied one.
     * @param owner address receiving the game miner
     * @param miner address of the game miner onboarding
     * @param bAirDrop flag if the game miner is airdropped before,
     * bAirDrop =1, onboard the airdropped game miner, =0, onboard a new game miner
     * @param permitGameMiner signature of onboarding manager to approve the onboarding
     */
    function GameMinerOnboard(
        address owner,
        address miner,
        bool    bAirDrop,
        uint256 deadline,
        Sig     calldata permitGameMiner
    ) external ensure(deadline) isGamingPhase {
        // Miner onboarding must be EOA address 
        require(!miner.isContract(), 'Game Miner: Not EOA Address');

        // Check signature
        bytes32 hashRegister = keccak256(abi.encode(GAME_MINER_TYPEHASH, owner, miner, bAirDrop, deadline));
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, hashRegister));
        address recoveredAddress = ecrecover(digest, permitGameMiner.v, permitGameMiner.r, permitGameMiner.s);

        require(recoveredAddress != address(0) && 
                recoveredAddress == AllManagers[uint256(MinerManagerType.Register_Authority)], 'Game Miner: INVALID_SIGNATURE');

        Miner memory tmpMiner;
        tmpMiner.mAddress = miner;
        tmpMiner.mType = MinerType.GameMiner;
        tmpMiner.mStatus = MinerStatus.Normal;
        tmpMiner.timestamp = uint32(block.timestamp);

        if(bAirDrop) {
            // Boarding an airdropped game miner
            uint256 pendingMinerID = getPendingMiner(owner);            // Can only have one pending game miner       
            require(pendingMinerID != type(uint256).max, "Game Miner: No Miner To Board"); 
            require(miner == AllMinerInfo[pendingMinerID].mAddress, "Game Miner: Wrong Miner Address"); 
            AllMinerInfo[pendingMinerID] = tmpMiner;
            allPendingGameMiners.remove(pendingMinerID);

        } else {
            // Boading a new applied game miner
            require(bAllowedToMintGameMiner(owner), 'Game Miner: Holding Game Miner');
            require(AllMinersToken[miner] == 0, "Game Miner: Miner Repeated");
            uint256 gMinerID = totalSupply() + 1;
            _safeMint(owner, gMinerID);
            AllMinersToken[tmpMiner.mAddress] = gMinerID;
            AllMinerInfo[gMinerID] = tmpMiner;

            // Increase the counter of total game miner 
            totalGameMiner += 1;       
        }

        // emit onboarding event
        address[] memory tempMiner = new address[](1);
        tempMiner[0] = miner;
        emit GameMinerOnboarded(owner,  tempMiner);
    }

    /**
     * @dev Onboarding a virtual Miner
     * @param owner address receiving the virtual miner
     * @param miner address of the virtual miner onboarding
     * @param permitMiner signature of miner register authority to confirm the miner address and price.  
     * @param permitToPay signature of payer to pay the onboarding fee
     */
    function RemoteMinerOnboard(
        address     owner,
        address     miner,
        Sig       calldata  permitMiner,
        Signature calldata  permitToPay
    ) external ensure(permitToPay.deadline) {

        // Check miner is white listed  
        require( (whiteListMiner[miner] == uint8(MinerType.RemoteMiner) ), 'Arkreen Miner: Wrong Miner');
        require(AllMinersToken[miner] == 0, "Arkreen Miner: Miner Repeated");

        // Check signature
        // keccak256("RemoteMinerOnboard(address owner,address miners,address token,uint256 price,uint256 deadline)");
        bytes32 hashRegister = keccak256(abi.encode(REMOTE_MINER_TYPEHASH, owner, miner, 
                                          permitToPay.token, permitToPay.value, permitToPay.deadline));
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, hashRegister));
        address recoveredAddress = ecrecover(digest, permitMiner.v, permitMiner.r, permitMiner.s);
  
        require(recoveredAddress != address(0) && 
                recoveredAddress == AllManagers[uint256(MinerManagerType.Register_Authority)], 'Arkreen Miner: INVALID_SIGNATURE');

        // Permit payment
        address sender = _msgSender();
        IERC20Permit(permitToPay.token).permit(sender, address(this), 
                                        permitToPay.value, permitToPay.deadline, permitToPay.v, permitToPay.r, permitToPay.s);

        // Prepare to mint new virtual/DTU miner
        Miner memory newMiner;
        newMiner.mAddress = miner;
        newMiner.mType = MinerType.RemoteMiner;
        newMiner.mStatus = MinerStatus.Normal;
        newMiner.timestamp = uint32(block.timestamp);    

        // mint new virtual/DTU miner
        uint256 realMinerID = totalSupply() + 1;
        _safeMint(owner, realMinerID);
        AllMinersToken[newMiner.mAddress] = realMinerID;
        AllMinerInfo[realMinerID] = newMiner;

        delete whiteListMiner[miner];

        // Transfer onboarding fee
        TransferHelper.safeTransferFrom(permitToPay.token, sender, address(this), permitToPay.value);

        emit MinerOnboarded(owner, miner);
    }


    
    function StandardMinerOnboard(
        address owner,
        address miner,
        bool    bAirDrop,
        uint256 deadline,
        Sig     calldata permitStandardMiner
    )external ensure(deadline) {

        require(!miner.isContract(), 'Standard Miner: Not EOA Address');

        // Check signature
        bytes32 hashRegister = keccak256(abi.encode(STANDARD_MINER_TYPEHASH, owner, miner, bAirDrop, deadline));
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, hashRegister));
        address recoveredAddress = ecrecover(digest, permitStandardMiner.v, permitStandardMiner.r, permitStandardMiner.s);

        require(recoveredAddress != address(0) && 
                recoveredAddress == AllManagers[uint256(MinerManagerType.Register_Authority)], 'Standard Miner: INVALID_SIGNATURE');
        
        Miner memory tmpMiner;
        tmpMiner.mAddress = miner;
        tmpMiner.mType = MinerType.StandardMiner;
        tmpMiner.mStatus = MinerStatus.Normal;
        tmpMiner.timestamp = uint32(block.timestamp);

        if(bAirDrop) {
            // // Boarding an airdropped game miner
            // uint256 pendingMinerID = getPendingMiner(owner);            // Can only have one pending game miner       
            // require(pendingMinerID != type(uint256).max, "Game Miner: No Miner To Board"); 
            // require(miner == AllMinerInfo[pendingMinerID].mAddress, "Game Miner: Wrong Miner Address"); 
            // AllMinerInfo[pendingMinerID] = tmpMiner;
            // allPendingGameMiners.remove(pendingMinerID);

        } else {
            // Boading a new applied standard miner
            // require(bAllowedToMintGameMiner(owner), 'Game Miner: Holding Game Miner');
            require(AllMinersToken[miner] == 0, "Standard Miner: Miner Repeated");
            require(whiteListMiner[miner] == uint8(MinerType.StandardMiner), "Standard Miner: Is not a standard miner in white list");
            uint256 gMinerID = totalSupply() + 1;
            _safeMint(owner, gMinerID);
            AllMinersToken[tmpMiner.mAddress] = gMinerID;
            AllMinerInfo[gMinerID] = tmpMiner;

            // Increase the counter of total game miner 
            // totalGameMiner += 1;       

            //clear data in white list 
            delete whiteListMiner[miner];
            // whiteListMiner[miner] = 0; 
            emit MinerOnboarded(owner, miner);
        }

    }

    /**
     * @dev Onboarding virtual miners in batch
     * @param owners addresses receiving the virtual miners
     * @param miners addresses of the virtual miners onboarding
     */
    function VirtualMinerOnboardInBatch(
        address[]  calldata   owners,
        address[]  calldata   miners
    ) external isGamingPhase onlyMinerManager {

        require(owners.length == miners.length, 'Arkreen Miner: Wrong Address List');

        // Prepare to mint new virtual miners, only virtual miners
        Miner memory newMiner;
        newMiner.mType = MinerType.RemoteMiner;
        newMiner.mStatus = MinerStatus.Normal;
        newMiner.timestamp = uint32(block.timestamp);

        for(uint256 index; index < owners.length; index++) {
            // Mint new virtual miners one by one
            uint256 virtualMinerID = totalSupply() + 1;
            newMiner.mAddress = miners[index];
            _safeMint(owners[index], virtualMinerID);
            AllMinersToken[newMiner.mAddress] = virtualMinerID;            
            AllMinerInfo[virtualMinerID] = newMiner;
        }
        // Need to emit? If yes, data may be big 
        emit VitualMinersInBatch(owners, miners);
    }

    /**
     * @dev Hook that is called before any token transfer. Miner Info is checked as the following rules:  
     * A) Game miner cannot be transferred
     * B) Only miner in Normal state can be transferred
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override (ERC721EnumerableUpgradeable) {
        // Game miner cannot be transferred, not including mint and burn
        // But contract owner can withdraw and re-airdrop game miner 
        if(_msgSender() != owner()) {
          if (from != address(0) && to != address(0)){
              Miner memory miner = AllMinerInfo[tokenId];
              require(miner.mType != MinerType.GameMiner, 'Arkreen Miner: Game Miner Transfer Not Allowed');
              require(miner.mStatus == MinerStatus.Pending, 'Arkreen Miner: Miner Status Not Transferrable');
          }
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @dev Get the Pending game miner ID of the specified owner
     * @param owner owner address
     */
    function getPendingMiner(address owner) internal view returns (uint256 tokenID) {
        uint256 totalMiners = balanceOf(owner);
        for(uint256 index; index < totalMiners; index++) {     
            uint256 minerID = tokenOfOwnerByIndex(owner, index);
            if(AllMinerInfo[minerID].mType == MinerType.GameMiner && AllMinerInfo[minerID].mStatus == MinerStatus.Pending) {
                return minerID;
            }
        }
        return type(uint256).max;
    }    


    /**
     * @dev Get the running game miner address of the specified owner
     * @param owner owner address
     */
    function getGamingMiners(address owner) external view returns (address[] memory) {
        uint256 totalMiners = balanceOf(owner);
        address[] memory gMiners = new address[](totalMiners);

        uint256 index;
        for(; index < totalMiners; index++) {     
            uint256 minerID = tokenOfOwnerByIndex(owner, index);
            if(AllMinerInfo[minerID].mType == MinerType.GameMiner && AllMinerInfo[minerID].mStatus == MinerStatus.Normal) {
                gMiners[index] = AllMinerInfo[minerID].mAddress;
            }
        }

        // Re-set the array length
        assembly { mstore(gMiners, index) }
        return gMiners;
    }  

    /**
     * @dev Check if allowed to mint a new game miner
     * @param owner owner address
     */
    function bAllowedToMintGameMiner(address owner) internal view returns (bool) {
        uint256 numberGame;
        uint256 numberReal;
        for(uint256 index; index < balanceOf(owner); index++) {     
            uint256 minerID = tokenOfOwnerByIndex(owner, index);
            if(AllMinerInfo[minerID].mStatus == MinerStatus.Normal ) {
                if(AllMinerInfo[minerID].mType == MinerType.GameMiner) {
                    numberGame = numberGame + 1;
                } else {
                    numberReal = numberReal + 1;
                }
            }
        }
        return numberGame <= numberReal;
    }   

    /**
     * @dev Get the token ID of the specified miner 
     * @param owner owner address
     * @param miner miner address to find, if it is zero, return the fisrt found running game miner
     */
/*    
    function getMinerTokenID(address owner, address miner) external view returns (uint256 tokenID) {
        uint256 totalMiners = balanceOf(owner);
        for(uint256 index; index < totalMiners; index++) {     
            uint256 minerID = tokenOfOwnerByIndex(owner, index);
            if( AllMinerInfo[minerID].mStatus == MinerStatus.Normal &&
                miner == AllMinerInfo[minerID].mAddress ) {
                return minerID;
            }    
        }
        return type(uint256).max;
    } 
*/
    /**
     * @dev Get all the miner info of the owner
     * @param owner owner address
     */
/*
    function GetMinerInfo(address owner) external view returns (Miner[] memory miners) {
        uint256 totalMiners = balanceOf(owner);
        miners = new Miner[](totalMiners);
        for(uint256 index;  index < totalMiners; index++) {     
            uint256 minerID = tokenOfOwnerByIndex(owner, index);
            miners[index] = AllMinerInfo[minerID];
        }
    }
*/
    function GetMinerInfo(address addrMiner) external view returns (address owner, Miner memory miner) {
        uint256 minerID = AllMinersToken[addrMiner];
        owner = ownerOf(minerID);
        miner = AllMinerInfo[minerID];
    }

    /**
     * @dev Get all the miner address of the owner
     * @param owner owner address
     */
    function GetMinersAddr(address owner) external view returns (address[] memory minersAddr) {
        uint256 totalMiners = balanceOf(owner);
        minersAddr = new address[](totalMiners);
        for(uint256 index;  index < totalMiners; index++) {     
            uint256 minerID = tokenOfOwnerByIndex(owner, index);
            minersAddr[index] = AllMinerInfo[minerID].mAddress;
        }
    }

    /**
     * @dev Register or unregister miner manufactures
     * @param manufactures manufactures to be registered or unregistered
     * @param yesOrNo = true, to register manufactures, = false, to unregister manufactures
     */
    function ManageManufactures(address[] calldata manufactures, bool yesOrNo) external onlyOwner {
      for(uint256 index;  index < manufactures.length; index++) {
        AllManufactures[manufactures[index]] = yesOrNo;
      }
    }

    /**
     * @dev Update the miner status
     * @param minerID miner ID of any type of miners
     * @param minerStatus new status
     */
    function SetMinersStatus(uint256 minerID, MinerStatus minerStatus) external onlyOwner {
        require(minerStatus != MinerStatus.Pending, 'Arkreen Miner: Wrong Input');      
        AllMinerInfo[minerID].mStatus = minerStatus;
    }

    /**
     * @dev Update the miner white list, add/remove the miners to/from the white list.
     *      Only miners in the white list are allowed to onboard as an NFT.
     * @param typeMiner Type of the miners to add, MinerType.Empty(=0) means to remove the miners
     * @param addressMiners List of the miners
     */
    function UpdateMinerWhiteList(uint8 typeMiner, address[] calldata addressMiners) external onlyMinerManager {
      address tempAddress;
      if(typeMiner == uint8(MinerType.GameMiner)) typeMiner = 0x10;   // set type of GameMiner to 0x10 for feasible to check empty
      for(uint256 index; index < addressMiners.length; index++) {
        tempAddress = addressMiners[index];
        if(typeMiner == 0xFF) {
          delete whiteListMiner[tempAddress];
          continue;
        }
        // Checked for non-existence
        require( tempAddress != address(0) && !tempAddress.isContract(), 'Arkreen Miner: Wrong Address');     
        require( whiteListMiner[tempAddress] == 0, 'Arkreen Miner: Miners Repeated');      
        whiteListMiner[tempAddress] = uint8(typeMiner);
      }
    }

    /**
     * @dev Update the cap to airdrop game miners
     * @param newMinerCap new cap to airdrop game miners
     */
    function ChangeAirdropCap(uint256 newMinerCap) external onlyOwner {
        require(newMinerCap >= counterGameMinerAirdrop, 'Arkreen Miner: Cap Is Lower');      
       capGameMinerAirdrop = newMinerCap;
    }    

    /**
     * @dev Set the timestamp of Arkreen network formal launch. 
     */
    function setLaunchTime(uint256 timeLaunch) external onlyOwner {
      require(timeLaunch > block.timestamp, 'Arkreen Miner: Low Timestamp');  
      timestampFormalLaunch = timeLaunch;
    }    

    /**
     * @dev Get the number of all the pending game miners
     */
    function GetPendingGameNumber() external view returns (uint256) {
      return allPendingGameMiners.length();
    }

    /**
     * @dev Check if holding miners
     * @param owner owner address
     */
    function isOwner(address owner) external view returns (bool) {
        // just considering number of tokens, token status not checked 
        return balanceOf(owner) > 0;
    }

    /**
     * @dev Set the Arkreen managing accounts 
     * @param managerType type of the managing account
     * @param managerAddress address of the managing account     
     */
    function setManager(uint256 managerType, address managerAddress) external onlyOwner {
      AllManagers[managerType] = managerAddress;
    }

    /**
     * @dev Withdraw all the onboarding fee
     * @param token address of the token to withdraw, USDC/ARKE
     */
    function withdraw(address token) public onlyOwner {
        address receiver = AllManagers[uint256(MinerManagerType.Payment_Receiver)];
        if(receiver == address(0)) {
            receiver = _msgSender();
        }
        uint256 balance = IERC20(token).balanceOf(address(this));
        TransferHelper.safeTransfer(token, receiver, balance);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public view override( ERC721EnumerableUpgradeable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory newBaseURI) external virtual onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }



}