pragma solidity ^0.4.24;

contract ERC721Cast {
    function getSerializedData(string _tokenVIN) public view returns(bytes32[]);
    function recoveryToken(string _tokenVIN, bytes32[] data) public;
    function safeTransferFrom(address _from, address _to, string _tokenVIN) public;
}

contract HomeBridge {
    address contractERC721Address;
    // This emits when bridge creation request sent
    event userRequestForSignature(address _reciever, string _tokenVIN, bytes32[] data);
    event transferCompleted(string _tokenVIN);

    constructor(address _contractAddress) public {
        contractERC721Address = _contractAddress;
    }

    function onERC721Received(address _from, address _to, string _tokenVIN, bytes _data) public {
        ERC721Cast(contractERC721Address).safeTransferFrom(_from, _to, _tokenVIN);
        emit userRequestForSignature(_to, _tokenVIN, ERC721Cast(contractERC721Address).getSerializedData(_tokenVIN));
    }

    function transferApproved(address _reciever, string _tokenVIN, bytes32[] _data) public{
        ERC721Cast(contractERC721Address).recoveryToken(_tokenVIN, _data);
        ERC721Cast(contractERC721Address).safeTransferFrom(address(this), _reciever, _tokenVIN);
        emit transferCompleted(_tokenVIN);
    }
}