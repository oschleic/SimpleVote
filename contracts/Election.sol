// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Election{
    /*
     *  Storage
     */

    struct Proposal {
        bytes32 name; 
        uint voteCount; 
    }

    uint256 votingRoundStart;

    mapping(address => uint256) public registered;
    mapping(address => uint256) public votes;

    mapping (uint => Proposal) public proposals;
    uint256 public proposalCount;

    Proposal[] passedProposals;

    mapping (address => bool) public isBoard;
    address[] public board;
    

    /*
     *  Modifiers
     */

    modifier onlyBoard() {
        require(isBoard[msg.sender]);
        _;
    }
    modifier boardMember(address newBoard) {
        require(isBoard[newBoard]);
        _;
    }
    modifier notBoardMember(address newBoard) {
        require(!isBoard[newBoard]);
        _;
    }
    modifier notRegistered() {
        require(registered[msg.sender] <= votingRoundStart);
        _;
    }



    constructor(address[] memory boardMembers){
        board = boardMembers;
        votingRoundStart = block.timestamp;
    }


    /*
     *  Public functions
     */

    function addBoardMember(address newBoard) public 
        onlyBoard()
        notBoardMember(newBoard) 
    {
        board.push(newBoard);
        isBoard[newBoard] = true;
    }

    function removeBoardMember(address toRemove) public
        onlyBoard()
        boardMember(toRemove)
    {
        isBoard[toRemove] = false;
        uint256 i = 0;
        while(board[i] != toRemove){
            i++;
        }
        for(i; i < board.length - 1; i++){
            board[i] = board[i + 1];
        }
        board.pop();
    }

    function endVotingRound() public onlyBoard(){
        approveProposal();
        proposalCount = 0;
        votingRoundStart = block.timestamp;
    }

    function createProposal(bytes32 name) public {
        Proposal memory newProp = Proposal(name, 0);
        proposals[proposalCount] = newProp;
        proposalCount++;
    }


    // Transfer proposal votes to a different address
    function transferVote(address to, uint256 numVotes) public {
        require(to != address(0));
        require(votes[msg.sender] >= numVotes);
        votes[msg.sender] -= numVotes;
        votes[to] += numVotes;
    }

    // Vote on a proposal
    function vote(uint256 proposalID, uint256 numVotes) public {
        require(votes[msg.sender] >= numVotes);
        votes[msg.sender] -= numVotes;
        proposals[proposalID].voteCount += numVotes;
    }

    // Register address to vote
    // Note, vulnerable to sybil attacks
    // A production ready setup would assign votes to voters (token based voting etc)
    function registerToVote() public notRegistered() {
        registered[msg.sender] = block.timestamp;
        votes[msg.sender] += 1;
    }


    /*
     *  View functions
     */


    function getProposals() public view returns (Proposal[] memory currentProposals) {
        currentProposals = new Proposal[](proposalCount);
        uint256 i = 0;
        for(i; i < proposalCount; i++){
            currentProposals[i] = proposals[i];
        }
        return currentProposals;
    }

    function getPassedProposals() public view returns (Proposal[] memory _passedProposals){
        _passedProposals = new Proposal[](passedProposals.length);
        uint256 i = 0;
        for(i; i < passedProposals.length; i++){
            _passedProposals[i] = passedProposals[i];
        }
        return _passedProposals;
    }

    function getBoardMembers() public view returns (address[] memory boardMembers){
        boardMembers = new address[](board.length);
        uint256 i = 0;
        for(i; i < board.length; i++){
            boardMembers[i] = board[i];
        }
        return boardMembers;
    }

    /*
     *  Internal functions
     */

    // Internal function used by endVotingRound()
    // Approves the proposal with the most votes
    function approveProposal() internal {
        uint256 i = 0;
        uint256 topProposal;
        uint256 maxVotes = 0;
        for(i; i < proposalCount; i++){
            if(proposals[i].voteCount > maxVotes){
                maxVotes = proposals[i].voteCount;
                topProposal = i;
            }
        }
        passedProposals.push(proposals[i]);
    }
    

    
}