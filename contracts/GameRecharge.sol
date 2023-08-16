// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';

import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './libraries/TransferHelper.sol';

contract GameRecharge is 
    ContextUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
    
{

    mapping (address => mapping(address => uint256)) public reCharges;
    mapping (address => bool) public allowedToken;

    //modifier
    modifier onlyAllowedToken(address token){
        require(allowedToken[token] == true, "Only the specified token is accepted");
        _;
    }

    event Recharge(address indexed sender, address indexed token, uint256 indexed amount);


        //initialize
    function initialize()
        external
        virtual
        initializer
    {
        __UUPSUpgradeable_init();
        __Ownable_init_unchained();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
        onlyOwner
    {}

        /**
     * @dev Withdraw all the onboarding fee
     * @param token address of the token to withdraw, USDC/ARKE
     */
    function withdraw(address token) public onlyOwner {
        // address receiver = AllManagers[uint256(MinerManagerType.Payment_Receiver)];
        // if(receiver == address(0)) {
        //     receiver = _msgSender();
        // }

        if(token == address(0)) {
            TransferHelper.safeTransferETH(owner(), address(this).balance);      
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            TransferHelper.safeTransfer(token, owner(), balance);
        }
    }


    function rechargeWithApprove(address token, uint256 amount) public onlyAllowedToken(token){
        address sender = _msgSender();
        // IERC20Permit(token).transferFrom(sender, address(this), amount);

        TransferHelper.safeTransferFrom(token, sender, address(this), amount);

        reCharges[sender][token] += amount;

        emit Recharge(sender, token, amount);
    }

    function rechargeWithPermit(
        address token, 
        uint256 amount, 
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s) 
    public onlyAllowedToken(token){
        // Permit payment
        address sender = _msgSender();
        IERC20PermitUpgradeable(token).permit(sender, address(this), amount, deadline, v, r, s);
        TransferHelper.safeTransferFrom(token, sender, address(this), amount);

        reCharges[sender][token] += amount;

        emit Recharge(sender, token, amount);
        
    }

    function rechargeWithNative() public payable {
        // Check payment value
        require (msg.value >= 10**18, "msg.value should not be less than 10**18");
        reCharges[msg.sender][address(0)] += msg.value;

        emit Recharge(msg.sender, address(0), msg.value);
    }

    function updateAllowedToken(address token, bool allowed) public onlyOwner {
        allowedToken[token] = allowed;
    }

}