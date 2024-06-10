// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./Vesting.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";


contract FactoryVestingClone {
    address immutable vestingImplementation;
    address [] vestings;
     struct VestingsInfo {
        string vestingName;
        address contractAddress;
       
    }

    mapping(string => VestingsInfo) public newVesitng;
    address VerifiedUserContractAddress = address(0);

    constructor(address _verifiedUserContractAddress) {
        require(_verifiedUserContractAddress != address(0),"Contract can't be added null"); 
        vestingImplementation = address(new Vesting());
        VerifiedUserContractAddress = _verifiedUserContractAddress;
    }
    uint public vestingCount;
   
    
    function getVesting(string memory vestingName) view public returns (address contractAddress) {
        return (newVesitng[vestingName].contractAddress);
    }

    function createVesting(
        string memory _vestingName,
        address _token,
        uint256 _lockBps,
        uint256 _vestBps,
        uint256 _lockClaimTime,
        uint256 _vestStart,
        uint256 _vestDuration,
        uint256 _vestInterval
    ) external returns (address) {
        require(newVesitng[_vestingName].contractAddress == address(0),"Vesting Already exist");
        require(_vestDuration % _vestInterval == 0 ,"Vest Duration is not divisable with vest interval");
        address clone = Clones.clone(vestingImplementation);
        Vesting(clone).init(
             _token, 
             _lockBps,
             _vestBps,
             _lockClaimTime,
             _vestStart,
             _vestDuration,
             _vestInterval,
             VerifiedUserContractAddress
            );
        vestings.push(clone);
        

        vestingCount++;
       
        newVesitng[_vestingName].vestingName = _vestingName;       
        newVesitng[_vestingName].contractAddress = address(clone);


        return address(clone);
    }


    modifier onlyAdminUser() {
            require(verifiedUser(VerifiedUserContractAddress).hasRole(verifiedUser(VerifiedUserContractAddress).DEFAULT_ADMIN_ROLE(),msg.sender), "Please admin allowed");
        _;
    }

     // Set verifiedUser Contract Addresses
    function setVerifiedUserContractAddress(address _verifyAddress) public virtual onlyAdminUser{
        require(_verifyAddress != address(0),"Contract can't be added null"); 
        VerifiedUserContractAddress = _verifyAddress;
    }
    
}