// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { SafeERC20 } from '../../../utils/SafeERC20.sol';
import { IERC20 } from '../../ERC20/IERC20.sol';
import { ERC20BaseInternal } from '../../ERC20/base/ERC20BaseInternal.sol';
import { IERC4626Internal } from '../IERC4626Internal.sol';
import { ERC4626BaseStorage } from './ERC4626BaseStorage.sol';

/**
 * @title Base ERC4626 internal functions
 */
abstract contract ERC4626BaseInternal is IERC4626Internal, ERC20BaseInternal {
    using SafeERC20 for IERC20;

    /**
     * @notice get the address of the base token used for vault accountin purposes
     * @return base token address
     */
    function _asset() internal view virtual returns (address) {
        return ERC4626BaseStorage.layout().asset;
    }

    /**
     * @notice get the total quantity of the base asset currently managed by the vault
     * @return total managed asset amount
     */
    function _totalAssets() internal view virtual returns (uint256);

    /**
     * @notice calculate the quantity of shares received in exchange for a given quantity of assets, not accounting for slippage
     * @param assetAmount quantity of assets to convert
     * @return shareAmount quantity of shares calculated
     */
    function _convertToShares(uint256 assetAmount)
        internal
        view
        virtual
        returns (uint256 shareAmount)
    {
        uint256 supply = _totalSupply();

        if (supply == 0) {
            shareAmount = assetAmount;
        } else {
            uint256 totalAssets = _totalAssets();
            if (totalAssets == 0) {
                shareAmount = assetAmount;
            } else {
                shareAmount = (assetAmount * supply) / totalAssets;
            }
        }
    }

    /**
     * @notice calculate the quantity of assets received in exchange for a given quantity of shares, not accounting for slippage
     * @param shareAmount quantity of shares to convert
     * @return assetAmount quantity of assets calculated
     */
    function _convertToAssets(uint256 shareAmount)
        internal
        view
        virtual
        returns (uint256 assetAmount)
    {
        uint256 supply = _totalSupply();

        if (supply == 0) {
            assetAmount = shareAmount;
        } else {
            assetAmount = (shareAmount * _totalAssets()) / supply;
        }
    }

    /**
     * @notice calculate the maximum quantity of base assets which may be deposited on behalf of given receiver
     * @dev unused address param represents recipient of shares resulting from deposit
     * @return maxAssets maximum asset deposit amount
     */
    function _maxDeposit(address)
        internal
        view
        virtual
        returns (uint256 maxAssets)
    {
        maxAssets = type(uint256).max;
    }

    /**
     * @notice calculate the maximum quantity of shares which may be minted on behalf of given receiver
     * @dev unused address param represents recipient of shares resulting from deposit
     * @return maxShares maximum share mint amount
     */
    function _maxMint(address)
        internal
        view
        virtual
        returns (uint256 maxShares)
    {
        maxShares = type(uint256).max;
    }

    /**
     * @notice calculate the maximum quantity of base assets which may be withdrawn by given holder
     * @param owner holder of shares to be redeemed
     * @return maxAssets maximum asset mint amount
     */
    function _maxWithdraw(address owner)
        internal
        view
        virtual
        returns (uint256 maxAssets)
    {
        maxAssets = _convertToAssets(_balanceOf(owner));
    }

    /**
     * @notice calculate the maximum quantity of shares which may be redeemed by given holder
     * @param owner holder of shares to be redeemed
     * @return maxShares maximum share redeem amount
     */
    function _maxRedeem(address owner)
        internal
        view
        virtual
        returns (uint256 maxShares)
    {
        maxShares = _balanceOf(owner);
    }

    /**
     * @notice simulate a deposit of given quantity of assets
     * @param assetAmount quantity of assets to deposit
     * @return shareAmount quantity of shares to mint
     */
    function _previewDeposit(uint256 assetAmount)
        internal
        view
        virtual
        returns (uint256 shareAmount)
    {
        shareAmount = _convertToShares(assetAmount);
    }

    /**
     * @notice simulate a minting of given quantity of shares
     * @param shareAmount quantity of shares to mint
     * @return assetAmount quantity of assets to deposit
     */
    function _previewMint(uint256 shareAmount)
        internal
        view
        virtual
        returns (uint256 assetAmount)
    {
        uint256 supply = _totalSupply();

        if (supply == 0) {
            assetAmount = shareAmount;
        } else {
            assetAmount = (shareAmount * _totalAssets() + supply - 1) / supply;
        }
    }

    /**
     * @notice simulate a withdrawal of given quantity of assets
     * @param assetAmount quantity of assets to withdraw
     * @return shareAmount quantity of shares to redeem
     */
    function _previewWithdraw(uint256 assetAmount)
        internal
        view
        virtual
        returns (uint256 shareAmount)
    {
        uint256 supply = _totalSupply();

        if (supply == 0) {
            shareAmount = assetAmount;
        } else {
            uint256 totalAssets = _totalAssets();

            if (totalAssets == 0) {
                shareAmount = assetAmount;
            } else {
                shareAmount =
                    (assetAmount * supply + totalAssets - 1) /
                    totalAssets;
            }
        }
    }

    /**
     * @notice simulate a redemption of given quantity of shares
     * @param shareAmount quantity of shares to redeem
     * @return assetAmount quantity of assets to withdraw
     */
    function _previewRedeem(uint256 shareAmount)
        internal
        view
        virtual
        returns (uint256 assetAmount)
    {
        assetAmount = _convertToAssets(shareAmount);
    }

    /**
     * @notice execute a deposit of assets on behalf of given address
     * @param assetAmount quantity of assets to deposit
     * @param receiver recipient of shares resulting from deposit
     * @return shareAmount quantity of shares to mint
     */
    function _deposit(uint256 assetAmount, address receiver)
        internal
        virtual
        returns (uint256 shareAmount)
    {
        require(
            assetAmount <= _maxDeposit(receiver),
            'ERC4626: maximum amount exceeded'
        );

        shareAmount = _previewDeposit(assetAmount);

        _deposit(msg.sender, receiver, assetAmount, shareAmount);
    }

    /**
     * @notice execute a minting of shares on behalf of given address
     * @param shareAmount quantity of shares to mint
     * @param receiver recipient of shares resulting from deposit
     * @return assetAmount quantity of assets to deposit
     */
    function _mint(uint256 shareAmount, address receiver)
        internal
        virtual
        returns (uint256 assetAmount)
    {
        require(
            shareAmount <= _maxMint(receiver),
            'ERC4626: maximum amount exceeded'
        );

        assetAmount = _previewMint(shareAmount);

        _deposit(msg.sender, receiver, assetAmount, shareAmount);
    }

    /**
     * @notice execute a withdrawal of assets on behalf of given address
     * @param assetAmount quantity of assets to withdraw
     * @param receiver recipient of assets resulting from withdrawal
     * @param owner holder of shares to be redeemed
     * @return shareAmount quantity of shares to redeem
     */
    function _withdraw(
        uint256 assetAmount,
        address receiver,
        address owner
    ) internal virtual returns (uint256 shareAmount) {
        require(
            assetAmount <= _maxWithdraw(owner),
            'ERC4626: maximum amount exceeded'
        );

        shareAmount = _previewWithdraw(assetAmount);

        _withdraw(msg.sender, receiver, owner, assetAmount, shareAmount);
    }

    /**
     * @notice execute a redemption of shares on behalf of given address
     * @param shareAmount quantity of shares to redeem
     * @param receiver recipient of assets resulting from withdrawal
     * @param owner holder of shares to be redeemed
     * @return assetAmount quantity of assets to withdraw
     */
    function _redeem(
        uint256 shareAmount,
        address receiver,
        address owner
    ) internal virtual returns (uint256 assetAmount) {
        require(
            shareAmount <= _maxRedeem(owner),
            'ERC4626: maximum amount exceeded'
        );

        assetAmount = _previewRedeem(shareAmount);

        _withdraw(msg.sender, receiver, owner, assetAmount, shareAmount);
    }

    /**
     * @notice ERC4626 hook, called deposit and mint actions
     * @dev function should be overridden and new implementation must call super
     * @param receiver recipient of shares resulting from deposit
     * @param assetAmount quantity of assets being deposited
     * @param shareAmount quantity of shares being minted
     */
    function _afterDeposit(
        address receiver,
        uint256 assetAmount,
        uint256 shareAmount
    ) internal virtual {}

    /**
     * @notice ERC4626 hook, called before withdraw and redeem actions
     * @dev function should be overridden and new implementation must call super
     * @param owner holder of shares to be redeemed
     * @param assetAmount quantity of assets being withdrawn
     * @param shareAmount quantity of shares being redeemed
     */
    function _beforeWithdraw(
        address owner,
        uint256 assetAmount,
        uint256 shareAmount
    ) internal virtual {}

    /**
     * @notice exchange assets for shares on behalf of given address
     * @param caller supplier of assets to be deposited
     * @param receiver recipient of shares resulting from deposit
     * @param assetAmount quantity of assets to deposit
     * @param shareAmount quantity of shares to mint
     */
    function _deposit(
        address caller,
        address receiver,
        uint256 assetAmount,
        uint256 shareAmount
    ) private {
        IERC20(_asset()).safeTransferFrom(caller, address(this), assetAmount);

        _mint(receiver, shareAmount);

        _afterDeposit(receiver, assetAmount, shareAmount);

        emit Deposit(caller, receiver, assetAmount, shareAmount);
    }

    /**
     * @notice exchange shares for assets on behalf of given address
     * @param caller transaction operator for purposes of allowance verification
     * @param receiver recipient of assets resulting from withdrawal
     * @param owner holder of shares to be redeemed
     * @param assetAmount quantity of assets to withdraw
     * @param shareAmount quantity of shares to redeem
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assetAmount,
        uint256 shareAmount
    ) private {
        if (caller != owner) {
            uint256 allowance = _allowance(owner, caller);

            require(
                allowance >= shareAmount,
                'ERC4626: share amount exceeds allowance'
            );

            unchecked {
                _approve(owner, caller, allowance - shareAmount);
            }
        }

        _beforeWithdraw(owner, assetAmount, shareAmount);

        _burn(owner, shareAmount);

        IERC20(_asset()).safeTransfer(receiver, assetAmount);

        emit Withdraw(caller, receiver, owner, assetAmount, shareAmount);
    }
}