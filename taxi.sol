// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.8.0;

contract taxi{
    struct participant{
        address payable prc;
        uint balance;
        bool approval_buy;
        bool approval_sell;
        bool approval_driver;
    }
    participant[] public participants;
    address public manager;
    struct taxiDriver{
        address payable taxi_driver;
        uint balance;
        uint salary;
        uint approval;
        bool set;
        uint valid_time;
        bool payed;
    }
    taxiDriver public driver;
    address payable public car_dealer;
    uint public contractBalance;
    struct expenses{
        uint expenses_fee;
        uint valid_time;
        bool payed;
    }
    expenses public exp;
    uint constant fee = 10 ether;
    uint32 public OwnedCarID;
    struct ProposedCar{
        uint32 CarID;
        uint price;
        uint valid_time;
        uint approval;
    }
    ProposedCar public p_car;
    struct ProposedRepurchase{
        uint32 OwnedCarID;
        uint price;
        uint valid_time;
        uint approval;
    }
    ProposedRepurchase public p_purc;
    uint public PayDividend_valid_time;
    bool public PayDividend_;
    
    constructor(address m){
        manager = m;
        contractBalance = 0;
        exp = expenses(10 ether, 0, false);
        OwnedCarID = 0;
        PayDividend_valid_time = block.timestamp + (180 * 1 days);
        PayDividend_ = false;
    }
    
    modifier onlyManegar(){
        require(msg.sender == manager);
        _;
    }
    
    modifier onlyCarDealer(){
        require(msg.sender == car_dealer);
        _;
    }
    
    modifier onlyDriver(){
        require(msg.sender == driver.taxi_driver);
        _;
    }
    
    function setContractBalance() private view returns(uint256){
        return address(this).balance;
    }
    
    function Join(address payable participant_) public payable{
        require(participants.length < 9);
        require(msg.value == fee);
        bool flag = true;
        for (uint i = 0; i < participants.length ; i++) {
            if (participants[i].prc == participant_) {
                flag = false;
            }
        }
        require(flag == true);
        participants.push(participant(participant_, 0, false, false, false));
        contractBalance = setContractBalance();
    }
    
    function SetCarDealer(address payable c) public onlyManegar {
        bool flag = true;
        for (uint i = 0; i < participants.length ; i++) {
            if (participants[i].prc == c) {
                flag = false;
            }
        } 
        require(flag == true);
        car_dealer = c;
    }
    
    function CarProposeToBusiness(uint32 CarID, uint price, uint valid_time) public onlyCarDealer{
        require(CarID != 0 && OwnedCarID == 0);
        p_car = ProposedCar(CarID, price * 1 ether, block.timestamp + (valid_time * 1 days), 0);
    }
    
    function ApprovePurchaseCar() public {
        require(p_car.CarID != 0);
        bool flag = false;
        for (uint i = 0 ; i < participants.length ; i++){
            if (participants[i].prc == msg.sender && participants[i].approval_buy == false){
                flag = true;
                participants[i].approval_buy = true;
            }
        }
        require(flag == true);
        p_car.approval += 1;
    }
    
    function PurchaseCar() public payable onlyManegar {
        require(block.timestamp <= p_car.valid_time);
        require(p_car.approval > participants.length/2);
        require(contractBalance >= p_car.price);
        car_dealer.transfer(p_car.price);
        for (uint i = 0; i< participants.length; i++){
            participants[i].approval_buy = false;
        }
        OwnedCarID = p_car.CarID;
        exp.valid_time = block.timestamp + (180 * 1 days);
        p_car = ProposedCar(0, 0, 0, 0);
        contractBalance = setContractBalance();
    }
    
    function RepurchaseCarPropose(uint32 CarID, uint price, uint valid_time) public onlyCarDealer {
        require(CarID == OwnedCarID);
        require(CarID != 0);
        p_purc = ProposedRepurchase(CarID, price * 1 ether, block.timestamp +  (valid_time * 1 days), 0);
    }
    
    function ApproveSellProposal() public {
        require(p_purc.OwnedCarID != 0);
        bool flag = false;
        for (uint i = 0 ; i < participants.length ; i++){
            if (participants[i].prc == msg.sender && participants[i].approval_sell == false){
                flag = true;
                participants[i].approval_sell = true;
            }
        }
        require(flag == true);
        p_purc.approval += 1;
    }
    
    function Repurchasecar() public payable onlyCarDealer {
        require(block.timestamp <= p_purc.valid_time);
        require(p_purc.approval > participants.length/2);
        require(msg.value == p_purc.price);
        for (uint i = 0; i< participants.length; i++){
            participants[i].approval_sell = false;
        }
        OwnedCarID = 0;
        p_purc = ProposedRepurchase(0, 0, 0, 0);
        contractBalance = setContractBalance();
    }
    
    function ProposeDriver(address payable d, uint salary) public onlyManegar {
        require(driver.set == false);
        for (uint i = 0 ; i < participants.length ; i++){
            participants[i].approval_driver = false;
        }
        driver = taxiDriver(d, 0, salary * 1 ether, 0, false, 0, false);
    }
    
    function ApproveDriver() public {
        require(driver.taxi_driver != address(0));
        bool flag = false;
        for (uint i = 0 ; i < participants.length ; i++){
            if (participants[i].prc == msg.sender && participants[i].approval_driver == false){
                flag = true;
                participants[i].approval_driver = true;
            }
        }
        require(flag == true);
        driver.approval += 1;
    }
    
    function SetDriver() public onlyManegar {
        require(driver.approval > participants.length / 2);
        driver.set = true;
        driver.valid_time = block.timestamp + (30 * 1 days);
        for (uint i = 0 ; i < participants.length ; i++){
            participants[i].approval_driver = false;
        }
    }
    
    function FireDriver() public onlyManegar {
        require(driver.set == true);
        require(!(block.timestamp <= driver.valid_time && driver.payed == true));
        driver.balance += driver.salary;
        driver.set = false;
    }
    
    event PayTaxi(address _from, uint _value);
    
    function PayTaxiCharge() public payable {
        emit PayTaxi(msg.sender, msg.value);
        contractBalance = setContractBalance();
    }
    
    function ReleaseSalary() public onlyManegar {
        require(driver.set == true);
        require(!(block.timestamp <= driver.valid_time && driver.payed == true));
        if (block.timestamp > driver.valid_time) {
            driver.valid_time += 30 * 1 days;
        }
        driver.payed = true;
        driver.balance += driver.salary;
    }
    
    function GetSalary() public payable onlyDriver {
        require(driver.balance > 0);
        driver.taxi_driver.transfer(driver.balance);
        driver.balance = 0;
        if (driver.set == false) {
            driver = taxiDriver(address(0), 0, 0, 0, false, 0, false);
        }
        contractBalance = setContractBalance();
    }
    
    function PayCarExpenses() public payable onlyManegar {
        require(!(block.timestamp <= exp.valid_time && exp.payed == true));
        if (block.timestamp > exp.valid_time) {
            exp.valid_time += 180 * 1 days;
        }
        exp.payed = true;
        car_dealer.transfer(exp.expenses_fee);
        contractBalance = setContractBalance();
    }
    
    function PayDividend() public onlyManegar {
        require(block.timestamp <= driver.valid_time && driver.payed == true);
        require(block.timestamp <= exp.valid_time && exp.payed == true);
        require(!(block.timestamp <= PayDividend_valid_time && PayDividend_ == true));
        if (block.timestamp > PayDividend_valid_time) {
            PayDividend_valid_time += 180 * 1 days;
        }
        PayDividend_ = true;
        uint share = (contractBalance - driver.balance) / participants.length;
        for (uint i = 0 ; i < participants.length ; i++){
            participants[i].balance = share;
        }
    }
    
    function GetDividend() public payable {
        bool flag = false;
        uint c_participant;
        for (uint i = 0 ; i < participants.length ; i++){
            if (participants[i].prc == msg.sender){
                c_participant = i;
                flag = true;
                break;
            }
        }
        require(flag == true);
        require(participants[c_participant].balance > 0);
        participants[c_participant].prc.transfer(participants[c_participant].balance);
        participants[c_participant].balance = 0;
        contractBalance = setContractBalance();
    }
    
    fallback() external { 
        revert(); 
    }
    
}
