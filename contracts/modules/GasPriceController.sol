// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/*
    frontrun prevent
*/
contract GasPriceController is Ownable {
    event SetMaxGasPrice(
        uint maxGasPrice
    );

    modifier onlyValidGasPrice()
    {
        require(tx.gasprice <= _maxGasPrice,"GasPriceController: gasPrice too high");
        _;
    }

    uint constant public MIN_GASPRICE = 5 gwei;

    uint private _maxGasPrice = MIN_GASPRICE;

    function _setMaxGasPrice(
        uint maxGasPrice_
    )
        internal
    {
        require(maxGasPrice_ >= MIN_GASPRICE, "GasPriceController: too low");
        _maxGasPrice = maxGasPrice_;
        emit SetMaxGasPrice(maxGasPrice_);
    }

    function setMaxGasPrice(
        uint maxGasPrice_
    )
        external
        onlyOwner
    {
        _setMaxGasPrice(maxGasPrice_);
    }

    function maxGasPrice()
        external
        view
        returns(uint)
    {
        return _maxGasPrice;
    }
}