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

    modifier mustHaveRecords(address _sender) {
        Person storage _person = persons[_sender];

        if (bytes(_person.name).length == 0 || bytes(_person.bio).length == 0) {
            revert SaveMyName__NoDetailsFound();
        }
        _;
    }

    constructor(address initialOwner) Ownable(initialOwner) {}

    function setDetails(Person calldata _person, address _sender) public {
        persons[_sender] = _person;
    }

    function updateDetails(Person calldata _info, address _sender) public mustHaveRecords(_sender) {
        Person storage _person = persons[_sender];

        if (bytes(_info.bio).length != 0) {
            _person.bio = _info.bio;
        }

        if (bytes(_info.name).length != 0) {
            _person.name = _info.name;
        }
    }

    function getPerson(address _sender) public view returns (Person memory) {
        return persons[_sender];
    }
}
