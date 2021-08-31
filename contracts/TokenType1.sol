// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

contract TokenType1 is TokenBase
{
	using GCLeveragedReserveManager for GCLeveragedReserveManager.Self;

	GCLeveragedReserveManager.Self lrm;

	constructor (string memory _name, string memory _symbol, uint8 _decimals, address _stakesToken, address _reserveToken, address _miningToken)
		TokenBase(_name, _symbol, _decimals, _stakesToken, _reserveToken, _miningToken, address(0)) public
	{
		lrm.init(_reserveToken, _miningToken);
	}

	/**
	 * @notice Overrides the default total reserve definition in order to
	 *         account only for the diference between assets being lent
	 *         and assets being borrowed.
	 * @return _totalReserve The amount of the reserve token corresponding
	 *                       to this contract's worth.
	 */
	function totalReserve() public view override returns (uint256 _totalReserve)
	{
		return GCFormulae._calcCostFromUnderlyingCost(totalReserveUnderlying(), exchangeRate());
	}

	/**
	 * @notice Overrides the default total underlying reserve definition in
	 *         order to account only for the diference between assets being
	 *         lent and assets being borrowed.
	 * @return _totalReserveUnderlying The amount of the underlying asset
	 *                                 corresponding to this contract's worth.
	 */
	function totalReserveUnderlying() public view override returns (uint256 _totalReserveUnderlying)
	{
		return lendingReserveUnderlying().sub(borrowingReserveUnderlying());
	}

	/**
	 * @notice Provides the contract address for the GExchange implementation
	 *         currently being used to convert the mining token (COMP) into
	 *         the underlying asset.
	 * @return _exchange A GExchange compatible contract address, or address(0)
	 *                   if it has not been set.
	 */
	function exchange() public view override returns (address _exchange)
	{
		return lrm.exchange;
	}

	/**
	 * @notice Provides the minimum and maximum amount of the mining token to
	 *         be processed on every operation. If the contract balance
	 *         is below the minimum it waits until more accumulates.
	 *         If the total amount is beyond the maximum it processes the
	 *         maximum and leaves the rest for future operations. The mining
	 *         token accumulated via liquidity mining is converted to the
	 *         underlying asset and used to mint the associated cToken.
	 *         This range is used to avoid wasting gas converting small
	 *         amounts as well as mitigating slipage converting large amounts.
	 * @return _miningMinGulpAmount The minimum amount of the mining token
	 *                              to be processed per deposit/withdrawal.
	 * @return _miningMaxGulpAmount The maximum amount of the mining token
	 *                              to be processed per deposit/withdrawal.
	 */
	function miningGulpRange() public view override returns (uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount)
	{
		return (lrm.miningMinGulpAmount, lrm.miningMaxGulpAmount);
	}

	/**
	 * @notice Provides the minimum and maximum amount of the gcToken Type 1 to
	 *         be processed on every operation. This method applies only to
	 *         gcTokens Type 2 and is not relevant for gcTokens Type 1.
	 * @return _mtcMinGulpAmount The minimum amount of the gcToken Type 1
	 *                              to be processed per deposit/withdrawal
	 *                              (always 0).
	 * @return _mtcMaxGulpAmount The maximum amount of the gcToken Type 1
	 *                              to be processed per deposit/withdrawal
	 *                              (always 0).
	 */
	function mtcGulpRange() public view override returns (uint256 _mtcMinGulpAmount, uint256 _mtcMaxGulpAmount)
	{
		return (0, 0);
	}

	/**
	 * @notice Provides the target collateralization ratio and margin to be
	 *         maintained by this contract. The amount is relative to the
	 *         maximum collateralization available for the associated cToken
	 *         on Compound. gcToken Type 1 uses leveraged collateralization
	 *         where the cToken is used to borrow its underlying token which
	 *         in turn is used to mint new cToken and repeat. This is
	 *         performed to the maximal level where the actual reserve
	 *         ends up corresponding to the difference between the amount
	 *         lent and the amount borrowed.
	 * @param _collateralizationRatio The percent value relative to the
	 *                                maximum allowed that this contract
	 *                                will target for collateralization
	 *                                (defaults to 94%)
	 * @param _collateralizationRatio The percent value relative to the
	 *                                maximum allowed that this contract
	 *                                will target for collateralization
	 *                                margin (defaults to 2%)
	 */
	function collateralizationRatio() public view override returns (uint256 _collateralizationRatio, uint256 _collateralizationMargin)
	{
		return (lrm.collateralizationRatio, lrm.collateralizationMargin);
	}

	/**
	 * @notice Sets the contract address for the GExchange implementation
	 *         to be used in converting the mining token (COMP) into
	 *         the underlying asset. This is a priviledged function
	 *         restricted to the contract owner.
	 * @param _exchange A GExchange compatible contract address.
	 */
	function setExchange(address _exchange) public override onlyOwner nonReentrant
	{
		lrm.setExchange(_exchange);
	}

	/**
	 * @notice Sets the minimum and maximum amount of the mining token to
	 *         be processed on every operation. See miningGulpRange().
	 *         This is a priviledged function restricted to the contract owner.
	 * @param _miningMinGulpAmount The minimum amount of the mining token
	 *                             to be processed per deposit/withdrawal.
	 * @param _miningMaxGulpAmount The maximum amount of the mining token
	 *                             to be processed per deposit/withdrawal.
	 */
	function setMiningGulpRange(uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount) public override onlyOwner nonReentrant
	{
		lrm.setMiningGulpRange(_miningMinGulpAmount, _miningMaxGulpAmount);
	}

	/**
	 * @notice Sets the minimum and maximum amount of the gcToken Type 1 to
	 *         be processed on every operation. This method applies only to
	 *         gcTokens Type 2 and is not relevant for gcTokens Type 1.
	 *         This is a priviledged function restricted to the contract owner.
	 * @param _mtcMinGulpAmount The minimum amount of the gcToken Type 1
	 *                             to be processed per deposit/withdrawal
	 *                             (ignored).
	 * @param _mtcMaxGulpAmount The maximum amount of the gcToken Type 1
	 *                             to be processed per deposit/withdrawal
	 *                             (ignored).
	 */
	function setMtcGulpRange(uint256 _mtcMinGulpAmount, uint256 _mtcMaxGulpAmount) public override /*onlyOwner nonReentrant*/
	{
		_mtcMinGulpAmount; _mtcMaxGulpAmount; // silences warnings
	}

	/**
	 * @notice Sets the target collateralization ratio and margin to be
	 *         maintained by this contract. See collateralizationRatio().
	 *         Setting both parameters to 0 turns off collateralization and
	 *         leveraging. This is a priviledged function restricted to the
	 *         contract owner.
	 * @param _collateralizationRatio The percent value relative to the
	 *                                maximum allowed that this contract
	 *                                will target for collateralization
	 *                                (defaults to 94%)
	 * @param _collateralizationRatio The percent value relative to the
	 *                                maximum allowed that this contract
	 *                                will target for collateralization
	 *                                margin (defaults to 2%)
	 */
	function setCollateralizationRatio(uint256 _collateralizationRatio, uint256 _collateralizationMargin) public override onlyOwner nonReentrant
	{
		lrm.setCollateralizationRatio(_collateralizationRatio, _collateralizationMargin);
	}

	/**
	 * @dev This method is overriden from GTokenBase and sets up the reserve
	 *      after a deposit comes along. It basically adjusts the
	 *      collateralization/leverage to reflect the new increased reserve
	 *      balance. This method uses the GCLeveragedReserveManager to
	 *      adjust the reserve and this is done via flash loans.
	 *      See GCLeveragedReserveManager.sol.
	 * @param _cost The amount of reserve being deposited (ignored).
	 * @return _success A boolean indicating whether or not the operation
	 *                  succeeded. This operation should not fail unless
	 *                  any of the underlying components (Compound, Aave,
	 *                  Dydx) also fails.
	 */
	function _prepareDeposit(uint256 _cost) internal override mayFlashBorrow returns (bool _success)
	{
		_cost; // silences warnings
		return lrm.adjustReserve(0);
	}

	/**
	 * @dev This method is overriden from GTokenBase and sets up the reserve
	 *      before a withdrawal comes along. It basically calculates the
	 *      the amount that will be left in the reserve, in terms of cToken
	 *      cost, and adjusts the collateralization/leverage accordingly. This
	 *      method uses the GCLeveragedReserveManager to adjust the reserve
	 *      and this is done via flash loans. See GCLeveragedReserveManager.sol.
	 * @param _cost The amount of reserve being withdrawn and that needs to
	 *              be immediately liquid.
	 * @return _success A boolean indicating whether or not the operation succeeded.
	 *                  The operation may fail if it is not possible to recover
	 *                  the required liquidity (e.g. low liquidity in the markets).
	 */
	function _prepareWithdrawal(uint256 _cost) internal override mayFlashBorrow returns (bool _success)
	{
		return lrm.adjustReserve(GCFormulae._calcUnderlyingCostFromCost(_cost, GC.fetchExchangeRate(reserveToken)));
	}

	/**
	 * @dev This method dispatches the flash loan callback back to the
	 *      GCLeveragedReserveManager library. See GCLeveragedReserveManager.sol
	 *      and GFlashBorrower.sol.
	 */
	function _processFlashLoan(address _token, uint256 _amount, uint256 _fee, bytes memory _params) internal override returns (bool _success)
	{
		return lrm._receiveFlashLoan(_token, _amount, _fee, _params);
	}
}
