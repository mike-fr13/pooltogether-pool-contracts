pragma solidity ^0.6.4;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "../token/ControlledTokenFactory.sol";
import "../prize-pool/PeriodicPrizePoolFactory.sol";
import "../yield-service/CompoundYieldServiceBuilder.sol";
import "../token/TicketFactory.sol";
import "../external/compound/CTokenInterface.sol";

contract PrizePoolBuilder is Initializable {

  event PrizePoolCreated(
    address indexed creator,
    address indexed prizePool,
    address yieldService,
    address ticket,
    address distributionStrategy,
    uint256 prizePeriodSeconds
  );

  CompoundYieldServiceBuilder public compoundYieldServiceBuilder;
  PeriodicPrizePoolFactory public periodicPrizePoolFactory;
  TicketFactory public ticketFactory;
  ControlledTokenFactory public controlledTokenFactory;
  RNGInterface public rng;

  function initialize (
    CompoundYieldServiceBuilder _compoundYieldServiceBuilder,
    PeriodicPrizePoolFactory _periodicPrizePoolFactory,
    TicketFactory _ticketFactory,
    ControlledTokenFactory _controlledTokenFactory,
    RNGInterface _rng
  ) public initializer {
    require(address(_compoundYieldServiceBuilder) != address(0), "interest pool factory is not defined");
    require(address(_periodicPrizePoolFactory) != address(0), "prize pool factory is not defined");
    require(address(_ticketFactory) != address(0), "ticket factory is not defined");
    require(address(_controlledTokenFactory) != address(0), "controlled token factory is not defined");
    require(address(_rng) != address(0), "rng cannot be zero");
    compoundYieldServiceBuilder = _compoundYieldServiceBuilder;
    periodicPrizePoolFactory = _periodicPrizePoolFactory;
    ticketFactory = _ticketFactory;
    controlledTokenFactory = _controlledTokenFactory;
    rng = _rng;
  }

  function createPeriodicPrizePool(
    CTokenInterface cToken,
    PrizeStrategyInterface _prizeStrategy,
    uint256 prizePeriodSeconds,
    string memory _ticketName,
    string memory _ticketSymbol,
    string memory _sponsorshipName,
    string memory _sponsorshipSymbol
  ) public returns (PrizePool) {
    PeriodicPrizePool prizePool = periodicPrizePoolFactory.createPeriodicPrizePool();

    prizePool.initialize(
      ticketFactory.createTicket(_ticketName, _ticketSymbol, prizePool),
      controlledTokenFactory.createControlledToken(_sponsorshipName, _sponsorshipSymbol, prizePool),
      controlledTokenFactory.createControlledToken(prizePool),
      compoundYieldServiceBuilder.createCompoundYieldService(cToken),
      _prizeStrategy,
      rng,
      prizePeriodSeconds
    );

    emit PrizePoolCreated(
      msg.sender,
      address(prizePool),
      address(prizePool.yieldService()),
      address(prizePool.ticket()),
      address(_prizeStrategy),
      prizePeriodSeconds
    );

    return prizePool;
  }
}