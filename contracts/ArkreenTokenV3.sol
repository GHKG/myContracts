// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol';
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';

import '@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol';

contract ArkreenTokenV3 is 
    ContextUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    ERC20VotesUpgradeable
{

    string  private constant _NAME = 'Arkreen Token';
    string  private constant _SYMBOL = 'tAKRE';
    string  private constant _VERSION = '1';

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 amount, address foundationAddr)
        external
        virtual
        initializer
    {
        __UUPSUpgradeable_init_unchained();
        __ERC1967Upgrade_init_unchained();
        __Context_init_unchained();
        
        __ERC20_init_unchained(_NAME, _SYMBOL);
        __ERC20Permit_init(_NAME);
        __Ownable_init_unchained();
        __Pausable_init_unchained();
    
    
        _mint(foundationAddr, amount * 10 ** decimals());
    
    }

    function decimals() public view virtual override returns (uint8) {
        // return 8;
        return 18;
    }

    function pause() external onlyOwner{
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

}