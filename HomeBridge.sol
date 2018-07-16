pragma solidity ^0.4.24;

contract ERC721Cast {
    function getSerializedData(string _tokenVIN) public view returns(bytes32[]);
    function recoveryToken(string _tokenVIN, bytes32[] data) public;
    function safeTransferFrom(address _from, address _to, string _tokenVIN) public;
}

contract HomeBridge {
    address contractERC721Address;
    mapping(address => bool) validators;
    mapping(bytes32 => bool) validatorAlreadyHandled;
    mapping(bytes32 => bool) tokenRecovered;
    mapping(bytes32 => uint) signaturesCollected;
    uint requiredSignatures;
    // This emits when bridge creation request sent
    event userRequestForSignature(address _reciever, string _tokenVIN, bytes32[] data);
    event transferCompleted(string _tokenVIN);

    constructor(address _contractAddress, address[] _validators, uint _requiredSignatures) public {
        contractERC721Address = _contractAddress;
        for (uint i=0; i<_validators.length; i++) {
           validators[_validators[i]] = true;
        }
        requiredSignatures = _requiredSignatures;
    }

    function onERC721Received(address _from, address _to, string _tokenVIN, bytes _data) public {
        ERC721Cast(contractERC721Address).safeTransferFrom(_from, _to, _tokenVIN);
        emit userRequestForSignature(_to, _tokenVIN, ERC721Cast(contractERC721Address).getSerializedData(_tokenVIN));
    }

    function transferApproval(address _reciever, string _tokenVIN, bytes32[] _data, string txHash) public {
        require(isValidator(msg.sender));
        bytes32 hash = keccak256(abi.encodePacked(_reciever, _tokenVIN, _data, txHash));
        bytes32 sender_hash = keccak256(abi.encodePacked(hash,msg.sender));
        require(!validatorAlreadyHandled[sender_hash]);
        signaturesCollected[hash]+=1;
        require(signaturesCollected[hash]>=requiredSignatures);
        require(!tokenRecovered[hash]);
        ERC721Cast(contractERC721Address).recoveryToken(_tokenVIN, _data);
        tokenRecovered[hash] = true;
        ERC721Cast(contractERC721Address).safeTransferFrom(address(this), _reciever, _tokenVIN);
        emit transferCompleted(_tokenVIN);
    }

    function isValidator(address _validator) private view returns (bool) {
        return validators[_validator];
    }
}