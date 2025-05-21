// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "contracts/PriceConverter.sol";
contract KumFundme{
    AggregatorV3Interface priceFeed;
    using PriceConverter for uint256;

    address private owner;
    struct Donor{
        address donor;
        string message;
        uint256 value;
    }

    Donor[] public donors;
    mapping (address sender => uint256 value) public senderToValue;
    mapping (address sender => Donor ) public addressToDonor;
    uint256 public minimumVal = 10e18;

    constructor(){
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }

    function donate() public payable returns (string memory){
        uint256 ethSent = msg.value.getConversionRate(priceFeed);
        require(ethSent >= minimumVal, "Eth donated can't be less than $10");
        senderToValue[msg.sender] += ethSent;

        if(addressToDonor[msg.sender].donor == address(0)){

            Donor memory newDonor = Donor({
                donor : msg.sender,
                message: "Thank you for donating",
                value : msg.value
            });
            addressToDonor[msg.sender] =  newDonor;
            donors.push(newDonor);
        }
        else{
            addressToDonor[msg.sender].value += msg.value;
        }
        return "Transaction Successful";
    }

    function getAmountDonated(address donor) public view returns (uint256){
        uint256 amount = addressToDonor[donor].value;
        return amount;
    }

    function withdrawAllFunds() public onlyOwner{

        for(uint256 i = 0; i < donors.length; i++){
            address donorAddress = donors[i].donor;

            donors[i].value = 0;
            addressToDonor[donorAddress].value = 0;
        }
        (bool success,) = payable (msg.sender).call{value: address(this).balance}("");
        require(success, "Withdraw operation failed");
    }

    receive() external payable {
        donate();
     }
    fallback() external payable {
        donate();
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}