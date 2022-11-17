// SPDX-License-Identifier: MIT
// Contract created by Mohammed Rizwan

/* 1. Create a UI for this task using React.js.
2. One user can create multiple projects
3. other users can contribute to the project in terms of ether. you need to track the amount contributed to the project. 
   optional ( user can set a minimum amount of ether to contribute to the project) 
4. for spending collected ether of the project needs to create a request for spending money with the amount and target 
   address where you need to send ether.
   Hint: Create a requestEther method with two parameters amount and sender/vendor/target address to send ether.
5. For this, you need to take approval from the approver ( a user who contributed to this project). 
   You need to finalize the request, for success finalization required greater then 50% approval if approval is less then 
   50% transaction will not commit.
   Hint: you need to create two smart contracts one for project contribution and other related tasks and another one for 
   managing this project's instances. */

pragma solidity >= 0.7.0 < 0.9.0;

contract OpenSourceProject{

    mapping (address => uint) public contributors;
    address public manager;                                 //only manager can create multiple projects, manager is owner.
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors;

    struct Request{
        string description;
        address payable recepient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address => bool) voters;
    }
    mapping (uint => Request) public requests;
    uint public numRequests;

    constructor(uint _target, uint _deadline) {
        target = _target;
        deadline = block.timestamp + _deadline;           // deadline shall be in UNIX time format.
        minimumContribution = 100 wei;                    //set the minimum amount for contribution
        manager = msg.sender;
    }

    function sendETH() public payable{
        require(block.timestamp < deadline, "Deadline has passed");
        require (minimumContribution >= 100 wei, "Minimum contribution is not met");

        if (contributors[msg.sender] == 0) {
             noOfContributors++;
        }
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;      
    }

    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }

    function refund() public {                                // Refund if below conditions are true.
        require (block.timestamp > deadline && raisedAmount < target, "You are not eligible for refunds");
        require (contributors[msg.sender] > 0);
        address payable user = payable (msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }
  
    modifier onlyManager(){                                   // only manager can create the request, so modifier is created.
        require(manager == msg.sender, "Only manager can access this function");
        _;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyManager {
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description = _description;
        newRequest.recepient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }
    function voteRequest(uint _requestNo) public {
        require (contributors[msg.sender] > 0, "You must be a contributor to vote");
        Request storage thisRequest = requests[_requestNo];
        require (thisRequest.voters[msg.sender] == false, "You are already voted");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNo) public onlyManager{
        require (raisedAmount >= target);
        Request storage thisRequest = requests[_requestNo];
        require (thisRequest.completed == false, "The request is already completed");
        require (thisRequest.noOfVoters > noOfContributors/2, "Majority does not support"); 
        thisRequest.recepient.transfer(thisRequest.value);
        thisRequest.completed = true;
    }
}
