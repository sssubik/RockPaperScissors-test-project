const { expect, assert } = require('chai');
const { artifacts, ethers } = require('hardhat');


describe('Rock Paper Scissors Contract',  () => {
    let Token, token, RPS, rps;

    beforeEach(async () => {
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
        Token = await ethers.getContractFactory('RPSToken');
        token =  await Token.deploy(5000);
        RPS = await ethers.getContractFactory('RockPaperScissor');
        rps = await RPS.deploy(token.address);
        await token.connect(owner).transfer(addr1.address, 100);
        await token.connect(addr1).approve(rps.address,100)
        await token.connect(owner).transfer(addr2.address, 100);
        await token.connect(addr2).approve(rps.address,100)
    })

    
    it('should create game', async () => {
        await token.connect(owner).transfer(addr1.address, 100);
        await rps.createGame(10, addr1.address, 8556);
            
     })

    it('should play the game', async() =>{
        var tx = await rps.createGame(10, addr1.address, 8556);
        var rc = await tx.wait()
        var event = rc.events.find(event => event.event == 'GameCreated')
        var [,,gameId] = event.args
        gameId = gameId.toNumber()
        
        var tx = await rps.connect(addr2).joinGame(gameId)
        var rc = await tx.wait()
        var event = rc.events.find(event => event.event == 'JoinedGame')
        console.log(event.args)


        await rps.connect(addr1).commit(gameId, 1, 25);
        await rps.connect(addr2).commit(gameId,2,25);
        await rps.connect(addr1).checkWinner(gameId, 1, 25)
        console.log(await rps.balanceOf(addr1.address))
        console.log(await rps.balanceOf(addr2.address))
    })
    

})
