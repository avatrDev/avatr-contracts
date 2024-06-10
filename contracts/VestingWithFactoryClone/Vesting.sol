// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 import "@openzeppelin/contracts/utils/Context.sol";
 import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 import "@openzeppelin/contracts/utils/math/SafeMath.sol";
 import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
 import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
 import "@openzeppelin/contracts/proxy/utils/Initializable.sol";



/**
Interface for Verified User
*/
interface verifiedUser {
    function isUserVerified(address userAddresss) external view returns(bool);
    function URI_SETTER_ROLE() external view returns(bytes32);
    function DEFAULT_ADMIN_ROLE() external view returns(bytes32);
    function hasRole(bytes32 role, address account) external view returns (bool);
}

/**
 * @title Vesting and timelock contract
 * @dev Keeps tokens allocated for beneficiaries and releases them over time.
 * The Lock'ed portion gets released after lockClaimTime.
 * Vested portion gets released gradually after vestStart.
 **/
contract Vesting is Initializable, Context, ReentrancyGuard {
    using SafeERC20 for IERC20;
    event LockRelease(address beneficiary, uint256 amount);
    event VestRelease(address beneficiary, uint256 amount);
    event Allocate(address beneficiary, uint256 amount);

    IERC20 public token;

    // relative values of how much allocated funds are locked by timeLock and vesting
    // expressed in 1/10000 basis points. The total should be 10000 (100%)
    uint256 public lockBps;
    uint256 public vestBps;

    // the moment when time-locked amount becomes available for claiming
    uint256 public lockClaimTime;

    // vesting parameters
    uint256 public vestStart; // the moment of gradual unlocking of vest funds
    uint256 public vestDuration; // the total timespan of vesting
    // receipt of funds tied to intervals. If user claimed in current interval,
    // he can't claim funds again before interval expired
    uint256 public vestInterval;

    uint256 public totalVestingAmount;

    struct Allocation {
        // amount allocated for given beneficiary
        // Virtually divided into two parts - timeLock and vest
        uint256 amount;
        // amount already paid out to the user
        uint256 released;
    }

    mapping(address => Allocation) public allocations;

    uint256 public constant MAX_ALLOCATIONS_PER_TX = 100;

    address VerifiedUserContractAddress = address(0);

    /**
     * @dev common parameters are given through constructor.
     * @param _token ERC-20 token that gets allocated
     * @param _lockBps relative part that gets Lock-ed by time. Nominated in bps (1/10000)
     * @param _vestBps part that gets Lock-ed by time. Nominated in bps (1/10000).
     * @param _lockClaimTime moment after which the time-Locked part is unlocked
     * @param _vestStart moment after which the gradual unlocking of the Vested amount begins
     * @param _vestDuration how long does a gradual unlock last. After _vestStart + _vestDuration Vesting part is fully unlocked
     * @param _vestInterval time interval within which the unlock is calculated
     **/
    function init (
        address _token,
        uint256 _lockBps,
        uint256 _vestBps,
        uint256 _lockClaimTime,
        uint256 _vestStart,
        uint256 _vestDuration,
        uint256 _vestInterval,
        address _verifiedUserContractAddress
    ) public initializer {
        require(_token != address(0), "token address cannot be zero");
        require(_vestInterval > 0, "interval should be greater than 0");
        require(_vestDuration > _vestInterval, "duration should be greater than interval");
        require(_lockBps + _vestBps == 10000, "sum of Lock and Vest bps should be 10000");
        require(_lockClaimTime > _getCurrentBlockTime(), "lockClaimTime should be in the future");
        require(_vestStart >= _lockClaimTime, "vestStart earlier than lockClaimTime");
        require(_verifiedUserContractAddress != address(0),"Contract can't be added null"); 
        token = IERC20(_token);
        lockBps = _lockBps;
        vestBps = _vestBps;
        lockClaimTime = _lockClaimTime;
        vestStart = _vestStart;
        vestDuration = _vestDuration;
        vestInterval = _vestInterval;
        VerifiedUserContractAddress = _verifiedUserContractAddress;
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

    /**
     * @dev submit multiple records of beneficiaries and their allocations in one transaction
     * @param _allocations ABI-encoded array of beneficiaries and amounts
     **/
    function setAllocations(bytes[] memory _allocations) external nonReentrant onlyAdminUser {
    
    require(_allocations.length <= MAX_ALLOCATIONS_PER_TX, "Too many allocations");

    uint256 totalAmount;
    address beneficiary;
    uint256 amount;

        for (uint256 i = 0; i < _allocations.length; i++) {
            (beneficiary, amount) = abi.decode(_allocations[i], (address, uint256));
            
            require(beneficiary != address(0), "Beneficiary is the zero address");

            Allocation storage alloc = allocations[beneficiary];
            require(alloc.amount == 0, "Already allocated");
            require(alloc.released == 0, "Already released");

            alloc.amount = amount;
            totalAmount += amount;
            emit Allocate(beneficiary, amount);
        }
        totalVestingAmount += totalAmount;
        token.safeTransferFrom(_msgSender(), address(this), totalAmount);
    }

    /**
     * @dev submit the single allocation record
     * @param beneficiary address of holder
     * @param beneficiary amount
     **/
    function setAllocation(address beneficiary, uint256 amount) external nonReentrant onlyAdminUser {
        require(beneficiary != address(0), "Beneficiary is the zero address");
        require(allocations[beneficiary].amount == 0, "Already allocated");
        require(allocations[beneficiary].released == 0, "Already released");
        allocations[beneficiary].amount = amount;
        totalVestingAmount = totalVestingAmount + amount;
        emit Allocate(beneficiary, amount);
        token.safeTransferFrom(_msgSender(), address(this), amount);
    }

    /**
     * @dev called to send unfrozen tokens to the beneficiary.
     * @param beneficiary account to whom tokens were allocated
     **/
    function release(address beneficiary) external nonReentrant {
        require(beneficiary != address(0), "Beneficiary is the zero address");
        (  uint256 _amount,
            ,
            ,
            uint256 _released,
            ,
            ,
            ,
            ,
            ,
            uint256 _releasable,
            uint256 _lockReleasable,
            uint256 _vestReleasable
        ) = getAllocation(beneficiary);

        require(_released < _amount, "Amount already released");
        require(_releasable > 0, "Nothing to release yet");
       
        if (_lockReleasable > 0) {
            allocations[beneficiary].released += _lockReleasable;
            emit LockRelease(beneficiary, _lockReleasable);
            token.safeTransfer(beneficiary, _lockReleasable);
        }

        if (_vestReleasable > 0) {
            allocations[beneficiary].released += _vestReleasable;
            emit VestRelease(beneficiary, _vestReleasable);
            token.safeTransfer(beneficiary, _vestReleasable);
        }
    }

    /**
     * @dev calculates and returns the full information about beneficiary's allocation
     * @param beneficiary address of beneficiary (holder)
     **/
    function getAllocation(address beneficiary)
        public
        view
        returns (
            uint256 amount,
            uint256 lockAmount,
            uint256 vestAmount,
            uint256 released,
            uint256 lockReleased,
            uint256 vestReleased,
            uint256 unfrozen,
            uint256 lockUnfrozen,
            uint256 vestUnfrozen,
            uint256 releasable,
            uint256 lockReleasable,
            uint256 vestReleasable
        )
    {
        amount = allocations[beneficiary].amount;
        lockAmount = (amount * lockBps) / 10000;
        vestAmount = amount - lockAmount;

        released = allocations[beneficiary].released;

        if (released >= lockAmount) {
            lockReleased = lockAmount;
            vestReleased = released - lockReleased;
        }

        lockUnfrozen = getLockUnfrozen(lockAmount);
        vestUnfrozen = getVestUnfrozen(vestAmount);
        unfrozen = lockUnfrozen + vestUnfrozen;

        if (lockUnfrozen > lockReleased) {
            lockReleasable = lockUnfrozen - lockReleased;
        }

        if (vestUnfrozen > vestReleased) {
            vestReleasable = vestUnfrozen - vestReleased;
        }
        releasable = lockReleasable + vestReleasable;
    }

    /**
     * @dev calculates how much of given TimeLock-ed amount is unfrozen to the moment.
     * depends on time (is lockClaimTime happened or not).
     * @param lockAmount the total amount of Time_Locked tokens
     * @return unfrozen amount
     **/
    function getLockUnfrozen(uint256 lockAmount) public view returns (uint256) {
        if (_getCurrentBlockTime() >= lockClaimTime) {
            return lockAmount;
        }
        return 0;
    }

    /**
     * @dev calculates how much of given Vest-ed amount is unfrozen to the moment.
     * depends on time (is vestStart happened, is vestDurationPassed or how much intervals passed to the moment).
     * @param vestAmount the total amount of Vest-ed tokens
     * @return unfrozen amount
     **/
    function getVestUnfrozen(uint256 vestAmount) public view returns (uint256) {
        uint256 vestEnd = vestStart + vestDuration;
        uint256 currentTime = _getCurrentBlockTime();
        if (currentTime <= vestStart) {
            return 0;
        }
        if (currentTime >= vestEnd) {
            return vestAmount;
        }
        uint256 passedInvervals = (currentTime - vestStart) / vestInterval;
        uint256 totalIntervals = vestDuration / vestInterval;
        uint256 vestUnfrozenAmount = (vestAmount * passedInvervals) / totalIntervals;
        return vestUnfrozenAmount;
    }

    /**
     * @dev This function introduced for testing purposes and allows time mocking in tests
     * @return current timestamp
     **/
    function _getCurrentBlockTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}