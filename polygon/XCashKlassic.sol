// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.6.0
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/// @custom:security-contact az0006t@protonmail.com
contract XCashKlassic is ERC20, ERC20Pausable, AccessControl {

    string public constant VERSION = "1.0.1";

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant CLAIM_SIGNER_ROLE = keccak256("CLAIM_SIGNER_ROLE");

    error InvalidAdmin();
    error AlreadyClaimed();
    error InvalidAmount();
    error ClaimExpired();
    error InvalidClaimSignature();
    error InvalidXckAddress();
    error InvalidBridgeId();

    mapping(bytes32 => bool) public claimed;

    event BridgeClaimed(
        bytes32 indexed bridgeId,
        address indexed recipient,
        uint256 amount,
        uint256 deadline
    );

    event BridgeBurned(
        bytes32 indexed bridgeId,
        address indexed sender,
        uint256 amount,
        string xckAddress
    );
    
    constructor(address initialAdmin) ERC20("XCash Klassic", "wXCK") {
        if (initialAdmin == address(0)) revert InvalidAdmin();

        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(PAUSER_ROLE, initialAdmin);
        _grantRole(CLAIM_SIGNER_ROLE, initialAdmin);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function claim(
        bytes32 bridgeId,
        uint256 amount,
        uint256 deadline,
        bytes calldata signature
    ) external whenNotPaused {
        if (claimed[bridgeId]) revert AlreadyClaimed();
        if (amount == 0) revert InvalidAmount();
        if (block.timestamp > deadline) revert ClaimExpired();

        bytes32 digest = keccak256(
            abi.encode(
                block.chainid,
                address(this),
                bridgeId,
                msg.sender,
                amount,
                deadline
            )
        );

        bytes32 ethSignedMessageHash =
            MessageHashUtils.toEthSignedMessageHash(digest);

        address signer = ECDSA.recover(ethSignedMessageHash, signature);

        if (!hasRole(CLAIM_SIGNER_ROLE, signer)) {
            revert InvalidClaimSignature();
        }

        claimed[bridgeId] = true;

        _mint(msg.sender, amount);

        emit BridgeClaimed(bridgeId, msg.sender, amount, deadline);
    }

    function burn(uint256 amount) external whenNotPaused {
        if (amount == 0) revert InvalidAmount();

        _burn(msg.sender, amount);
    }

    function bridgeBurn(bytes32 bridgeId, uint256 amount, string calldata xckAddress) external whenNotPaused {
        if (bridgeId == bytes32(0)) revert InvalidBridgeId();
        if (amount == 0) revert InvalidAmount();

        bytes calldata addr = bytes(xckAddress);

        if (
            addr.length != 98 ||
            addr[0] != bytes1("X") ||
            addr[1] != bytes1("C") ||
            addr[2] != bytes1("K")
        ) {
            revert InvalidXckAddress();
        }

        _burn(msg.sender, amount);

        emit BridgeBurned(bridgeId, msg.sender, amount, xckAddress);
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