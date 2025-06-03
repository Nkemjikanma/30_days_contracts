// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SaveMyName is Ownable {
    error SaveMyName__NoDetailsFound();

    struct Person {
        string name;
        string bio;
    }

    mapping(address => Person) private persons;

    modifier mustHaveRecords() {
        Person storage _person = persons[msg.sender];

        if (bytes(_person.name).length == 0 || bytes(_person.bio).length == 0) {
            revert SaveMyName__NoDetailsFound();
        }
        _;
    }

    constructor(address initialOwner) Ownable(initialOwner) {}

    function setDetails(Person calldata _person) public {
        persons[msg.sender] = _person;
    }

    function updateDetails(Person calldata _info) public mustHaveRecords {
        Person storage _person = persons[msg.sender];

        if (bytes(_info.bio).length != 0) {
            _person.bio = _info.bio;
        }

        if (bytes(_info.name).length != 0) {
            _person.name = _info.name;
        }
    }

    function getPerson() public view returns (Person memory) {
        return persons[msg.sender];
    }
}
