//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract IOU is Ownable {
    error IOU__InvalidMemberAddress();
    error IOU_InvalidAmount();
    error IOU_CreditorIsNotAMember();
    error IOU__CantOweSelf();
    error IOU__InvalidDebtId();
    error IOU__PayingBackTooMuch();
    error IOU_DEBTALREADYSETTLED();
    error IOU_DEBTNOTACCEPTED();

    enum DebtStatus {
        PENDING, // Initial state when a debt is requested
        ACCEPTED, // Creditor has approved the debt
        REJECTED, // Creditor has rejected the debt
        SETTLED // Debt has been paid

    }

    struct Debt {
        address creditor; // Who the debt is owed to
        address debtor; // Who owes the debt
        uint256 amount;
        string description;
        uint256 timestamp;
        DebtStatus status;
        uint256 debtId;
    }

    struct Friend {
        uint256 totalDeposited;
        uint256 availableBalance;
        uint256 totalOwed;
        uint256 totalOwedToUser;
    }

    mapping(address => Friend) public friendGroup;

    // debtId to debt
    mapping(uint256 => Debt) public allDebts;
    // debtId to creditor
    mapping(uint256 => address) public debtToCreditor;
    //debtId to debtor
    mapping(uint256 => address) public debtToDebtor;

    // debts - Debtor to Creditor to list of Debts
    mapping(address => mapping(address => Debt[])) public debtsIOwe;
    mapping(address => mapping(address => Debt[])) public debtsOwedToMe;

    // track pending debts
    mapping(address => uint256[]) public pendingDebtsToApprove;
    uint256 public nextDebtId = 1;

    // Track all members of the group
    address[] public members;
    mapping(address => bool) public isMember;

    modifier checkMember(address _memberAddress) {
        bool exists = isMember[_memberAddress];

        if (!exists || _memberAddress == address(0)) {
            revert IOU__InvalidMemberAddress();
        }
        _;
    }

    event NewMemberCreated(address indexed _newMember);
    event Deposited(address indexed _member, uint256 _amount);
    event DebtStatusChanged(uint256 debtId, address indexed _user, bool _isApproved);
    event DebtSettled(address indexed _user, address _creditor, uint256 _amount);

    constructor(address _initialOwner) Ownable(_initialOwner) {}

    function addMember(address _newMember) external {
        if (!isMember[_newMember]) {
            members.push(_newMember);
            isMember[_newMember] = true;

            friendGroup[_newMember].availableBalance = 0;
            friendGroup[_newMember].totalDeposited = 0;
            friendGroup[_newMember].totalOwed = 0;
            friendGroup[_newMember].totalOwedToUser = 0;

            emit NewMemberCreated(_newMember);
        }
    }

    function deposit(address _memberAddress, uint256 _amount) external payable checkMember(_memberAddress) {
        if (_amount <= 0) {
            revert IOU_InvalidAmount();
        }

        //TODO: call the msg.value in engine

        friendGroup[_memberAddress].totalDeposited += _amount;
        friendGroup[_memberAddress].availableBalance += _amount;

        emit Deposited(msg.sender, msg.value);
    }

    //
    function createDebt(address _creditor, address _debtor, uint256 _amount, string calldata _desc)
        external
        checkMember(_creditor)
    {
        if (!isMember[_debtor]) {
            revert IOU_CreditorIsNotAMember();
        }

        if (_amount <= 0) {
            revert IOU_InvalidAmount();
        }

        if (_creditor == _debtor) {
            revert IOU__CantOweSelf();
        }

        // Generate a unique debt ID
        uint256 debtId = nextDebtId++;

        Debt memory debtItem = Debt({
            creditor: _creditor,
            debtor: _debtor,
            amount: _amount,
            description: _desc,
            timestamp: block.timestamp,
            status: DebtStatus.PENDING,
            debtId: debtId
        });

        allDebts[debtId] = debtItem;
        debtToCreditor[debtId] = _creditor;
        debtToDebtor[debtId] = _debtor;

        // add to creditors recievable debts
        debtsOwedToMe[_creditor][_debtor].push(debtItem);

        //debts that _debtor owes
        debtsIOwe[_debtor][_creditor].push(debtItem);

        // add to pending debts for debtors approval
        pendingDebtsToApprove[_debtor].push(debtId);

        // update friendsGroup
        friendGroup[_creditor].totalOwedToUser += _amount;
        friendGroup[_debtor].totalOwed += _amount;
    }

    function respondToDebtClaim(address _user, uint256 _debtId, bool _isApproved) public checkMember(_user) {
        uint256 pendingIndex = type(uint256).max;

        // get pending debt
        for (uint256 i = 0; i < pendingDebtsToApprove[_user].length; i++) {
            if (pendingDebtsToApprove[_user][i] == _debtId) {
                pendingIndex = i;

                break;
            }
        }

        if (pendingIndex == type(uint256).max) {
            revert IOU__InvalidDebtId();
        }

        Debt storage debtItem = allDebts[_debtId];
        if (debtItem.debtor != _user) {
            revert IOU__InvalidDebtId();
        }

        debtItem.status = _isApproved ? DebtStatus.ACCEPTED : DebtStatus.REJECTED;

        if (!_isApproved) {
            friendGroup[_user].totalOwed -= debtItem.amount;
            friendGroup[debtItem.creditor].totalOwedToUser -= debtItem.amount;
        }

        // Remove from pending list (swap and pop for gas efficiency)
        uint256 lastIndex = pendingDebtsToApprove[msg.sender].length - 1;
        if (pendingIndex < lastIndex) {
            pendingDebtsToApprove[_user][pendingIndex] = pendingDebtsToApprove[_user][lastIndex];
        }
        pendingDebtsToApprove[_user].pop();

        emit DebtStatusChanged(_debtId, _user, _isApproved);
    }

    function settleDebt(address _user, address _creditor, uint256 _debtId, uint256 _amount)
        external
        payable
        checkMember(_user)
    {
        if (!isMember[_creditor]) {
            revert IOU_CreditorIsNotAMember();
        }

        if (_amount <= 0) {
            revert IOU_InvalidAmount();
        }

        if (_creditor == _user) {
            revert IOU__CantOweSelf();
        }

        Debt storage debtItem = allDebts[_debtId];

        if (_amount > debtItem.amount) {
            revert IOU__PayingBackTooMuch();
        }

        if (debtItem.status != DebtStatus.ACCEPTED) {
            revert IOU_DEBTNOTACCEPTED();
        }

        // Check if user has enough balance
        if (friendGroup[_user].availableBalance < _amount) {
            revert("Insufficient balance");
        }

        // Update debtor's balance
        friendGroup[msg.sender].availableBalance -= _amount;
        friendGroup[_user].totalOwed -= _amount;

        // Update creditor's balance
        friendGroup[_creditor].availableBalance += _amount;
        friendGroup[_creditor].totalOwedToUser -= _amount;

        debtItem.amount -= _amount;

        // Update debt status if fully paid
        if (debtItem.amount == 0) {
            debtItem.status = DebtStatus.SETTLED;
        }

        updateDebtMappings(_user, _creditor, _debtId, _amount);

        emit DebtSettled(_user, _creditor, _amount);
    }

    function updateDebtMappings(address _debtor, address _creditor, uint256 _debtId, uint256 _amount) internal {
        // updated debtsIOwe
        for (uint256 i = 0; i < debtsIOwe[_debtor][_creditor].length; i++) {
            if (debtsIOwe[_debtor][_creditor][i].debtId == _debtId) {
                debtsIOwe[_debtor][_creditor][i].amount -= _amount;

                if (debtsIOwe[_debtor][_creditor][i].amount == 0) {
                    debtsIOwe[_debtor][_creditor][i].status = DebtStatus.SETTLED;
                }
                break;
            }
        }
        // update debtsOwedToMe
        for (uint256 i = 0; i < debtsOwedToMe[_creditor][_debtor].length; i++) {
            if (debtsOwedToMe[_creditor][_debtor][i].debtId == _debtId) {
                debtsOwedToMe[_creditor][_debtor][i].amount -= _amount;
                if (debtsOwedToMe[_creditor][_debtor][i].amount == 0) {
                    debtsOwedToMe[_creditor][_debtor][i].status = DebtStatus.SETTLED;
                }
                break;
            }
        }
    }

    function getMyDebts(address _user) external view checkMember(_user) returns (Debt[] memory) {
        // count number of debts
        uint256 totalDebts = 0;

        for (uint256 i = 0; i < members.length; i++) {
            address creditor = members[i];

            if (creditor != _user) {
                // skip self
                totalDebts += debtsIOwe[_user][creditor].length;
            }
        }

        Debt[] memory usersDebts = new Debt[](totalDebts);

        // fill in the array with the debts
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < members.length; i++) {
            address creditor = members[i];

            if (creditor != _user) {
                for (uint256 j = 0; j < debtsIOwe[_user][creditor].length; j++) {
                    usersDebts[currentIndex] = debtsIOwe[_user][creditor][j];
                    currentIndex++;
                }
            }
        }

        return usersDebts;
    }

    function getDebtsOwedToMe(address _user) external view checkMember(_user) returns (Debt[] memory) {
        uint256 totalDebts = 0;

        for (uint256 i = 0; i < members.length; i++) {
            address debtor = members[i];
            if (debtor != _user) {
                totalDebts += debtsOwedToMe[_user][debtor].length;
            }
        }

        Debt[] memory usersReceivables = new Debt[](totalDebts);

        uint256 currentIndex = 0;
        for (uint256 i = 0; i < members.length; i++) {
            address debtor = members[i];
            if (debtor != _user) {
                Debt[] storage individualDebts = debtsOwedToMe[_user][debtor];
                for (uint256 j = 0; j < individualDebts.length; j++) {
                    usersReceivables[currentIndex] = individualDebts[j];
                    currentIndex++;
                }
            }
        }

        return usersReceivables;
    }
}
