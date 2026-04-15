// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract HospitalQueue {
    address public owner;
    address payable public hospitalWallet;
    
    // Ma'lum ruxsat etilgan to'lovchi adresi
    address public allowedPayer;
    
    uint256 public constant MIN_FEE = 0.01 ether;
    uint256 public constant VIP_FEE = 0.05 ether;
    
    // Foydalanuvchilar qancha to'lov qilganini saqlovchi mapping
    mapping(address => uint256) public patientBalances;
    mapping(address => bool) public isVipPatient;
    
    event PaymentReceived(address indexed patient, uint256 amount, bool isVip);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }
    
    constructor(address payable _hospitalWallet, address _allowedPayer) {
        owner = msg.sender;
        hospitalWallet = _hospitalWallet;
        allowedPayer = _allowedPayer;
    }
    
    // Asosiy to'lov va navbatga yozilish funksiyasi
    function bookQueue() public payable {
        // 1. Faqat ma'lum adresdan kelgan to'lovni qabul qilish
        require(msg.sender == allowedPayer, "You are not the allowed payer");
        
        // 2. Minimal to'lov miqdorini tekshirish
        require(msg.value >= MIN_FEE, "Payment is below the minimum fee (0.01 ETH)");
        
        // 3. Mapping yordamida balansni saqlash
        patientBalances[msg.sender] += msg.value;
        
        bool vipStatus = false;
        
        // 4. if/else yordamida mantiq: VIP yoki Oddiy navbat
        if (msg.value >= VIP_FEE) {
            isVipPatient[msg.sender] = true;
            vipStatus = true;
            // VIP bemor uchun to'lovning hammasini kasalxonaga o'tkazish
            hospitalWallet.transfer(msg.value);
        } else {
            isVipPatient[msg.sender] = false;
            // Oddiy bemor uchun to'lovning 90% kasalxonaga, 10% kontraktda qoladi
            uint256 transferAmount = (msg.value * 90) / 100;
            hospitalWallet.transfer(transferAmount);
        }
        
        // 5. Event chiqarish
        emit PaymentReceived(msg.sender, msg.value, vipStatus);
    }
    
    // 6. Faqat kontrakt egasi yig'ilib qolgan (masalan 10%) pulni yechib olishi
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Withdrawal failed");
        
        emit FundsWithdrawn(owner, balance);
    }
    
    // Contract balansini ko'rish
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
