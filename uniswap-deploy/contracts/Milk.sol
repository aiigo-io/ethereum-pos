// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Milk Token
 * @dev Implementation of the Milk ERC20 token
 */
contract Milk is ERC20, Ownable {
    uint8 private _decimals = 18;
    
    /**
     * @dev Constructor that gives the msg.sender an initial supply of tokens
     */
    constructor(uint256 initialSupply) ERC20("Milk", "Milk") {
        _mint(msg.sender, initialSupply * 10**decimals());
    }
    
    /**
     * @dev Returns the number of decimals used for token
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    
    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     * @return A boolean that indicates if the operation was successful
     */
    function mint(address to, uint256 amount) public onlyOwner returns (bool) {
        _mint(to, amount);
        return true;
    }
    
    /**
     * @dev Burns a specific amount of tokens from the caller
     * @param amount The amount of tokens to be burned
     */
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
} 