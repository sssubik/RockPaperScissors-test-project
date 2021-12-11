//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "hardhat/console.sol";

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract RockPaperScissor{
    uint256 public gameId = 0;
    IERC20 token;

    mapping(uint => Game) games;
    mapping(address => uint) playerBalances;

    enum GameStatus {
        Created,
        Started,
        Commited,
        Picked,
        Finished,
        Cancelled
    }
  
    
    struct Game{
        address playerA;
        address playerB;
        uint amount;
        mapping(address => bytes32) hashPlayers;
        mapping(address => uint) moves;
        uint endTime;
        
        GameStatus status;
    }

    event GameCreated(address playerA, uint amount, uint gameId);
    event JoinedGame(address playerB, GameStatus status);

    constructor(address _token){
        token = IERC20(_token);
    }
    
    function _gameExists(uint _gameId) internal view{
        Game storage game = games[_gameId];
        
        
        require(game.playerA != address(0) && game.playerB != address(0),'sorry one address is null');
    }
    function createGame(uint _amount, address _playerA, uint _timePeriod) public
    
    {   
        
        Game storage game = games[gameId];
        require(_amount > 0, 'No free games are allowed');
        require(token.balanceOf(_playerA) >= _amount, 'Sorry you dont have enough tokens');
        token.transferFrom(_playerA, address(this), _amount);
        game.playerA = _playerA;
        
        game.endTime = block.timestamp + _timePeriod; 
        game.amount = _amount;
        game.status = GameStatus.Created;
        
        
        emit GameCreated(_playerA, _amount, gameId);
        gameId++;
    }

    function joinGame(uint _gameId) public
    {
        Game storage game = games[_gameId];
        
        require(msg.sender != game.playerA, "You cant play with yourself");
        require(game.playerB == address(0), "Sorry no slot for this game");
        require(game.status == GameStatus.Created);
        require(token.balanceOf(msg.sender) >= game.amount, 'Sorry you dont have enough tokens');
        token.transferFrom(msg.sender, address(this), game.amount);

        game.playerB = msg.sender;
        
        game.status = GameStatus.Started;
        
        emit JoinedGame(game.playerB, game.status);
    }


    // 1 = rock
    // 2 = paper
    // 3 = scissors
    function commit(uint _gameId, uint _move, uint _seed) public{

        require(_move == 1 || _move == 2|| _move ==3);
        
        Game storage game = games[_gameId];
        
        _gameExists(_gameId);
        require(game.endTime >= block.timestamp);
        
        //require(game.status == GameStatus.Started);
        require(game.playerA == msg.sender || game.playerB == msg.sender);
        game.hashPlayers[msg.sender] = keccak256(abi.encodePacked(_move,_seed,msg.sender));
        game.moves[msg.sender] = _move;
        game.status = GameStatus.Commited;
    }
    
    function checkWinner(uint _gameId, uint _move, uint _seed) public{
        Game storage game = games[_gameId];
        require(game.status == GameStatus.Commited);
      
        bytes32 playerHash1 = game.hashPlayers[game.playerA];
        bytes32 playerHash2 = game.hashPlayers[game.playerB];
        bytes32 callerHash;
        require(msg.sender == game.playerA || msg.sender == game.playerB, "only players can check winner");
        
        if(msg.sender == game.playerA){
            callerHash = keccak256(abi.encodePacked(_move, _seed, game.playerA));
            require(callerHash == playerHash1, 'Sorry the move does not match');
        }else{
            callerHash = keccak256(abi.encodePacked(_move, _seed, game.playerB));
            require(callerHash == playerHash2, 'Sorry the move does not match');
        }
        game.status = GameStatus.Picked;
        _resolveWinners(_gameId);
        game.status = GameStatus.Finished;
    }
    // 
    function _resolveWinners(uint _gameId) internal{ 
        Game storage game = games[_gameId];
        require(game.status == GameStatus.Picked);

        uint move_playerA = game.moves[game.playerA];
        uint move_playerB = game.moves[game.playerB];

        uint price = game.amount * 2;

        if(move_playerA == move_playerB){
          
            _pay(game.amount, game.playerA);
            _pay(game.amount, game.playerB);
            
        }else if((move_playerA == 1 && move_playerB == 3)
                ||(move_playerA == 2 && move_playerB == 1)
                ||(move_playerA == 3 && move_playerB == 2)    
        ){
            _pay(price,game.playerA);
        }
        else{
            _pay(price, game.playerB);
        }
    }

    function _pay(uint _amount, address player) internal{
        playerBalances[player] = playerBalances[player] + _amount;

    }
    function withdraw(uint _amount) public{
        require(playerBalances[msg.sender] >= _amount, "Amount is too high");
        require(_amount > 0);
        playerBalances[msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);
    }

    function cancelGame(uint _gameId) public {
        Game storage game = games[_gameId];
        require(game.status == GameStatus.Started || game.status == GameStatus.Created);
        game.status = GameStatus.Cancelled;
    }

    function balanceOf(address player) public view returns(uint){
        return playerBalances[player];
    }
}