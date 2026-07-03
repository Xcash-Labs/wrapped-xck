// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.6.0
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

/// @custom:security-contact az0006t@protonmail.com
contract XCashKlassic is ERC20, ERC20Pausable, AccessControl {
    /// @notice Authorized to mint wrapped XCK.
    /// @dev Intended to be assigned to the bridge wallet or bridge contract.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Authorized to pause and unpause transfers in an emergency.
    /// @dev Intended to be assigned to an emergency administrator.
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor(address initialAdmin)
        ERC20("XCash Klassic", "wXCK")
    {
        require(initialAdmin != address(0), "Admin cannot be zero address");
        // Initially assign all roles to the admin.
        // Roles can be separated later without redeploying the token.
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(MINTER_ROLE, initialAdmin);
        _grantRole(PAUSER_ROLE, initialAdmin);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(to != address(0), "Invalid recipient");
        require(amount > 0, "Invalid amount");
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        require(amount > 0, "Invalid amount");
        _burn(msg.sender, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable)
    {
        super._update(from, to, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}