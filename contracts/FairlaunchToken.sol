// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./modules/GasPriceController.sol";
import "./modules/DexListing.sol";

contract FairlaunchToken is ERC20, GasPriceController, DexListing {
    constructor(
        string memory name_,
        string memory symbol_,
        address pairedCurrency_
    )
        ERC20(name_, symbol_)
    {
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
                super._transfer(sender_, address(0xdead), fee);
            }
            super._transfer(sender_, recipient_, transferA);
        } else {
            super._transfer(sender_, recipient_, amount_);
        }
    }    
}