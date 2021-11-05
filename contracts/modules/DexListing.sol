// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OriginOwner.sol";

import "../lib/LDex.sol";

contract DexListing is OriginOwner {

    address immutable public uniswapV2Router;
    address immutable public wbnbPair;
    address immutable public busdPair;

    uint private _listingFeePercent = 0;
    uint private _listingDuration;
    uint private _listingStartAt;

    bool internal _listingFinished;

    constructor(
        uint listingDuration_
    )
    {
        _listingDuration = listingDuration_;
        address router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = router;

        wbnbPair = LDex._createPair(router, LDex._wbnb);
        busdPair = LDex._createPair(router, LDex._busd);
    }

    function _startListing()
        private
        onlyOriginOwner
    {
        _listingStartAt = block.timestamp;
        _listingFeePercent = 100;

        // originOwner removed, once listing started
        _removeOriginOwner();
    }

    function _finishListing()
        private
    {
        _listingFinished = true;
    }

    function _updateListingFee()
        private
    {
        uint pastTime = block.timestamp - _listingStartAt;
        if (pastTime > _listingDuration) {
            _listingFeePercent = 0;
        } else {
            // pastTime == 0 => fee = 100
            // pastTime == _listingDuration => fee = 0
            _listingFeePercent = 100 * (_listingDuration - pastTime) / _listingDuration;
        }
    }

    function _updateAndGetListingFee(
        address sender_,
        address recipient_,
        uint256 amount_
    )
        internal
        returns(uint)
    {
        if (_listingStartAt == 0) {
            // first addLiquidity
            if (LDex._isPair(recipient_) && amount_ > 0) {
                _startListing();
            }
            return 0;
        } else {
            _updateListingFee();
            if (_listingStartAt + _listingDuration <= block.timestamp) {
                _finishListing();
            }

            if (!LDex._isPair(sender_) && !LDex._isPair(recipient_)) {
                // normal transfer
                return 0;
            } else {
                // swap
                return amount_ * _listingFeePercent / 100;
            }
        }
    }

    function listingDuration()
        public
        view
        returns(uint)
    {
        return _listingDuration;
    }

    function listingFinished()
        public
        view
        returns(bool)
    {
        return _listingFinished;
    }
}