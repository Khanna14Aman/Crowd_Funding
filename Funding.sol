// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract CrowdFunding{
    mapping(address=>uint)contributors;
    address public manager;
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public actualAmount;
    uint public noOfContributors;


    constructor(uint _target,uint _deadline){
        manager = msg.sender;
        target = _target;
        deadline = block.timestamp+_deadline;
        minimumContribution = 100 wei;
    }
    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool)voters;
    }

    mapping(uint=>Request)public requests;
    uint public numRequests;

    function sendEth()public payable{
        require(block.timestamp<deadline,"DeadLine has passed");
        require(msg.value>=minimumContribution,"At least pay minimumContribution");
        if(contributors[msg.sender]==0){
            noOfContributors++;
        }
        contributors[msg.sender]+=msg.value;
        raisedAmount+=msg.value;
        actualAmount+=msg.value;
    }

    function getContractBalance()public view returns(uint){
        return address(this).balance;
    }

    function refund() public{
        require(block.timestamp>deadline && raisedAmount<target,"Target amount raised within the deadline. So you cannot get back money");
        require(contributors[msg.sender]>0,"You are not contributor");
        address payable user = payable(msg.sender);
        require(actualAmount>=contributors[msg.sender]);
        actualAmount-=contributors[msg.sender];
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
        noOfContributors--;
    }

    modifier onlyManager(){
        require(msg.sender==manager,"Only manager can call this function");
        _;
    }

    function createRequest(string memory _description,address payable _recipient,uint _value)public onlyManager{
        require(raisedAmount>=target,"Target amount does'nt achieved.");
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }

    function voteRequests(uint _requestNo)public{
        require(contributors[msg.sender]>0,"You must be contributor");
        require(_requestNo<numRequests,"This request does'nt exists.");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false,"You already voted");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNo)public onlyManager{
        require(raisedAmount>=target,"Target amount does'nt met.");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed==false,"You already get Paid.");
        require(thisRequest.value<=actualAmount,"We don't have this much amount");
        require(thisRequest.noOfVoters>noOfContributors/2,"Majority doesnot support");
        thisRequest.recipient.transfer(thisRequest.value);
        actualAmount-=thisRequest.value;
        thisRequest.completed = true;
    }
}