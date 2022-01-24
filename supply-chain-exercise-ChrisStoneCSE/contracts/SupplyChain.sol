// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {

  address public owner;
  uint public skuCount;
  // <items mapping>
  mapping(uint256 => Item) public items;
  enum State { ForSale, Sold, Shipped, Received }
  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }
  
  /* 
   * Events
   */

    event LogForSale(uint sku);
    event LogSold(uint sku);
    event LogShipped(uint sku);
    event LogReceived(uint sku);

  /* 
   * Modifiers
   */

  // Create a modifer, `isOwner` that checks if the msg.sender is the owner of the contract
  modifier isOwner {
    require(msg.sender == owner);
    _;
  }

  modifier verifyCaller (address _address) { 
    require (msg.sender == _address); 
    _;
  }

  modifier paidEnough(uint _price) { 
    require(msg.value >= _price); 
    _;
  }

  modifier checkValue(uint _sku) {
    //refund them after pay for item (why it is before, _ checks for logic before func)
    _;
     uint _price = items[_sku].price;
     uint amountToRefund = msg.value - _price;
     items[_sku].buyer.transfer(amountToRefund);
  }

  modifier forSale(uint _sku) {
    require(items[_sku].seller != address(0), "Sku not found.");
    require(items[_sku].state == State.ForSale, "Not for sale");
    require(items[_sku].buyer == address(0), "Buyer already exists");
    _;
  }

  modifier sold(uint _sku) {
    require(items[_sku].state == State.Sold, "Not sold");
    require(items[_sku].buyer != address(0), "No buyer");
    _;
  }

  modifier shipped(uint _sku) {
    require(items[_sku].state == State.Shipped, "Item has not shipped");
    require(items[_sku].buyer != address(0), "No buyer");
    _;
  }
  
  modifier received(uint _sku) {
    require(items[_sku].state == State.Received, "Not received");
    require(items[_sku].buyer != address(0), "No buyer");
    _;
  }

  constructor() public {
    // 1. Set the owner to the transaction sender
    // 2. Initialize the sku count to 0. Question, is this necessary?
     owner = msg.sender;
     skuCount = 0;
  }

  function addItem(string memory _name, uint _price) public returns (bool) {
    // 1. Create a new item and put in array
    items[skuCount] = Item({
    name: _name, 
    sku: skuCount, 
    price: _price, 
    state: State.ForSale, 
    seller: msg.sender, 
    buyer: address(0)
    });
    // 2. Increment the skuCount by one
    skuCount = skuCount + 1;
    // 3. Emit the appropriate event
    emit LogForSale(skuCount);
    // 4. return true
    return true;
  }

  function buyItem(uint sku) public payable forSale(sku) paidEnough(items[sku].price) checkValue(sku) {
    items[sku].buyer = msg.sender;
    items[sku].state = State.Sold;
    (bool sent, ) = items[sku].seller.call.value(items[sku].price)("");
    require(sent, "Transaction Failed.");
    emit LogSold(sku);
  }

  function shipItem(uint sku) public sold(sku) verifyCaller(items[sku].seller) {
    items[sku].state = State.Shipped;
    emit LogShipped(sku);
  }

  function receiveItem(uint sku) public shipped(sku) verifyCaller(items[sku].buyer) {
    items[sku].state = State.Received;
    emit LogReceived(sku);
  }

  // Uncomment the following code block. it is needed to run tests
function fetchItem(uint _sku) public view
  returns (string memory name, uint sku, uint price, uint state, address seller, address buyer)
  {
     name = items[_sku].name;
     sku = items[_sku].sku;
     price = items[_sku].price;
     state = uint(items[_sku].state);
     seller = items[_sku].seller;
     buyer = items[_sku].buyer;
     return (name, sku, price, state, seller, buyer);
   }
}
