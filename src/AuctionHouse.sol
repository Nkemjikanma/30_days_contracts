// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AuctionHouse is Ownable {
    /**
     * Errors ********
     */
    error AuctionHouse__MissingAuctionCreationFields();
    error AuctionHouse__AuctionInactive();
    error AuctionHouse__BidAmountTooLow();
    error AuctionHouse_BidHadEnded();
    error AuctionHouse__UserNotAuthorised();
    error AuctionHouse__CantCancelAuctionAterBidPlaced();

    /**
     * Storage *******
     */
    struct Bid {
        address bidder;
        uint256 amount;
        uint256 timestamp;
    }

    struct AuctionItem {
        string name;
        string description;
        uint256 startingPrice;
        bool isApprovedForAuction;
        uint256 startTime;
        uint256 auctionDuration;
        address highestBidder;
        uint256 highestBid;
        address seller;
        bool isActive;
        // Track all bids
        Bid[] bids;
        // Quick lookup for specific bidders
        mapping(address => uint256) bidderToAmount;
        address[] bidders;
    }

    mapping(uint256 => AuctionItem) public auctionItems;
    uint256 public auctionId;

    /**
     * Events *******
     */
    event AuctionCreated(address indexed seller, uint256 currentAuctionId);
    event AuctionEnded(string name, address indexed seller, uint256 highestBid);
    event BidPlaced(string name, address indexed bidder, uint256 timeStamp);

    constructor(address _initialOwner) Ownable(_initialOwner) {}

    /**
     *
     *
     *
     */
    function createAuction(
        string calldata _name,
        string calldata _description,
        uint256 _startingPrice,
        uint256 _durationInMinutes,
        address _seller
    ) external {
        if (
            bytes(_name).length == 0 || bytes(_description).length == 0 || _startingPrice == 0
                || _durationInMinutes == 0
        ) {
            revert AuctionHouse__MissingAuctionCreationFields();
        }
        uint256 _currentAuctionId = auctionId++;

        AuctionItem storage newItem = auctionItems[_currentAuctionId];
        newItem.name = _name;
        newItem.description = _description;
        newItem.startingPrice = _startingPrice;
        newItem.isApprovedForAuction = true;
        newItem.startTime = block.timestamp;
        newItem.auctionDuration = block.timestamp + (_durationInMinutes * 1 minutes);
        newItem.seller = _seller;
        newItem.isActive = true;

        emit AuctionCreated(_seller, _currentAuctionId);
    }

    /**
     *
     *
     *
     */
    function placeBid(uint256 _auctionId, uint256 _amount, address _bidder) external {
        AuctionItem storage item = auctionItems[_auctionId];

        // checks
        if (item.isActive != true) {
            revert AuctionHouse__AuctionInactive();
        }

        if (item.highestBid > _amount) {
            revert AuctionHouse__BidAmountTooLow();
        }

        if (block.timestamp > item.auctionDuration) {
            revert AuctionHouse_BidHadEnded();
        }

        // check if this is new bidder if yes, add bidder list
        if (item.bidderToAmount[_bidder] == 0) {
            item.bidders.push(_bidder);
        }

        item.bidderToAmount[_bidder] = _amount;

        Bid memory newBid = Bid({bidder: _bidder, amount: _amount, timestamp: block.timestamp});

        item.bids.push(newBid);

        // get previous highest bidder info
        address previousHighestBidder = item.highestBidder;
        uint256 previousHighestBid = item.highestBid;

        // update hightest bids
        item.highestBidder = _bidder;
        item.highestBid = _amount;

        // return previous highest bid if there was a previous highest bidder
        if (previousHighestBidder != address(0)) {
            payable(previousHighestBidder).transfer(previousHighestBid);
        }

        emit BidPlaced(item.name, _bidder, newBid.timestamp);
    }

    function endAuction(uint256 _auctionId, address _user) external {
        AuctionItem storage item = auctionItems[_auctionId];

        // checks
        if (_user != item.seller) {
            revert AuctionHouse__UserNotAuthorised();
        }
        if (item.isActive != true) {
            revert AuctionHouse__AuctionInactive();
        }

        item.isActive = false;

        if (item.highestBidder != address(0)) {
            payable(item.seller).transfer(item.highestBid);
        }

        emit AuctionEnded(item.name, item.seller, item.highestBid);
    }

    // cancel auction before bids come in
    function cancelAuction(uint256 _auctionId, address _user) external {
        AuctionItem storage item = auctionItems[_auctionId];

        // checks
        if (_user != item.seller) {
            revert AuctionHouse__UserNotAuthorised();
        }

        if (item.bids.length > 0) {
            revert AuctionHouse__CantCancelAuctionAterBidPlaced();
        }

        item.isActive = false;
    }

    function getAuctionDetails(uint256 _auctionId)
        external
        view
        returns (string memory, string memory, uint256, uint256, bool, uint256, address, bool)
    {
        AuctionItem storage item = auctionItems[_auctionId];

        return (
            item.name,
            item.description,
            item.startingPrice,
            item.highestBid,
            item.isApprovedForAuction,
            item.startTime,
            item.seller,
            item.isActive
        );
    }

    function getBids(uint256 _auctionId) external view returns (Bid[] memory) {
        AuctionItem storage item = auctionItems[_auctionId];
        return item.bids;
    }

    function getBidders(uint256 _auctionId) external view returns (address[] memory) {
        AuctionItem storage item = auctionItems[_auctionId];
        return item.bidders;
    }

    // return all auction Ids where user has bid
    function getMyBids(address _user) external view returns (uint256[] memory) {
        // store number of bids
        uint256 count = 0;

        for (uint256 i = 0; i < auctionId; i++) {
            if (auctionItems[i].bidderToAmount[_user] > 0) {
                count++;
            }
        }

        // create memory of right size using count because we need to know size at runtime
        uint256[] memory myBids = new uint256[](count);

        // fill the array
        uint256 index = 0;
        for (uint256 i = 0; i < auctionId; i++) {
            if (auctionItems[i].bidderToAmount[_user] > 0) {
                myBids[index] = i;
                index++;
            }
        }
        return myBids;
    }

    // return all auction ids created by user
    function getMyAuctions(address _user) external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < auctionId; i++) {
            if (auctionItems[i].seller == _user) {
                count++;
            }
        }

        uint256[] memory myAuctions = new uint256[](count);

        // fill array
        uint256 index = 0;
        for (uint256 i = 0; i < auctionId; i++) {
            if (auctionItems[i].seller == _user) {
                myAuctions[index] = i;
                index++;
            }
        }

        return myAuctions;
    }
}
