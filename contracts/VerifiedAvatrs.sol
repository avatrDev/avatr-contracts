// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/access/AccessControl.sol";


contract VerifiedAvatrs is AccessControl {

    /***********************************|
    |             Variables             |
    |__________________________________*/
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    mapping (address => bool) public verifiedUsers;  
    
    event VerifiedUserAdded(address indexed user);
    event VerifiedUserRemoved(address indexed user);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
    }


    function addVerifiedUser(address _address) public onlyRole(URI_SETTER_ROLE) {
        verifiedUsers[_address] = true;
        emit VerifiedUserAdded(_address);
    }

    function removeVerifiedUser(address _address) public onlyRole(URI_SETTER_ROLE) {
        verifiedUsers[_address] = false;
        emit VerifiedUserRemoved(_address);
    }

    function bulkAddVerifiedUsers(address[] memory _addresses) public onlyRole(URI_SETTER_ROLE) {
        for (uint256 i = 0; i < _addresses.length; i++) {
            verifiedUsers[_addresses[i]] = true;
            emit VerifiedUserAdded(_addresses[i]);
        }
    }

    function isUserVerified(address _address) public view returns (bool) {
        return verifiedUsers[_address];
    }


    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}