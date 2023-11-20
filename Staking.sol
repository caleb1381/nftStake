// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract StakingContract is Ownable, IERC721Receiver, ERC721Holder {
    using SafeERC20 for IERC20;
    IERC20 immutable rewardToken;
    IERC721 immutable NFT;

    enum CollectionType {
        OG_CM,
        CRM,
        HunterZ
    }

    struct StakingInfo {
        uint256 softStakingMultiplier;
        uint256 hardStakingMultiplier;
        uint256 dailyReward;
        uint256 accumulatedReward;
        uint256 lastClaimTime;
        bool isStaked;
    }

    // mapping(address => mapping(uint256 => StakingInfo)) public stakingInfo;
    mapping(address => mapping(uint256 => StakingInfo)) public ogCmStakingInfo;
    mapping(address => mapping(uint256 => StakingInfo)) public crmStakingInfo;
    mapping(address => mapping(uint256 => StakingInfo))
        public hunterZStakingInfo;

    constructor(address _nft, address _token) Ownable(msg.sender) {
        NFT = IERC721(_nft);
        rewardToken = IERC20(_token);
    }

    // events
    event SoftStake(
        address indexed owner,
        CollectionType indexed collection,
        uint256 indexed tokenId,
        uint256 reward
    );
    event HardStake(
        address indexed owner,
        CollectionType indexed collection,
        uint256 indexed tokenId,
        uint256 reward
    );
    event UnlockNFT(
        address indexed owner,
        CollectionType indexed collection,
        uint256 indexed tokenId
    );
    event ClaimReward(
        address indexed owner,
        CollectionType indexed collection,
        uint256 indexed tokenId,
        uint256 reward
    );

    function softStake(CollectionType _collection, uint256 _tokenId) external {
        require(
            !_isStaked(msg.sender, _collection, _tokenId),
            "NFT is already staked"
        );

        uint256 reward = _calculateSoftStakingReward(_collection, _tokenId);
        uint256 multiplier = _getMultiplier(_collection, _tokenId);

        rewardToken.transfer(msg.sender, reward * multiplier);

        _updateStakingInfo(_collection, _tokenId, reward, multiplier);

        emit SoftStake(msg.sender, _collection, _tokenId, reward * multiplier);
    }

    function hardStake(CollectionType _collection, uint256 _tokenId) external {
        require(
            !_isStaked(msg.sender, _collection, _tokenId),
            "NFT is already staked"
        );

        uint256 reward = _calculateHardStakingReward(_collection, _tokenId);
        uint256 multiplier = _getMultiplier(_collection, _tokenId);

        NFT.safeTransferFrom(msg.sender, address(this), _tokenId, "");

        rewardToken.transfer(msg.sender, reward * multiplier);

        // _updateStakingInfo(msg.sender, _collection, _tokenId, reward, multiplier);

        emit HardStake(msg.sender, _collection, _tokenId, reward * multiplier);
    }

    function unstakeNFT(CollectionType _collection, uint256 _tokenId) external {
        require(
            _isStaked(msg.sender, _collection, _tokenId),
            "NFT is not staked"
        );

        // transfer NFT back to the owner

        // Update staking info
        // stakingInfo[msg.sender][uint256(_collection)][_tokenId].isStaked = false;

        emit UnlockNFT(msg.sender, _collection, _tokenId);
    }

    function claimReward(
        CollectionType _collection,
        uint256 _tokenId
    ) external {
        require(
            _isStaked(msg.sender, _collection, _tokenId),
            "NFT is not staked"
        );

        uint256 reward = _calculateAccumulatedReward(_collection, _tokenId);
        uint256 multiplier = _getMultiplier(_collection, _tokenId);

        require(reward > 0, "No accumulated reward to claim");

        rewardToken.transfer(msg.sender, reward * multiplier);

        _updateStakingInfo(_collection, _tokenId, 0, multiplier);

        emit ClaimReward(
            msg.sender,
            _collection,
            _tokenId,
            reward * multiplier
        );
    }

    function _isStaked(
        address _owner,
        CollectionType _collection,
        uint256 _tokenId
    ) internal view returns (bool) {
        if (_collection == CollectionType.OG_CM) {
            return ogCmStakingInfo[_owner][_tokenId].isStaked;
        } else if (_collection == CollectionType.CRM) {
            return crmStakingInfo[_owner][_tokenId].isStaked;
        } else if (_collection == CollectionType.HunterZ) {
            return hunterZStakingInfo[_owner][_tokenId].isStaked;
        } else {
            // Handle unknown collection type
            revert("Unknown CollectionType");
        }
    }

    function _calculateSoftStakingReward(
        CollectionType _collection,
        uint256 _tokenId
    ) internal view returns (uint256) {
        //
    }

    function _calculateHardStakingReward(
        CollectionType _collection,
        uint256 _tokenId
    ) internal view returns (uint256) {
        //
    }

    function _calculateAccumulatedReward(
        CollectionType _collection,
        uint256 _tokenId
    ) internal view returns (uint256) {
        //
    }

    function _getMultiplier(
        CollectionType _collection,
        uint256 _tokenId
    ) internal view returns (uint256) {
        // return stakingInfo[msg.sender][uint256(_collection)][_tokenId].softStakingMultiplier;
    }

    function _updateStakingInfo(
        CollectionType _collection,
        uint256 _tokenId,
        uint256 _reward,
        uint256 _multiplier
    ) internal {
        if (_collection == CollectionType.CRM) {
            ogCmStakingInfo[msg.sender][_tokenId] = StakingInfo({
                softStakingMultiplier: _multiplier,
                hardStakingMultiplier: _multiplier * 3,
                dailyReward: _reward,
                accumulatedReward: _reward,
                lastClaimTime: block.timestamp,
                isStaked: true
            });
        } else if (_collection == CollectionType.CRM) {
            crmStakingInfo[msg.sender][_tokenId] = StakingInfo({
                softStakingMultiplier: _multiplier,
                hardStakingMultiplier: _multiplier * 3,
                dailyReward: _reward,
                accumulatedReward: _reward,
                lastClaimTime: block.timestamp,
                isStaked: true
            });
        } else if (_collection == CollectionType.HunterZ) {
            hunterZStakingInfo[msg.sender][_tokenId] = StakingInfo({
                softStakingMultiplier: _multiplier,
                hardStakingMultiplier: _multiplier * 3,
                dailyReward: _reward,
                accumulatedReward: _reward,
                lastClaimTime: block.timestamp,
                isStaked: true
            });
        } else {
            revert("Unknown CollectionType");
        }
    }
}
