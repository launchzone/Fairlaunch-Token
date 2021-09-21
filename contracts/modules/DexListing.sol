// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OriginOwner.sol";

import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IUniswapV2Factory.sol";

contract DexListing is OriginOwner {
    bytes4 private constant FACTORY_SELECTOR = bytes4(keccak256(bytes('factory()')));

    address constant private _wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address constant private _busd = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    address immutable public uniswapV2Router;
    address immutable public wbnbPair;
    address immutable public busdPair;

    uint private _listingFeePercent = 0;
    uint private _listingDuration = 100 seconds;
    uint private _listingStartAt;

    bool internal _listingFinished;

    constructor()
    {
        address router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = router;

        wbnbPair = IUniswapV2Factory(IUniswapV2Router02(router).factory())
            .createPair(address(this), _wbnb);
        busdPair = IUniswapV2Factory(IUniswapV2Router02(router).factory())
            .createPair(address(this), _busd);
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

    function _isPair(
        address pair_
    )
        internal
        returns(bool)
    {

        (bool success, bytes memory data) = 
            pair_.call((abi.encodeWithSelector(FACTORY_SELECTOR)));
        return success && data.length > 0;
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
            if (_isPair(recipient_) && amount_ > 0) {
                _startListing();
            }
            return 0;
        } else {
            _updateListingFee();
            if (_listingStartAt + _listingDuration <= block.timestamp) {
                _finishListing();
            }

            if (!_isPair(sender_) && !_isPair(recipient_)) {
                // normal transfer
                return 0;
            } else {
                // swap
                return amount_ * _listingFeePercent / 100;
            }
        }
    }
}