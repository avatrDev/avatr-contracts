// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


  /***********************************|
  |             Interface             |
  |__________________________________*/

interface ContractToken {
    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function safeTransferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

     function owner()
        external
        view
        returns (address);

    function decimals() external view returns (uint8);
    // function allowance(address owner, address spender) external view returns (uint256);
    
}
/**
Interface for Verified User
*/
interface verifiedUser {
    function isUserVerified(address userAddresss) external view returns(bool);
    function URI_SETTER_ROLE() external view returns(bytes32);
    function DEFAULT_ADMIN_ROLE() external view returns(bytes32);
    function hasRole(bytes32 role, address account) external view returns (bool);
}

interface previousNFTContract {
    function isNFTPurchased(address userAddresss) external view returns(bool);
}


contract AvatrMakoNFT is ERC721, ERC721URIStorage, ERC721Pausable, Ownable {
    

  /***********************************|
  |             Variables             |
  |__________________________________*/
    address public ContractTokenContractAddress = address(0);
    address public VerifiedUserContractAddress = address(0);
    address public TreasuryAddress = address(0);
    uint8 public currentStage=1;
    bool public isPublicMint=false;

    // NFT Type 1=> BRONZE NFT, 2=>SILVER NFT, 3=>GOLD NFT
   
   struct NFT {
        uint id;
        address avatrAddress;        
        uint8 nftType;
        bool isPurchased;
        uint8 nftStage;
        uint8 packageType;        
    }
    struct package {        
        uint8 packageType;   
        uint price;
    }

    struct stage {
        uint stageId;
        uint totalSupply;
        mapping(uint => package) packages;
    }

    mapping(uint => stage) public stages;
    mapping(uint => NFT) public nfts;
    mapping(address => NFT) private nftHolder;
    address public serverAddress;
    
    uint8 public nftType;
    uint256 public totalSupply;
    
    uint256 public nftFees;
    uint public totalMint;
    address public previousTypeContractAddress;

    uint256 private _tokenIdCounter = 0;


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721,ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    constructor(
        uint8 _nftType,
        uint256 _nftFees,
        address _previousTypeContractAddress,
        address initialOwner
    ) ERC721("Avatr NFT", "MAKO") Ownable(initialOwner){
        
        nftType = _nftType;
        totalSupply = 10100;
        
        nftFees = _nftFees;
        totalMint = 0;
        previousTypeContractAddress = _previousTypeContractAddress;

        for (uint8 i = 1; i <= 3; i++) {
            stages[i].stageId = i;
            stages[i].totalSupply = i == 1 ? 5000 : i == 2 ? 8500 : 10100;
            stages[i].packages[1] = package(1, 149000000);
            stages[i].packages[2] = package(2, 249000000);
            stages[i].packages[3] = package(3, 349000000);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    modifier onlyVerifiedUser() {
        if (!isPublicMint) {
            require(verifiedUser(VerifiedUserContractAddress).isUserVerified(msg.sender), "Please Verified from dapp");
        }
        _;
    }
    

function commonChecks(address to) private view {
        require(stages[currentStage].totalSupply >= _tokenIdCounter + 1, "Cannot mint more NFT on this stage");

        if (nftType > 1) {
            require(previousTypeContractAddress != address(0), "Previous contract address not added");
            require(previousNFTContract(previousTypeContractAddress).isNFTPurchased(msg.sender), "You cannot purchase this NFT, please purchase the previous NFT first.");
        }

        require(totalSupply > totalMint, "NFT cannot be created, total supply reached");
        require(nftHolder[to].isPurchased == false, "Cannot purchase this NFT right now");
        require(super.balanceOf(to) == 0, "Cannot mint more than one NFT");
        require(ContractTokenContractAddress != address(0), "Token contract address not added");     
    }

    modifier onlyServer(address to, uint8 packageType) {
        require(msg.sender == serverAddress, "This method is only for server use");
        commonChecks(to);
        _;
    }

    modifier validateMinting(address to, uint8 packageType) {
        require(packageType == 1 || packageType == 2 || packageType == 3, "Invalid package type");
        require(TreasuryAddress != address(0), "Token contract address not added");
        require(ContractTokenContractAddress != address(0), "Token contract address not added");
        require(ContractToken(ContractTokenContractAddress).balanceOf(to) >= getPrice(currentStage, packageType), "Amount is not sufficient for mint.");
        commonChecks(to);
        _;
    }
    
    function setStage(uint8 round) public virtual onlyOwner {
        require(round > currentStage && round < 4,"Can not update stage right now please check your input."); 
        stages[currentStage].totalSupply = totalMint;
       currentStage = round;
    }

    function setServer(address _server) public virtual onlyOwner {
        require(_server != address(0),"Contract can not be added null"); 
        serverAddress = _server;
    }
    
    // Set config Contract Addresses
    function setConfigAddresses(address _treasuryAddress, address _verifyAddress,address _contractUsdcAddress ) public virtual onlyOwner{
        require(_treasuryAddress != address(0) && _verifyAddress != address(0) &&  _contractUsdcAddress != address(0),"Contract can't be added null"); 
        TreasuryAddress = _treasuryAddress;          
        ContractTokenContractAddress = _contractUsdcAddress; 
        VerifiedUserContractAddress = _verifyAddress;
    }

    function setPublicMint(bool _isPublicMint) public virtual onlyOwner {      
        isPublicMint = _isPublicMint;
    }

    function safeMintForServer(address to, uint8 packageType) public virtual onlyServer(to, packageType) {
        createNFT(to, packageType);
    }

    function safeMint(address to, uint8 packageType) public virtual onlyVerifiedUser validateMinting(to, packageType) {        
        ContractToken(ContractTokenContractAddress).transferFrom(to, TreasuryAddress, getPrice(currentStage,packageType));
        createNFT(to, packageType);
    }


    function getPrice(uint8 NftStage, uint8 packageType) public view returns(uint256) {
        return  (stages[NftStage].packages[packageType].price) + nftFees;
    }

    function createNFT(address to, uint8 packageType) private {
        totalMint += 1;
        _tokenIdCounter  += 1;
        uint256 tokenId = _tokenIdCounter;
        _safeMint(to, tokenId);
        nftHolder[to].isPurchased = true;
        nftHolder[to].id = tokenId;
      
        nfts[tokenId].nftStage = currentStage;
        nfts[tokenId].id = tokenId;
        nfts[tokenId].avatrAddress = to;
        nfts[tokenId].nftType = nftType;
        nfts[tokenId].isPurchased = true;
        nfts[tokenId].packageType = packageType;
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function setTokenURI(string memory uri) public virtual onlyOwner {       
        _setTokenURI(1, uri);
    } 

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function isNFTPurchased(address userAddress) public view returns(bool) {
        return nftHolder[userAddress].isPurchased;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory)
    {         
        return string(abi.encodePacked(super.tokenURI(1), uint2str(tokenId), '.json'));
    }


    function tokensOfOwner(address tokenOwnerAddress) public view returns(uint) {
        return nftHolder[tokenOwnerAddress].id;
    }

    function getPackageType(uint256 tokenId) public view returns (uint8) {
        return nfts[tokenId].packageType;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId ) public virtual override(ERC721,IERC721)  {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override(ERC721,IERC721)  {        
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        require(super.balanceOf(to) == 0, "Already have NFT on recipient address");        
        super._safeTransfer(from, to, tokenId, data);
        nftHolder[from].id = 0;
        nftHolder[to].id = tokenId;        
        nfts[tokenId].avatrAddress = to;
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721,IERC721) {
        safeTransferFrom(from, to, tokenId, "");
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = super.ownerOf(tokenId);
        return (spender == owner || super.isApprovedForAll(owner, spender) || super.getApproved(tokenId) == spender);
    }
}