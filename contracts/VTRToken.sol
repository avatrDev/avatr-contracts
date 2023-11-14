// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";



contract VTRToken is ERC20, ERC20Pausable,Ownable {
    constructor() ERC20("AVATR", "VTR") {
        _mint(msg.sender, 46480000000 * (10 ** uint256(decimals())));
    }
    
    
     function decimals() public view virtual override returns (uint8) {
        return 18;
    }
   

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     * - a caller must be the owner
     */
    // function mint(address to, uint256 amount) external onlyOwner {
    //     _mint(to, amount);
    // }
   
   
   
    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements
     * - a caller must be the owner
     */
    function pause() external onlyOwner {
        _pause();
    }


    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     * - a caller must be the owner
     */
    function unpause() external onlyOwner {
        _unpause();
    }
   

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
   

}