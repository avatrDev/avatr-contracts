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

    constructor() {
        vestingImplementation = address(new Vesting());
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
        address clone = Clones.clone(vestingImplementation);
        Vesting(clone).init(
             _token, 
             _lockBps,
             _vestBps,
             _lockClaimTime,
             _vestStart,
             _vestDuration,
             _vestInterval
            );
        vestings.push(clone);
        

        vestingCount++;
       
        newVesitng[_vestingName].vestingName = _vestingName;       
        newVesitng[_vestingName].contractAddress = address(clone);


        return address(clone);
    }
}