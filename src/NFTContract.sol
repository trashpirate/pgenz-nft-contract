/**

PGENZ Collection
Website: https://pigeonpark.xyz
Telegram: https://pigeonpark.xyz/
Twitter: https://twitter.com/pigeonparketh

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {ERC721A, IERC721A} from "@erc721a/contracts/ERC721A.sol";
import {ERC721ABurnable} from "@erc721a/contracts/extensions/ERC721ABurnable.sol";

/// @title NFTContract NFTs
/// @author Nadina Oates
/// @notice Contract implementing ERC721A standard using the ERC20 token and ETH for minting
/// @dev Inherits from ERC721A and ERC721ABurnable and openzeppelin Ownable
contract NFTContract is ERC721A, ERC2981, ERC721ABurnable, Ownable {
    /**
     * TYPES
     */
    struct ConstructorArguments {
        string name;
        string symbol;
        address owner;
        uint256 tokenFee;
        uint256 ethFee;
        address feeAddress;
        address tokenAddress;
        string baseURI;
        string basicURI;
        string teamURI;
        string contractURI;
        uint256 maxSupply;
        uint96 royaltyNumerator;
    }

    enum ListType {
        Regular,
        Team,
        Basic
    }

    /**
     * Storage Variables
     */
    IERC20 private immutable i_paymentToken;

    address private s_feeAddress;
    uint256 private s_tokenFee;
    uint256 private s_ethFee;
    uint256 private s_batchLimit = 50;

    string private s_contractURI;

    bool private s_paused;

    uint256 s_currentSet;

    mapping(uint256 tokenId => uint256) private s_set;
    mapping(uint256 setId => bool) private s_randomized;
    mapping(uint256 setId => uint256) private s_counter;
    mapping(uint256 setId => uint256) private s_size;
    mapping(uint256 tokenId => uint256) private s_tokenURINumber;
    mapping(uint256 setId => string) private s_baseURI;

    uint256[] private s_ids;
    uint256 private s_nonce;

    mapping(address account => ListType) private s_whitelist;
    mapping(address account => bool) private s_claimed;

    /**
     * Events
     */
    event Paused(address indexed sender, bool isPaused);
    event TokenFeeSet(address indexed sender, uint256 fee);
    event EthFeeSet(address indexed sender, uint256 fee);
    event FeeAddressSet(address indexed sender, address feeAddress);
    event BatchLimitSet(address indexed sender, uint256 batchLimit);
    event BaseURIUpdated(address indexed sender, uint256 setId, string baseUri);
    event SetStarted(address indexed sender, uint256 currentSet);
    event ContractURIUpdated(address indexed sender, string contractUri);
    event RoyaltyUpdated(
        address indexed feeAddress,
        uint96 indexed royaltyNumerator
    );
    event MetadataUpdated(uint256 indexed tokenId);
    event WhitelistUpdated(
        address sender,
        uint256 numAccounts,
        uint256 whitelistId
    );

    /**
     * Errors
     */
    error NFTContract_InsufficientTokenBalance();
    error NFTContract_InsufficientMintQuantity();
    error NFTContract_ExceedsMaxSupply();
    error NFTContract_ExceedsMaxPerWallet();
    error NFTContract_ExceedsBatchLimit();
    error NFTContract_FeeAddressIsZeroAddress();
    error NFTContract_TokenTransferFailed();
    error NFTContract_InsufficientEthFee(uint256 value, uint256 fee);
    error NFTContract_EthTransferFailed();
    error NFTContract_BatchLimitTooHigh();
    error NFTContract_NonexistentToken(uint256);
    error NFTContract_TokenUriError();
    error NFTContract_NoBaseURI();
    error NFTContract_ContractIsPaused();
    error NFTContract_SetAlreadyStarted();
    error NFTContract_SetNotConfigured();

    /// @notice Constructor
    /// @param args constructor arguments:
    ///                     name: collection name
    ///                     symbol: nft symbol
    ///                     owner: contract owner
    ///                     tokenFee: minting fee in tokens
    ///                     ethFee: minting fee in native coin
    ///                     feeAddress: address for fees
    ///                     tokenAddress: ERC20 token address
    ///                     baseURI: base uri
    ///                     basicURI: uri for PGEN mints
    ///                     teamURI: uri for team mints
    ///                     contractURI: contract uri
    ///                     maxSupply: maximum nfts mintable for first set
    ///                     royaltyNumerator: basis points for royalty fees
    constructor(
        ConstructorArguments memory args
    ) ERC721A(args.name, args.symbol) Ownable(msg.sender) {
        if (args.feeAddress == address(0)) {
            revert NFTContract_FeeAddressIsZeroAddress();
        }
        if (bytes(args.baseURI).length == 0) revert NFTContract_NoBaseURI();

        s_tokenFee = args.tokenFee;
        s_ethFee = args.ethFee;
        s_feeAddress = args.feeAddress;
        i_paymentToken = IERC20(args.tokenAddress);
        s_paused = true;

        _setConfig(0, 20, 0, false, args.teamURI);
        _setConfig(1, 540, 0, false, args.basicURI);

        _setConfig(2, args.maxSupply, 0, true, args.baseURI);
        _setContractURI(args.contractURI);
        _setDefaultRoyalty(args.feeAddress, args.royaltyNumerator);

        _startSet(2);
        _transferOwnership(args.owner);
    }

    receive() external payable {}

    /// @notice Mints NFT for a eth and a token fee
    /// @param quantity number of NFTs to mint
    function mint(uint256 quantity) external payable {
        if (s_paused) revert NFTContract_ContractIsPaused();
        if (quantity == 0) revert NFTContract_InsufficientMintQuantity();
        if (quantity > s_batchLimit) revert NFTContract_ExceedsBatchLimit();

        // whitelists
        uint256 setId;
        bool takeFee = false;
        if (
            s_whitelist[msg.sender] == ListType.Team && !s_claimed[msg.sender]
        ) {
            setId = 0;
            quantity = 1;
            s_claimed[msg.sender] = true;
        } else if (
            s_whitelist[msg.sender] == ListType.Basic && !s_claimed[msg.sender]
        ) {
            setId = 1;
            quantity = 1;
            s_claimed[msg.sender] = true;
        } else {
            takeFee = true;
            setId = s_currentSet;
        }

        if ((s_counter[setId] + quantity) > s_size[setId]) {
            revert NFTContract_ExceedsMaxSupply();
        }

        // mint nfts
        uint256 tokenId = _nextTokenId();
        for (uint256 i = 0; i < quantity; i++) {
            _setTokenURI(tokenId, setId);
            unchecked {
                tokenId++;
            }
        }

        _mint(msg.sender, quantity);

        // collect fees
        uint256 tokenFee = s_tokenFee;
        if ((tokenFee > 0) && takeFee) {
            uint256 totalTokenFee = tokenFee * quantity;
            if (i_paymentToken.balanceOf(msg.sender) < totalTokenFee) {
                revert NFTContract_InsufficientTokenBalance();
            }
            bool success = i_paymentToken.transferFrom(
                msg.sender,
                s_feeAddress,
                totalTokenFee
            );
            if (!success) revert NFTContract_TokenTransferFailed();
        }

        uint256 ethFee = s_ethFee;
        if ((ethFee > 0) && takeFee) {
            uint256 totalEthFee = ethFee * quantity;
            if (msg.value < totalEthFee) {
                revert NFTContract_InsufficientEthFee(msg.value, totalEthFee);
            }

            (bool success, ) = payable(s_feeAddress).call{value: totalEthFee}(
                ""
            );
            if (!success) revert NFTContract_EthTransferFailed();
        }
    }

    /// @notice Sets whitelist (only owner)
    /// @param accounts to be added to whitelist
    /// @dev Use this to whitelist wallets: whitelistId = 0 (not whitelisted), = 1 (team), = 2 (basic/PGEN) !!! only 1 whitelist per wallet !!!
    /// @param accounts addresses to be whitelisted
    /// @param whitelistId id of whitelist (none = 0, team = 1, basic = 2)
    function setWhitelist(
        address[] calldata accounts,
        uint256 whitelistId
    ) external onlyOwner {
        for (uint256 index = 0; index < accounts.length; index++) {
            s_whitelist[accounts[index]] = ListType(whitelistId);
        }
        emit WhitelistUpdated(msg.sender, accounts.length, whitelistId);
    }

    /// @notice Sets minting fee in terms of ERC20 tokens (only owner)
    /// @param fee New fee in ERC20 tokens
    function setTokenFee(uint256 fee) external onlyOwner {
        s_tokenFee = fee;
        emit TokenFeeSet(msg.sender, fee);
    }

    /// @notice Sets minting fee in ETH (only owner)
    /// @param fee New fee in ETH
    function setEthFee(uint256 fee) external onlyOwner {
        s_ethFee = fee;
        emit EthFeeSet(msg.sender, fee);
    }

    /// @notice Sets the receiver address for the token/ETH fee (only owner)
    /// @param feeAddress New receiver address for tokens and ETH received through minting
    function setFeeAddress(address feeAddress) external onlyOwner {
        if (feeAddress == address(0)) {
            revert NFTContract_FeeAddressIsZeroAddress();
        }
        s_feeAddress = feeAddress;
        emit FeeAddressSet(msg.sender, feeAddress);
    }

    /// @notice Sets batch limit - maximum number of nfts that can be minted at once (only owner)
    /// @param batchLimit Maximum number of nfts that can be minted at once
    function setBatchLimit(uint256 batchLimit) external onlyOwner {
        if (batchLimit > 100) revert NFTContract_BatchLimitTooHigh();
        s_batchLimit = batchLimit;
        emit BatchLimitSet(msg.sender, batchLimit);
    }

    /// @notice Withdraw tokens from contract (only owner)
    /// @param tokenAddress Contract address of token to be withdrawn
    /// @param receiverAddress Tokens are withdrawn to this address
    /// @return success of withdrawal
    function withdrawTokens(
        address tokenAddress,
        address receiverAddress
    ) external onlyOwner returns (bool success) {
        IERC20 tokenContract = IERC20(tokenAddress);
        uint256 amount = tokenContract.balanceOf(address(this));
        success = tokenContract.transfer(receiverAddress, amount);
        if (!success) revert NFTContract_TokenTransferFailed();
    }

    /// @notice Withdraws ETH from contract (only owner)
    /// @param receiverAddress ETH withdrawn to this address
    /// @return success of withdrawal
    function withdrawETH(
        address receiverAddress
    ) external onlyOwner returns (bool success) {
        uint256 amount = address(this).balance;
        (success, ) = payable(receiverAddress).call{value: amount}("");
        if (!success) revert NFTContract_EthTransferFailed();
    }

    /// @notice Sets configuration for set
    /// @param setId to be updated
    /// @param counter counter for this set
    /// @param size size of the set
    /// @param randomized whether set should be randomized or not
    /// @param baseURI base uri
    function setConfig(
        uint256 setId,
        uint256 size,
        uint256 counter,
        bool randomized,
        string memory baseURI
    ) external onlyOwner {
        _setConfig(setId, size, counter, randomized, baseURI);
    }

    /// @notice Sets contract uri
    /// @param _contractURI contract uri for contract metadata
    function setContractURI(string memory _contractURI) external onlyOwner {
        _setContractURI(_contractURI);
    }

    /// @notice Sets royalty
    /// @param feeAddress address receiving royalties
    /// @param royaltyNumerator numerator to calculate fees (denominator is 10000)
    function setRoyalty(
        address feeAddress,
        uint96 royaltyNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(feeAddress, royaltyNumerator);
        emit RoyaltyUpdated(feeAddress, royaltyNumerator);
    }

    /// @notice Starts new set
    /// @param setId number of current set
    function startSet(uint256 setId) external onlyOwner {
        _startSet(setId);
    }

    /// @notice Pauses minting
    /// @param _isPaused boolean to set minting to be paused (true) or unpaused (false)
    function pause(bool _isPaused) external onlyOwner {
        s_paused = _isPaused;
        emit Paused(msg.sender, _isPaused);
    }

    /**
     * Getter Functions
     */

    /// @notice Gets payment token address
    function getPaymentToken() external view returns (address) {
        return address(i_paymentToken);
    }

    /// @notice Gets maximum supply
    function getMaxSupply() external view returns (uint256) {
        uint256 maxSupply;
        for (uint256 index = 0; index <= s_currentSet; index++) {
            maxSupply += s_size[index];
        }
        return maxSupply;
    }

    /// @notice Gets counter
    function getCounter(uint256 setId) external view returns (uint256) {
        return s_counter[setId];
    }

    /// @notice Gets minting token fee in ERC20
    function getTokenFee() external view returns (uint256) {
        return s_tokenFee;
    }

    /// @notice Gets minting fee in ETH
    function getEthFee() external view returns (uint256) {
        return s_ethFee;
    }

    /// @notice Gets address that receives minting fees
    function getFeeAddress() external view returns (address) {
        return s_feeAddress;
    }

    /// @notice Gets number of nfts allowed minted at once
    function getBatchLimit() external view returns (uint256) {
        return s_batchLimit;
    }

    /// @notice Gets base uri
    /// @param setId set id
    function getBaseURI(uint256 setId) external view returns (string memory) {
        return _baseURI(setId);
    }

    /// @notice Gets contract uri
    function getContractURI() external view returns (string memory) {
        return s_contractURI;
    }

    /// @notice Gets current set
    function getCurrentSet() external view returns (uint256) {
        return s_currentSet;
    }

    /// @notice Returns whitelist
    function isWhitelisted(address account) external view returns (ListType) {
        return s_whitelist[account];
    }

    /// @notice Returns if claimed
    function hasClaimed(address account) external view returns (bool) {
        return s_claimed[account];
    }

    /// @notice Gets whether contract is paused
    function isPaused() external view returns (bool) {
        return s_paused;
    }

    /**
     * Public Functions
     */

    /// @notice retrieves contractURI
    function contractURI() public view returns (string memory) {
        return s_contractURI;
    }

    /// @notice retrieves tokenURI
    /// @dev adapted from openzeppelin ERC721URIStorage contract
    /// @param tokenId tokenID of NFT
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721A, IERC721A) returns (string memory) {
        _requireOwned(tokenId);

        string memory _tokenURI = Strings.toString(s_tokenURINumber[tokenId]);

        string memory base = _baseURI(s_set[tokenId]);

        // If both are set, concatenate the baseURI and tokenURI (via string.concat).
        if (bytes(_tokenURI).length > 0) {
            return string.concat(base, _tokenURI);
        }

        return super.tokenURI(tokenId);
    }

    /// @notice checks for supported interface
    /// @dev function override required by ERC721
    /// @param interfaceId interfaceId to be checked
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721A, IERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /**
     * Internal/Private Functions
     */

    /// @notice Checks if token owner exists
    /// @dev adapted code from openzeppelin ERC721
    /// @param tokenId token id of NFT
    function _requireOwned(uint256 tokenId) internal view {
        ownerOf(tokenId);
    }

    /// @notice sets first tokenId to 1
    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }

    /// @notice Retrieves base uri
    function _baseURI(uint256 setId) internal view returns (string memory) {
        return s_baseURI[setId];
    }

    /// @notice Sets configuration for set
    /// @param setId to be updated
    /// @param size size of set
    /// @param counter counter for this set
    /// @param randomized whether set should be randomized
    /// @param baseURI base uri
    function _setConfig(
        uint256 setId,
        uint256 size,
        uint256 counter,
        bool randomized,
        string memory baseURI
    ) private {
        s_size[setId] = size;
        s_counter[setId] = counter;
        s_randomized[setId] = randomized;
        _setBaseURI(setId, baseURI);
    }

    /// @notice Sets current set
    /// @param setId number of current set
    function _startSet(uint256 setId) private {
        if (s_counter[setId] > 0) revert NFTContract_SetAlreadyStarted();
        if (bytes(s_baseURI[setId]).length == 0 || s_size[setId] == 0)
            revert NFTContract_SetNotConfigured();

        if (s_randomized[setId]) {
            delete s_ids;
            s_ids = new uint256[](s_size[setId]);
        }
        s_currentSet = setId;
        emit SetStarted(msg.sender, setId);
    }

    /// @notice Checks if token owner exists
    /// @dev adapted code from openzeppelin ERC721URIStorage
    /// @param tokenId tokenId of nft
    /// @param setId setId
    function _setTokenURI(uint256 tokenId, uint256 setId) private {
        s_set[tokenId] = setId;

        if (s_randomized[setId]) {
            s_tokenURINumber[tokenId] = _randomTokenURI();
        } else {
            s_tokenURINumber[tokenId] = s_counter[setId];
        }

        unchecked {
            s_counter[setId]++;
        }
        emit MetadataUpdated(tokenId);
    }

    /// @notice Sets base uri
    /// @param setId set number
    /// @param baseURI base uri for NFT metadata
    function _setBaseURI(uint256 setId, string memory baseURI) private {
        s_baseURI[setId] = baseURI;
        emit BaseURIUpdated(msg.sender, setId, baseURI);
    }

    /// @notice Sets contract uri
    /// @param _contractURI contract uri for contract metadata
    function _setContractURI(string memory _contractURI) private {
        s_contractURI = _contractURI;
        emit ContractURIUpdated(msg.sender, _contractURI);
    }

    /// @notice generates a random tokenURI
    function _randomTokenURI() private returns (uint256 randomTokenURI) {
        uint256 numAvailableURIs = s_ids.length;
        uint256 randIdx = uint256(
            keccak256(abi.encodePacked(block.prevrandao, s_nonce))
        ) % numAvailableURIs;

        // get new and nonexisting random id
        randomTokenURI = (s_ids[randIdx] != 0) ? s_ids[randIdx] : randIdx;

        // update helper array
        s_ids[randIdx] = (s_ids[numAvailableURIs - 1] == 0)
            ? numAvailableURIs - 1
            : s_ids[numAvailableURIs - 1];
        s_ids.pop();

        unchecked {
            s_nonce++;
        }
    }
}
