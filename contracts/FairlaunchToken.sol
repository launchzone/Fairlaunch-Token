// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./modules/GasPriceController.sol";
import "./modules/DexListing.sol";
import "./modules/TransferFee.sol";

contract FairlaunchToken is ERC20, GasPriceController, DexListing, TransferFee, Ownable {
    constructor(
        string memory name_,
        string memory symbol_,
        uint listingDuration_,
        uint initSupply_
    )
        ERC20(name_, symbol_)
        DexListing(listingDuration_)
    {
        _mint(msg.sender, initSupply_);
        _setTransferFee(msg.sender, 0, 0, 0);
    }

    function _transfer(
        address sender_,
        address recipient_,
        uint256 amount_
    )
        internal
        override
        onlyValidGasPrice
    {
        if (!_listingFinished) {
            uint fee = _updateAndGetListingFee(sender_, recipient_, amount_);
            require(fee <= amount_, "FairlaunchToken: listing fee too high");
            uint transferA = amount_ - fee;
            if (fee > 0) {
                // super._transfer(sender_, address(0xdead), fee);
                super._transfer(sender_, _getTransferFeeTo(), fee);
            }
            super._transfer(sender_, recipient_, transferA);
        } else {
            uint transferFee = _getTransferFee(sender_, recipient_, amount_);
            require(transferFee <= amount_, "transferFee too high");
            uint transferA = amount_ - transferFee;
            if (transferFee > 0) {
                super._transfer(sender_, _getTransferFeeTo(), transferFee);    
            }
            if (transferA > 0) {
                super._transfer(sender_, recipient_, transferA);    
            }
        }
    }

    /*
        Settings
    */

    function setMaxGasPrice(
        uint maxGasPrice_
    )
        external
        onlyOwner
    {
        _setMaxGasPrice(maxGasPrice_);
    }

    function setTransferFee(
        address to_,
        uint buyFee_,
        uint sellFee_,
        uint normalFee_
    )
        external
        onlyOwner
    {
        _setTransferFee(to_, buyFee_, sellFee_, normalFee_);
    }
}