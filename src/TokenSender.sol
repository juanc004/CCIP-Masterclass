// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

contract CCIPTokenSender is OwnerIsCreator {
    IRouterClient router;
    LinkTokenInterface linkToken;

    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);

    event TokensTransferred(
      bytes32 indexed messageId, // unique ID of the message
      uint64 indexed destinationChainSelector, // The chain selector of destination chain
      address reciever, // address of the receiver on the destination chain
      address token, // token address transferred
      uint256 tokenAmount, // token amount that was transferred
      address feeToken, // the token address used to pay CCIP fees
      uint256 fees  // fees paid for sending the message
    );

    constructor(address _router, address _link) {
      router = IRouterClient(_router);
      linkToken = LinkTokenInterface(_link);
    }

    function transferTokens(
      uint64 _destinationChainSelector,
      address _receiver,
      address _token,
      uint256 _amount
    ) external returns(bytes32 messageId) 
      {
        Client.EVMTokenAmount[] 
          memory tokenAmounts = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({
          token: _token,
          amount: _amount
        });
        tokenAmounts[0] = tokenAmount;

        //Build CCIP Message
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
          receiver: abi.encode(_reciever),
          data: "",
          tokenAmounts: tokenAmounts,
          extraArgs: Client._argsToBytes(
            Client.EVMExtraArgsV1({gasLimit: 0, strict: false})
            ),
            feeToken: address(linkToken)
        });

        // CCIP Fees Management
        uint256 fees = router.getFee(_destinationChainSelector, message);

        if(fees > linkToken.balanceOf(address(this))) 
          revert NotEnoughBalance(linkToken.balanceOf(address(this)), fees);
        
        linkToken.approve(address(router), fees);

        // Approve Router to spend CCIP-BnM tokens we send
        IERC20(_token).approve(address(router), _amount);

        // Send CCIP Message
        messageId = router.ccipSend(_destinationChainSelector,message);

        emit TokensTransferred(
          messageId,
          _destinationChainSelector,
          _receiver,
          _token,
          _amount,
          address(linkToken),
          fees
        );
    }
}