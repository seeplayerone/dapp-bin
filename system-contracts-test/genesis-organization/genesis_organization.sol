pragma solidity 0.4.25;

import "github.com/seeplayerone/dapp-bin/library/acl.sol";
import "github.com/seeplayerone/dapp-bin/library/SafeMath.sol";

interface ConsensusMining {
    function getValidatorPower(address validatorAddress, uint finalHeight) external view returns(uint);
    function depositToSpecificAddress(address receiver, uint day, uint amount) external;
}

/// @title This is smart contract which represents the Genesis Organization of flow
///  Note the design of this organization is subjected to change in the near future
///  Right now we adopt the simplest design in which there are a group of members with equal rights
contract GenesisOrganization is ACL {
    address constant delegateAddr = 0x630000000000000000000000000000000000000064;
    bool private initialized;

    /// 届
    uint private round;
    /// 每轮开始时间
    uint private roundStartTime;
    /// 每轮开始高度
    uint private roundStartHeight;
    /// 选举记录自增索引
    uint private electRecordIndex;
    /// 提议记录自增索引
    uint private proposalIndex;

    /// 操作类型，用来控制报名理事，选举等行为可操作的区间
    enum OperateType {SIGN_UP_MEMBER, ELECT_MEMBER, SIGN_UP_PERMANENT_MEMBER, SIGN_UP_DIRECTOR, ELECT_PERMANENT_AND_DIRECTOR, TAKE_OFFICE}
    /// 岗位类型 没有职位、理事、常任理事、理事长
    enum PositionType {NO_POSITION, MEMBER, PERMANENT_MEMBER, DIRECTOR}
    /// 提议状态 {进行中，已生效，已失效}
    enum ProposalStatus {ONGOING, APPROVED, REJECTED}
    /// 提议类型 {预留Asim分配，卸任}
    enum ProposalType {DEPOSIT, RESIGN}

    /// 公民
    struct Citizen {
        /// 总声望，每个周期末尾统计获得
        uint totalPrestige;
        /// 报名声望值
        uint signUpPrestige;
        /// 投票给自己声望值
        uint electToSelfPrestige;
        /// 被投票获得的声望值
        uint electInPrestige;
        /// 投票出去的声望值
        uint electOutPrestige;
        /// 被投票的记录id
        uint[] electInRecordIds;
        /// 投票出去的记录id
        uint[] electOutRecordIds;
        /// 我发起的提议
        uint[] myProposals;
        /// 我投票过的提议
        uint[] myVotedProposals;
        /// 已投票的准常任理事名单
        address[] votedPermanentMembers;
        /// 已投票的理事长
        address votedDirector;
        /// 已经投票参与过的提议集合，用于重复投票校验
        /// proposalId => bool
        mapping(uint => bool) votedProposals;
        /// 身处职位
        PositionType position;
        /// 是否存在该成员
        bool existed;
    }

    /// 选举投票记录
    struct ElectRecord {
        /// 被选举人地址
        address elector;
        /// 投票时间
        uint timestamp;
        /// 该笔投票的声望值
        uint prestige;
        /// 是否存在该笔投票记录
        bool existed;
    }

    /// 提议记录
    struct Proposal {
        /// 发起人
        address proposer;
        /// 参与投票的人
        address[] voters;
        /// 赞成的人
        address[] approvers;
        /// 反对的人
        address[] rejecters;
        /// 收钱地址
        address receiver;
        /// 投票人是否有权利校验map
        mapping(address => bool) voterRight;
        /// 金额
        uint amount;
        /// 质押天数
        uint depositLength;
        /// 通过百分比
        uint percent;
        /// 此次投票总声望
        uint totalPrestige;
        /// 已投票的声望和
        uint votedPrestige;
        /// 投反对票的声望总和
        uint rejectPrestige;
        /// 开始时间
        uint startTime;
        /// 理事长开始表决时间
        uint directorStartTime;
        /// 结束时间
        uint endTime;
        /// 提议类型
        ProposalType proposalType;
        /// proposal status
        ProposalStatus status;
        /// 是否需要理事长一票否决
        bool directorVote;
        /// 理事长是否否决该提议，仅当提议需要理事长表决的时候
        bool directorReject;
        /// whether the Proposal exists
        bool existed;
    }

    /// address => Citizen
    mapping(address => Citizen) citizens;
    /// electRecordId => ElectRecord
    mapping(uint => ElectRecord) electRecords;
    /// proposalId => Proposal
    mapping(uint => Proposal) proposals;
    /// 已经报名理事的成员，用于重复校验
    mapping(address => bool) signedUpMembers;
    /// 已经报名常任理事的成员，用于重复校验
    mapping(address => bool) signedUpPermanentMembers;
    /// 已经报名理事长的成员，用于重复校验
    mapping(address => bool) signedUpDirectors;

    /// 理事可发起的提议
    ProposalType[] memberProposals;
    /// 常任理事可发起的提议
    ProposalType[] permanentMemberProposals;
    /// 理事长可发起的提议
    ProposalType[] directorProposals;
    /// 理事可投票的提议
    ProposalType[] memberVotes;
    /// 常任理事可投票的提议
    ProposalType[] permanentVotes;
    /// 理事长可投票的提议
    ProposalType[] directorVotes;

    /// 理事
    address[] members;
    /// 常任理事
    address[] permanentMembers;
    /// 理事长
    address director;

    /// 候选理事名单
    address[] candidateMembers;
    /// 候选常任理事名单
    address[] candidatePermanentMembers;
    /// 候选理事长名单
    address[] candidateDirectors;

    /// 报名理事名单
    address[] signUpMembers;
    /// 报名常任理事名单
    address[] signUpPermanentMembers;
    /// 报名理事长名单
    address[] signUpDirectors;

    /// ASCoin
    uint private ASCoin;
    /// 报名理事最少的声望
    uint private MemberThreshold;
    /// 报名常任理事最少的声望
    uint private PermanentMemberThreshold;
    /// 报名理事长最少的声望
    uint private DirectorThreshold;
    /// 最小理事人数
    uint private MinimumMemberLength;
    /// 每轮时间跨度，默认180天，计量单位为秒，可配置
    uint private RoundLength;

    /// 共识挖矿系统合约
    ConsensusMining consensusMining;

    /// 捐赠
    event ReceiveEvent(address donator, uint assetType, uint amount);
    /// 报名事件
    event FoundationSignUpEvent(uint round, address member, PositionType positionType, uint prestige);
    /// 投票选举成员事件
    event ElectEvent(uint round, address from, address to, uint prestige);
    /// 转移资产事件
    event TransferAssetEvent(address receiver, ProposalType proposalType, uint assetType, uint amount);
    /// 全体成员上任事件。参数分别为：轮数、每轮开始时间、每轮结束时间、报名理事结束时间、选举理事结束时间、上任开始时间、理事长、常任理事、理事
    event TakeOfficeEvent(uint round, uint startTime, uint endTime, uint signUpMemberEndTime, uint electMemberEndTime,
        uint takeOfficeStartTime, address director, address[] permanentMembers, address[] members);
    /// 成员卸任事件
    event ResignEvent(uint round, address oldMember, address newMember, PositionType positionType);
    /// 发起提议事件
    event StartProposalEvent(uint round, uint proposalId, ProposalType proposalType, address proposer);
    /// 成员待投票提议事件
    event VotingProposalEvent(uint round, address[] voters, uint proposalId);
    /// 理事长一票否决事件
    event DirectorVoteEvent(uint round, uint proposalId, address director);
    /// 成员已参与提议投票事件
    event VoteEvent(uint round, uint proposalId, address voter, bool decision);
    /// 提议状态码变更事件
    event ProposalStatusChangeEvent(uint round, uint proposalId, ProposalStatus status);

    function() public payable {
        emit ReceiveEvent(msg.sender, msg.assettype, msg.value);
    }

    /**
     * @dev 初始化创世组织的理事长、常任理事人员，以及一些状态变量
     *
     * @param _director 理事长
     * @param _permanentMembers 常任理事
     */
    function init(address _director, address[] _permanentMembers) public {
        require(!initialized, "it is not allowed to init more than once");
        require(msg.sender == 0x66dbdd2826fb068f2929af065b04c0804d0397b09e, "invalid caller address");
        require(_permanentMembers.length == 5, "there must be five permanent Members");

        for (uint i = 0; i < _permanentMembers.length; i++) {
            Citizen storage citizen = citizens[_permanentMembers[i]];
            citizen.position = PositionType.PERMANENT_MEMBER;
            citizen.existed = true;
        }
        Citizen storage m = citizens[_director];
        m.position = PositionType.DIRECTOR;
        m.existed = true;
        
        director = _director;
        permanentMembers = _permanentMembers;

        round = 1;
        roundStartTime = block.timestamp;
        roundStartHeight = block.number;
        initialized = true;
        consensusMining = ConsensusMining(0x63000000000000000000000000000000000000006a);
        ASCoin = 0x000000000000000000000000;
        MemberThreshold = 10000000;
        PermanentMemberThreshold = 25000000;
        DirectorThreshold = 50000000;
        MinimumMemberLength = 6;
        RoundLength = 180*24*60*60;

        directorProposals.push(ProposalType.DEPOSIT);
        permanentVotes.push(ProposalType.DEPOSIT);
    }

    /// 临时测试方法，用于调整每轮选举的跨度，单位为秒
    function updateRoundLength(uint length) public {
        require(length > 0, "invalid param of length");
        RoundLength = length;
        roundStartTime = block.timestamp;
        roundStartHeight = block.number;
    }

    function getRoundLength() public view returns(uint) {
        return RoundLength;
    }

    /**
     * @dev 报名成为准理事
     *
     * 每个周期的前2/6区间进行
     */
    function signUpMember(address[] callers) public {
        // checkValidOperateInterval(OperateType.SIGN_UP_MEMBER);
        for (uint i = 0; i < callers.length; i++) {
            require(!signedUpMembers[callers[i]], "you have signed up");
        
            uint power = getValidPower();
            Citizen storage candidate = citizens[callers[i]];
            require(power >= MemberThreshold, "you don't have enough prestige to sign up");

            candidate.signUpPrestige = MemberThreshold;
            candidate.existed = true;
            signUpMembers.push(callers[i]);
            signedUpMembers[callers[i]] = true;

            emit FoundationSignUpEvent(round, callers[i], PositionType.MEMBER, MemberThreshold);
        }
    }

    /**
     * @dev 投票选举准理事
     *
     * 全名投票，默认可以投票给自己
     *
     * @param to 被投票人
     * @param prestigeValue 声望值
     */
    function electMember(address[] to, uint[] prestigeValue) public {
        // checkValidOperateInterval(OperateType.ELECT_MEMBER);
        for (uint i = 0; i < to.length; i++) {
            require(signUpMembers.length >= MinimumMemberLength, "minimum size of member is six");
            require(prestigeValue[i] > 0, "invalid param of prestigeValue");
            uint power = getValidPower();

            Citizen storage candidate = citizens[to[i]];
            require(candidate.existed, "the address you electing to is invalid");
            require(signedUpMembers[to[i]], "the address you electing to hasn't signed up");

            /// 生成选举记录
            uint electRecordId = electRecordIndex+1;
            ElectRecord storage record = electRecords[electRecordId];
            record.elector = to[i];
            record.timestamp = block.timestamp;
            record.prestige = prestigeValue[i];
            record.existed = true;
            electRecordIndex++;

            Citizen storage voter = citizens[msg.sender];
            if (voter.existed) {
                /// 剩余有效声望值计算公式为：总的有效声望-投票出去的声望-投给自己的声望-报名准理事消耗的声望
                uint validPrestige = SafeMath.sub(
                    SafeMath.sub(SafeMath.sub(power, voter.electOutPrestige), voter.signUpPrestige), 
                    voter.electToSelfPrestige
                );
                require(validPrestige >= prestigeValue[i], "you don't have enough prestige to elect");
            } else {
                require(power >= prestigeValue[i], "you don't have enough prestige to elect");
            }

            /// 投票给自己
            if (msg.sender == to[i]) {
                voter.electToSelfPrestige = SafeMath.add(voter.electToSelfPrestige, prestigeValue[i]);
            } else {
                candidate.electInPrestige = SafeMath.add(candidate.electInPrestige, prestigeValue[i]);
                candidate.electInRecordIds.push(electRecordId);
            }
            voter.electOutPrestige = SafeMath.add(voter.electOutPrestige, prestigeValue[i]);
            voter.electOutRecordIds.push(electRecordId);
            voter.existed = true;

            emit ElectEvent(round, msg.sender, to[i], prestigeValue[i]);
        }
    }

    /**
     * @dev 报名成为准常任理事，由准理事报名
     *
     * 每个周期的后1/6区间进行
     */
    function signUpPermanentMember(address[] callers) public {
        // checkValidOperateInterval(OperateType.SIGN_UP_PERMANENT_MEMBER);
        require(signUpMembers.length >= MinimumMemberLength, "minimum size of member is six");
        require(hasQualification(callers[i]), "you don't have qualification to sign up");
        for (uint i = 0; i < callers.length; i++) {
            require(!signedUpPermanentMembers[callers[i]], "you have signed up");

            Citizen storage candidate = citizens[callers[i]];
            require(candidate.existed, "candidate is not existing");
            
            /// 准常任理事与准理事报名门槛的差值
            uint extraPrestige = SafeMath.sub(PermanentMemberThreshold, MemberThreshold);
            /// 剩余有效声望值计算公式为：总的有效声望-投票出去的声望-投给自己的声望-报名准常任理事比准理事额外消耗的声望
            uint validPrestige = SafeMath.sub(
                SafeMath.sub(SafeMath.sub(getValidPower(), candidate.electOutPrestige), candidate.electToSelfPrestige), 
                candidate.signUpPrestige
            );
            require(validPrestige >= extraPrestige, "you don't have enough prestige to sign up");
            
            candidate.signUpPrestige = PermanentMemberThreshold;
            signUpPermanentMembers.push(callers[i]);
            signedUpPermanentMembers[callers[i]] = true;

            emit FoundationSignUpEvent(round, callers[i], PositionType.PERMANENT_MEMBER, extraPrestige);
        }
    }

    /**
     * @dev 报名成为准理事长，由准理事报名
     *
     * 每个周期的后1/6区间进行
     */
    function signUpDirector(address caller) public {
        // checkValidOperateInterval(OperateType.SIGN_UP_DIRECTOR);
        require(signUpMembers.length >= MinimumMemberLength, "minimum size of member is six");
        require(hasQualification(caller), "you don't have qualification to sign up");
        require(!signedUpDirectors[caller], "you have signed up");

        Citizen storage candidate = citizens[caller];
        require(candidate.existed, "candidate is not existing");

        /// 准理事长与准理事报名门槛的差值
        uint extraPrestige = SafeMath.sub(DirectorThreshold, MemberThreshold);
        /// 剩余有效声望值计算公式为：总的有效声望-投票出去的声望-投给自己的声望-报名准理事长比准理事额外消耗的声望
        uint validPrestige = SafeMath.sub(
            SafeMath.sub(SafeMath.sub(getValidPower(), candidate.electOutPrestige), candidate.electToSelfPrestige), 
            candidate.signUpPrestige
        );
        require(validPrestige >= extraPrestige, "you don't have enough prestige to sign up");
        
        candidate.signUpPrestige = DirectorThreshold;
        signUpDirectors.push(caller);
        signedUpDirectors[caller] = true;

        emit FoundationSignUpEvent(round, caller, PositionType.DIRECTOR, extraPrestige);
    }

    /**
     * @dev 投票选举准理事长和准常任理事
     * 
     * 一部分准理事报名了准常任理事和准理事长后，剩下的准理事负责投票
     * @param to 被投票人
     * @param prestigeValue 声望值
     */
    function electPermanentAndDirector(address caller, address to, uint prestigeValue) public {
        // checkValidOperateInterval(OperateType.ELECT_PERMANENT_AND_DIRECTOR);
        require(hasQualification(caller), "you don't have qualification to elect");
        require(!signedUpPermanentMembers[caller] && !signedUpDirectors[caller], "you don't have qualification to elect");
        require(prestigeValue > 0, "invalid param of prestigeValue");
        require(signedUpPermanentMembers[to] || signedUpDirectors[to], "the address you electing for hasn't signed up");

        Citizen storage voter = citizens[caller];
        require(voter.existed, "voter is not existing");

        /// 每个投票人最多只能投票给5个不同的准常任理事
        uint length = voter.votedPermanentMembers.length;
        if (signedUpPermanentMembers[to]) {
            if (length == 0) {
                voter.votedPermanentMembers.push(to);
            } else {
                bool voted;
                for (uint i = 0; i < length; i++) {
                    if (to == voter.votedPermanentMembers[i]) {
                        voted = true;
                        break;
                    }
                }
                if (!voted) {
                    require(length < 5, "it's not allowed to vote more than five different permanent members");
                    voter.votedPermanentMembers.push(to);
                }
            }
        }
        /// 每个投票人最多只能投票给一个准理事长
        if (signedUpDirectors[to] && voter.votedDirector != 0x0) {
            if (voter.votedDirector == 0x0) {
                voter.votedDirector = to;
            } else {
                require(voter.votedDirector == to, "it's not allowed to vote more than one director");
            }
        }

        /// 剩余有效声望值计算公式为：总的有效声望-投票出去的声望-投给自己的声望-报名准理事消耗的声望
        uint validPower = SafeMath.sub(
            SafeMath.sub(SafeMath.sub(getValidPower(), voter.electOutPrestige), voter.signUpPrestige), 
            voter.electToSelfPrestige
        );
        require(validPower >= prestigeValue, "you don't have enough prestige to elect");

        Citizen storage candidate = citizens[to];
        require(candidate.existed, "the address you electing to is invalid");

        /// 生成选举记录
        uint electRecordId = electRecordIndex+1;
        ElectRecord storage electRecord = electRecords[electRecordId];
        electRecord.elector = to;
        electRecord.timestamp = block.timestamp;
        electRecord.prestige = prestigeValue;
        electRecord.existed = true;
        electRecordIndex++;

        voter.electOutPrestige = SafeMath.add(voter.electOutPrestige, prestigeValue);
        voter.electOutRecordIds.push(electRecordId);
        candidate.electInPrestige = SafeMath.add(candidate.electInPrestige, prestigeValue);
        candidate.electInRecordIds.push(electRecordId);

        emit ElectEvent(round, caller, to, prestigeValue);
    }

    function getMyVotedPermanentAndDirector() public returns(address[], address) {
        Citizen storage c = citizens[msg.sender];
        return (c.votedPermanentMembers, c.votedDirector);
    }

    /// 是否有报名常任理事、理事长或者选举的资格
    function hasQualification(address caller) internal view returns(bool) {
        bool result;
        if (signedUpMembers[caller]) {
            address[] memory tempMembers = sortMembers(signUpMembers);
            uint length = tempMembers.length;
            if (length >= MinimumMemberLength && length <= 99) {
                result = true;
            }
            if (length > 99 && calCitizenTotalPrestige(caller) >= calCitizenTotalPrestige(tempMembers[98])) {
                result = true;
            }
        }
        return result;
    }

    /**
     * @dev 一键上任接口
     */
    function takeOffice() public {
        // checkValidOperateInterval(OperateType.TAKE_OFFICE);

        /// 在职成员卸任
        resignExistingMembers();
        /// 新成员上任
        takeOfficeNewMembers();
        /// 重置状态变量
        resetStateVariables();

        emit TakeOfficeEvent(
            round,
            roundStartTime,
            SafeMath.add(roundStartTime, RoundLength),
            SafeMath.add(roundStartTime, SafeMath.div(RoundLength, 3)),
            SafeMath.add(roundStartTime, SafeMath.div(SafeMath.mul(RoundLength, 5), 6)),
            SafeMath.add(roundStartTime, SafeMath.div(SafeMath.mul(RoundLength, 173), 180)),
            director, 
            permanentMembers, 
            members
        );
    }

    /// 在职成员卸任
    function resignExistingMembers() internal {
        /// 理事卸任并删除候选理事
        resignCitizens(members);
        delete members;
        resignCitizens(candidateMembers);
        delete candidateMembers;

        /// 常任理事卸任并删除候选常任理事
        resignCitizens(permanentMembers);
        delete permanentMembers;
        delete candidatePermanentMembers;

        /// 理事长卸任并删除候选理事长
        address[] memory tempDirector = new address[](1);
        tempDirector[0] = director;
        resignCitizens(tempDirector);
        delete director;
        delete candidateDirectors;
    }

    /// 新成员上任
    function takeOfficeNewMembers() internal {
        /// 理事长上任
        uint directorLength = signUpDirectors.length;
        if (directorLength > 0) {
            if (directorLength == 1) {
                director = signUpDirectors[0];
            } else {
                address[] memory sortedDirectors = sortMembers(signUpDirectors);
                director = sortedDirectors[0];
                for (uint i = 1; i < sortedDirectors.length; i++) {
                    candidateDirectors.push(sortedDirectors[i]);
                }
            }
            address[] memory tempDirectors = new address[](1);
            tempDirectors[0] = director;
            takeOfficeCitizens(tempDirectors, PositionType.DIRECTOR);
        }

        /// 常任理事上任
        uint permanentLength = signUpPermanentMembers.length;
        if (permanentLength > 0) {
            if (permanentLength <= 5) {
                permanentMembers = signUpPermanentMembers;
            } else {
                address[] memory sortedPermanents = sortMembers(signUpPermanentMembers);
                for (uint j = 0; j < 5; j++) {
                    permanentMembers.push(sortedPermanents[j]);
                }
                for (uint k = 5; k < sortedPermanents.length; k++) {
                    candidatePermanentMembers.push(sortedPermanents[k]);
                }
            }
            takeOfficeCitizens(permanentMembers, PositionType.PERMANENT_MEMBER);
        }

        /// 理事上任
        uint memberLength = signUpMembers.length;
        if (memberLength >= MinimumMemberLength) {
            confirmMembers();
            if (0x0 != director) {
                address[] memory removeDirector = new address[](1);
                removeDirector[0] = director;   
                removeNewMembers(removeDirector);
            }
            if (permanentMembers.length > 0) {
                removeNewMembers(permanentMembers);
            }
            takeOfficeCitizens(members, PositionType.MEMBER);
        }
    }

    /// 新成员上任后重置上一届的报名等数据
    function resetStateVariables() internal {
        for (uint i = 0; i < signUpMembers.length; i++) {
            delete signedUpMembers[signUpMembers[i]];
        }
        for (uint j = 0; j < signUpPermanentMembers.length; j++) {
            delete signedUpPermanentMembers[signUpPermanentMembers[j]];
        }
        for (uint k = 0; k < signUpDirectors.length; k++) {
            delete signedUpDirectors[signUpDirectors[k]];
        }
        delete signUpMembers;
        delete signUpPermanentMembers;
        delete signUpDirectors;
        round++;
        roundStartTime = block.timestamp;
        roundStartHeight = block.number;
    }

    /// 现任成员卸任公用方法
    function resignCitizens(address[] existingCitizens) internal {
        uint length = existingCitizens.length;
        if (length > 0) {
            for (uint i = 0; i < length; i++) {
                Citizen storage citizen = citizens[existingCitizens[i]];
                if (citizen.existed) {
                    citizen.totalPrestige = 0;
                    if (citizen.myProposals.length > 0) {
                        for (uint j = 0; j < citizen.myProposals.length; j++) {
                            delete proposals[citizen.myProposals[j]];
                        }
                        citizen.myProposals = new uint[](0);
                    }
                    if (citizen.myVotedProposals.length > 0) {
                        for (uint k = 0; k < citizen.myVotedProposals.length; k++) {
                            delete citizen.votedProposals[k];
                        }
                        citizen.myVotedProposals = new uint[](0);
                    }
                    citizen.position = PositionType.NO_POSITION;
                }
            }
        }
    }

    /// 对给定数组从大到小排序
    function sortMembers(address[] targetAddresses) internal view returns(address[]) {
        uint length = targetAddresses.length;
        if (length > 0) {
            address tempAddr;
            for (uint m = 0; m < length-1; m++) {
                for (uint n = 0; n < length-m-1; n++) {
                    if (calCitizenTotalPrestige(targetAddresses[n]) < calCitizenTotalPrestige(targetAddresses[n+1])) {
                        tempAddr = targetAddresses[n];
                        targetAddresses[n] = targetAddresses[n+1];
                        targetAddresses[n+1] = tempAddr;
                    }
                }
            }
        }
        return targetAddresses;
    }

    /// 准理事及准候选理事成员上任公用方法
    function takeOfficeCitizens(address[] targetAddresses, PositionType positionType) internal {
        uint length = targetAddresses.length;
        if (length > 0) {
            for (uint i = 0; i < length; i++) {
                Citizen storage citizen = citizens[targetAddresses[i]];
                if (citizen.existed) {
                    citizen.totalPrestige = calCitizenTotalPrestige(targetAddresses[i]);
                    citizen.signUpPrestige = 0;
                    citizen.electToSelfPrestige = 0;
                    citizen.electInPrestige = 0;
                    citizen.electOutPrestige = 0;
                    citizen.electInRecordIds = new uint[](0);
                    if (citizen.electOutRecordIds.length > 0) {
                        for (uint k = 0; k < citizen.electOutRecordIds.length; k++) {
                            delete electRecords[citizen.electOutRecordIds[k]];
                        }
                        citizen.electOutRecordIds = new uint[](0);
                    }
                    citizen.votedPermanentMembers = new address[](0);
                    delete citizen.votedDirector;
                    citizen.position = positionType;
                }
            }
        }
    }

    /// 确认新一任的理事及候选理事名单
    function confirmMembers() internal {
        address tempAddr;   
        uint length = signUpMembers.length;
        for (uint m = 0; m < length-1; m++) {
            for (uint n = 0; n < length-m-1; n++) {
                if (calCitizenTotalPrestige(signUpMembers[n]) < calCitizenTotalPrestige(signUpMembers[n+1])) {
                    tempAddr = signUpMembers[n];
                    signUpMembers[n] = signUpMembers[n+1];
                    signUpMembers[n+1] = tempAddr;
                }
            }
        }
        if (length >= MinimumMemberLength && length <= 99) {
            members = signUpMembers;
        }
        if (length > 99) {
            for (uint i = 0; i < 99; i++) {
                members.push(signUpMembers[i]);
            }
            for (uint j = 99; j < length; j++) {
                candidateMembers.push(signUpMembers[j]);
            }
        }   
    }

    /// 从理事名单中移除报名常任理事和理事长的成员
    function removeNewMembers(address[] removeMembers) internal {
        uint removeLength = removeMembers.length;
        if (removeLength > 0) {
            for (uint i = 0; i < removeLength; i++) {
                uint length = members.length;
                for (uint j = 0; j < length; j++) {
                    if (removeMembers[i] == members[j]) {
                        if (j != length-1) {
                            members[j] = members[length-1];
                        }
                        members.length--;
                        break;
                    }
                }
            }
        }
    }

    /// 测试方法
    function getSignUpMembers() public view returns(address[], address[], address[]) {
        return (signUpMembers, signUpPermanentMembers, signUpDirectors);
    }

    /// 测试方法
    function getCandidateMembers() public view returns(address[], address[], address[]) {
        return (candidateMembers, candidatePermanentMembers, candidateDirectors);
    }

    /**
     * @dev 现任成员卸任
     *
     * 目前都是直接卸任，如果有候选人员，由候选人员上任
     * 根绝规则：如果是理事长或常任理事卸任，候选人员上任后，将从理事名单中删除该人员。
     */
    function resign(address caller) public {
        Citizen storage citizen = citizens[caller];
        require(citizen.existed, "citizen is not existing");
        require(citizen.position == PositionType.DIRECTOR || citizen.position == PositionType.PERMANENT_MEMBER
         || citizen.position == PositionType.MEMBER, "you don't have authority to resign");

        /// 发起提议
        startProposal(1, 0x0, 0, 0);

        /// 理事长卸任
        if (PositionType.DIRECTOR == citizen.position) {
            resighDirector(caller);
        }
        /// 常任理事卸任
        if (PositionType.PERMANENT_MEMBER == citizen.position) {
            resignPermanentMember(caller);
        }
        /// 理事卸任
        if (PositionType.MEMBER == citizen.position) {
            resignMember(caller);
        }

        citizen.myProposals = new uint[](0);
        if (citizen.myVotedProposals.length > 0) {
            for (uint i = 0; i < citizen.myVotedProposals.length; i++) {
                delete citizen.votedProposals[citizen.myVotedProposals[i]];
            }
            citizen.myVotedProposals = new uint[](0);
        }
        citizen.position = PositionType.NO_POSITION;
    }

    /// 理事长卸任
    /// 如果有候选理事长，候选人顶上，并对候选人名单重新排序。
    /// 最后从理事名单中删除该候选人
    function resighDirector(address caller) internal {
        delete director;
        uint length = candidateDirectors.length;
        address candidate;
        if (length > 0) {
            candidate = candidateDirectors[0];
            Citizen storage citizen = citizens[candidate];
            if (citizen.existed && citizen.position == PositionType.MEMBER) {
                director = candidate;
                citizen.position = PositionType.DIRECTOR;
                for (uint i = 0; i < length-1; i++) {
                    candidateDirectors[i] = candidateDirectors[i+1];
                }
                candidateDirectors.length--;
                uint memberLength = members.length;
                for (uint j = 0; j < memberLength; j++) {
                    if (candidate == members[j]) {
                        if (j != memberLength-1) {
                            members[j] = members[memberLength-1];
                        }
                        members.length--;
                        break;
                    }
                }
            }
        }
        emit ResignEvent(round, caller, candidate, PositionType.DIRECTOR);
    }

    /// 常任理事卸任
    /// 如果有候选常任理事，候选人顶上，并对候选人名单重新排序。
    /// 最后从理事名单中删除该候选人
    function resignPermanentMember(address caller) internal {
        uint length = permanentMembers.length;
        for (uint i = 0; i < length; i++) {
            if (caller == permanentMembers[i]) {
                if (i != length-1) {
                    permanentMembers[i] = permanentMembers[length-1];
                }
                permanentMembers.length--;
                break;
            }
        }
        address candidate;
        uint candidateLength = candidatePermanentMembers.length;
        if (candidateLength > 0) {
            candidate = candidatePermanentMembers[0];
            Citizen storage newMember = citizens[candidate];
            if (newMember.existed && newMember.position == PositionType.MEMBER) {
                permanentMembers.push(candidate);
                newMember.position = PositionType.PERMANENT_MEMBER;
                for (uint k = 0; k < candidateLength-1; k++) {
                    candidatePermanentMembers[k] = candidatePermanentMembers[k+1];
                }
                candidatePermanentMembers.length--;
                uint memberLength = members.length;
                for (uint j = 0; j < memberLength; j++) {
                    if (candidate == members[j]) {
                        if (j != memberLength-1) {
                            members[j] = members[memberLength-1];
                        }
                        members.length--;
                        break;
                    }
                }
            }
        }
        emit ResignEvent(round, caller, candidate, PositionType.PERMANENT_MEMBER);
    }

    /// 理事卸任
    /// 从理事名单中删除该成员。
    /// 如果有候选人，候选人顶上，并对候选人列表重新排序
    function resignMember(address caller) internal {
        uint length = members.length;
        for (uint i = 0; i < length; i++) {
            if (caller == members[i]) {
                if (i != length-1) {
                    members[i] = members[length-1];
                }
                members.length--;
                break;
            }
        }
        address candidate;
        uint candidateMemberLength = candidateMembers.length;
        if (candidateMemberLength > 0) {
            candidate = candidateMembers[0];
            Citizen storage newMember = citizens[candidate];
            if (newMember.existed) {
                members.push(candidate);
                newMember.position = PositionType.MEMBER;
                for (uint j = 0; j < candidateMemberLength-1; j++) {
                    candidateMembers[j] = candidateMembers[j+1];
                }
                candidateMembers.length--;
            }
        }
        emit ResignEvent(round, caller, candidate, PositionType.MEMBER);
    }

    /**
     * @dev 发起提议
     *
     * @param proposalType 提议类型
     * @param receiver 收钱地址
     * @param amount 金额
     * @param depositLength 质押天数
     * @return proposalId 提议记录id
     */
    function startProposal(uint proposalType, address receiver, uint amount, uint depositLength) public returns(uint) {
        require(proposalType == 0 || proposalType == 1, "invalid proposal type");

        Citizen storage citizen = citizens[msg.sender];
        require(citizen.existed, "you are not allowed to start a proposal");
        require(citizen.position == PositionType.MEMBER || citizen.position == PositionType.PERMANENT_MEMBER
            || citizen.position == PositionType.DIRECTOR, "you are not allowed to start a proposal");

        uint proposalId = proposalIndex+1;
        Proposal storage prop = proposals[proposalId];
        prop.proposer = msg.sender;
        prop.startTime = block.timestamp;
        prop.status = ProposalStatus.ONGOING;
        prop.existed = true;

        /// 预留Asim分配
        if (0 == proposalType) {
            /// 只有理事长能发起预留Asim分配
            require(citizen.position == PositionType.DIRECTOR, "only director can start a proposal of allocating Asim");
            require(amount > 0, "amount must bigger than 0");
            if (depositLength > 0) {
                require(depositLength == 10 || depositLength == 30 || depositLength == 90 || depositLength == 180
                || depositLength == 360 || depositLength == 720, "invalid param of depositLength");
                prop.depositLength = depositLength;
            }
            prop.voters = permanentMembers;
            prop.receiver = receiver;
            prop.amount = amount;
            prop.percent = 60;
            prop.proposalType = ProposalType.DEPOSIT;
            prop.endTime = SafeMath.add(block.timestamp, SafeMath.div(SafeMath.mul(RoundLength, 7), 180));
        }
        /// 成员卸任
        else if (1 == proposalType) {
            prop.voters.push(msg.sender);
            prop.approvers.push(msg.sender);
            prop.percent = 100;
            prop.votedPrestige = citizen.totalPrestige;
            prop.proposalType = ProposalType.RESIGN;
            prop.status = ProposalStatus.APPROVED;
            prop.endTime = SafeMath.add(block.timestamp, SafeMath.div(SafeMath.mul(RoundLength, 7), 180));
        }
        for (uint i = 0; i < prop.voters.length; i++) {
            prop.voterRight[prop.voters[i]] = true;
        }
        prop.totalPrestige = calProposalTotalPrestige(prop.voters);
        citizen.myProposals.push(proposalId);
        proposalIndex++;
        
        emit StartProposalEvent(round, proposalId, prop.proposalType, msg.sender);
        emit VotingProposalEvent(round, prop.voters, proposalId);
        if (prop.proposalType == ProposalType.RESIGN) {
            emit ProposalStatusChangeEvent(round, proposalId, prop.status);
        }
        return proposalId;
    }

    /**
     * @dev 参与提议投票，按权重投票
     *
     * @param proposalId 提议记录id
     * @param decision 投票决定
     */
    function vote(address caller, uint proposalId, bool decision) public {
        Proposal storage prop = proposals[proposalId];
        require(prop.existed, "proposal is not existing");
        require(prop.endTime >= block.timestamp, "the proposal has ended");

        Citizen storage citizen = citizens[caller];
        require(citizen.existed, "citizen is not existing");
        require(!citizen.votedProposals[proposalId], "you have voted");

        /// 如果是理事长投票，只能一票否决
        if (prop.directorVote && citizen.position == PositionType.DIRECTOR) {
            require(prop.status == ProposalStatus.APPROVED, "invalid proposal status");
            require(prop.directorStartTime <= block.timestamp, "invalid time to vote");
            prop.status = ProposalStatus.REJECTED;
            prop.rejecters.push(caller);
            prop.directorReject = true;
            emit VoteEvent(round, proposalId, caller, false);
            emit ProposalStatusChangeEvent(round, proposalId, prop.status);
        } else {
            require(prop.voterRight[caller], "you don't have right to vote");
            require(prop.status == ProposalStatus.ONGOING, "invalid proposal status");
            if (prop.directorVote) {
                require(block.timestamp < prop.directorStartTime, "invalid time to vote");
            }
            if (decision) {
                prop.votedPrestige = SafeMath.add(prop.votedPrestige, citizen.totalPrestige);
                /// 如果支持率达标，修改提议状态，并执行提议内容
                if (SafeMath.div(SafeMath.mul(prop.votedPrestige, 100), prop.totalPrestige) >= prop.percent) {
                    prop.status = ProposalStatus.APPROVED;
                    emit ProposalStatusChangeEvent(round, proposalId, prop.status);
                }
                prop.approvers.push(caller);
            } else {
                prop.rejectPrestige = SafeMath.add(prop.rejectPrestige, citizen.totalPrestige);
                uint rejectPercent = SafeMath.div(SafeMath.mul(prop.rejectPrestige, 100), prop.totalPrestige);
                /// 如果反对率达标，提前终止提议
                if (rejectPercent > SafeMath.sub(100, prop.percent)) {
                    prop.status = ProposalStatus.REJECTED;
                    emit ProposalStatusChangeEvent(round, proposalId, prop.status);
                }
                prop.rejecters.push(caller);
            }
            emit VoteEvent(round, proposalId, caller, decision);
        }
        citizen.myVotedProposals.push(proposalId);
        citizen.votedProposals[proposalId] = true;
    }

    /**
     * @dev 提议发起人确认执行提议
     *
     * @param proposalId 提议id
     */
    function approverConfirm(uint proposalId) public {
        Proposal storage prop = proposals[proposalId];
        require(prop.existed, "invalid proposalId");
        require(prop.proposer == msg.sender, "you don't have right to confirm");
        // require(block.timestamp > prop.endTime, "the proposal hasn't ended up");
        require(prop.status == ProposalStatus.APPROVED, "voters dont't aggree the proposal");

        if (prop.proposalType == ProposalType.DEPOSIT) {
            if (prop.depositLength > 0) {
                address(consensusMining).transfer(prop.amount, ASCoin);
                consensusMining.depositToSpecificAddress(prop.receiver, prop.depositLength, prop.amount);
                emit TransferAssetEvent(address(consensusMining), ProposalType.DEPOSIT, ASCoin, prop.amount);
            } else {
                prop.receiver.transfer(prop.amount, ASCoin);
                emit TransferAssetEvent(prop.receiver, ProposalType.DEPOSIT, ASCoin, prop.amount);
            }
        }
    }

    /**
     * @dev 获取各职位允许发起的提议类型以及能参与投票的提议类型
     *
     * @return 理事能发起的提议类型、常任理事能发起的提议类型、理事长能发起的提议类型
     */
    function getMemberProposalTypes() public view returns(ProposalType[], ProposalType[], 
        ProposalType[], ProposalType[], ProposalType[], ProposalType[]) 
    {
        return (memberProposals, permanentMemberProposals, directorProposals, memberVotes, permanentVotes, directorVotes);
    }

    /**
     * @dev 查看全部组织架构，包括理事、常任理事、理事长以及他们的声望值
     *
     * @return 理事长、常任理事、理事、声望值、提议、投票
     */
    function getOrganizationStructure() public view returns(address, address[], address[], uint[], uint[], uint[]) {
        uint totalLength = SafeMath.add(SafeMath.add(permanentMembers.length, members.length), 1);

        uint[] memory prestiges = new uint[](totalLength);
        uint[] memory myProposals = new uint[](totalLength);
        uint[] memory myVotedProposals = new uint[](totalLength);

        /// 理事长
        Citizen storage curDirector = citizens[director];
        prestiges[0] = curDirector.totalPrestige;
        myProposals[0] = curDirector.myProposals.length;
        myVotedProposals[0] = curDirector.myVotedProposals.length;

        /// 常任理事
        if (permanentMembers.length > 0) {
            for (uint i = 0; i < permanentMembers.length; i++) {
                Citizen storage permanent = citizens[permanentMembers[i]];
                prestiges[i+1] = permanent.totalPrestige;
                myProposals[i+1] = permanent.myProposals.length;
                myVotedProposals[i+1] = permanent.myVotedProposals.length;
            }
        }

        /// 理事
        uint tempLength = SafeMath.add(permanentMembers.length, 1);
        if (members.length > 0) {
            for (uint j = 0; j < members.length; j++) {
                Citizen storage member = citizens[members[j]];
                prestiges[j+tempLength] = member.totalPrestige;
                myProposals[j+tempLength] = member.myProposals.length;
                myVotedProposals[j+tempLength] = member.myVotedProposals.length;
            }
        }
        return (director, permanentMembers, members, prestiges, myProposals, myVotedProposals);
    }

    /**
     * @dev 查看投票选举页面成员个人信息
     *
     * @return 被选举人当前声望、投票人剩余声望值、已支持候选人列表、已支持候选人声望值、我支持的声望值
     */
    function getVotePageInfo(address voteTo) public view returns(uint, uint, address[], uint[], uint[]) {
        Citizen storage candidate = citizens[voteTo];
        if (!candidate.existed) {
            return (0, 0, new address[](0), new uint[](0), new uint[](0));
        }

        /// 被选举人当前声望
        uint candidatePrestige = SafeMath.add(
            SafeMath.add(candidate.signUpPrestige, candidate.electToSelfPrestige), 
            candidate.electInPrestige
        );

        /// 投票人剩余声望值
        Citizen storage voter = citizens[msg.sender];
        uint voterPrestige = getValidPower();
        if (voter.existed) {
            voterPrestige = SafeMath.sub(
                SafeMath.sub(SafeMath.sub(voterPrestige, voter.signUpPrestige), voter.electToSelfPrestige), 
                voter.electOutPrestige
            );
        }

        /// 已支持候选人
        address[] memory tempCandidates;
        uint[] memory tempPrestiges;
        uint[] memory tempVotes;
        (tempCandidates, tempPrestiges, tempVotes) = supportedCandidates(voter.electOutRecordIds);
        
        return (candidatePrestige, voterPrestige, tempCandidates, tempPrestiges, tempVotes);
    }

    /// 查询已支持的候选人名单
    function supportedCandidates(uint[] electOutRecordIds) internal view returns(address[], uint[], uint[]) {
        uint length = electOutRecordIds.length;
        address[] memory tempCandidates = new address[](length);
        uint[] memory tempPrestiges = new uint[](length);
        uint[] memory tempVotes = new uint[](length);
        if (length > 0) {
            for (uint i = 0; i < length; i++) {
                ElectRecord storage record = electRecords[electOutRecordIds[i]];
                tempCandidates[i] = record.elector;
                Citizen storage elector = citizens[record.elector];
                tempPrestiges[i] = SafeMath.add(
                    SafeMath.add(elector.signUpPrestige, elector.electToSelfPrestige), 
                    elector.electInPrestige
                );
                tempVotes[i] = record.prestige;
            }
        }
        return (tempCandidates, tempPrestiges, tempVotes);
    }

    /**
     * @dev 查看我的提议记录
     *
     * @return 记录id、提议类型、提议日期、提议状态
     */
    function getMyProposals() public view returns(uint[], ProposalType[], uint[], ProposalStatus[]) {
        Citizen storage citizen = citizens[msg.sender];
        if (!citizen.existed) {
            return (new uint[](0), new ProposalType[](0), new uint[](0), new ProposalStatus[](0));
        }

        uint length = citizen.myProposals.length;
        uint[] memory ids = new uint[](length);
        ProposalType[] memory types = new ProposalType[](length);
        uint[] memory timestamps = new uint[](length);
        ProposalStatus[] memory status = new ProposalStatus[](length);
        if (length > 0) {
            for (uint i = 0; i < length; i++) {
                Proposal storage p = proposals[citizen.myProposals[i]];
                ids[i] = citizen.myProposals[i];
                types[i] = p.proposalType;
                timestamps[i] = p.startTime;
                status[i] = p.status;
            }
        }
        return (ids, types, timestamps, status);
    }

    /**
     * @dev 查看我的投票记录
     *
     * @return 记录id、提议类型、我的投票、提议日期、提议状态
     */
    function getMyVotedProposals() public view returns(uint[], ProposalType[], uint[], ProposalStatus[]) {
        Citizen storage citizen = citizens[msg.sender];
        if (!citizen.existed) {
            return (new uint[](0), new ProposalType[](0), new uint[](0), new ProposalStatus[](0));
        }

        uint length = citizen.myVotedProposals.length;
        uint[] memory ids = new uint[](length);
        ProposalType[] memory types = new ProposalType[](length);
        uint[] memory timestamps = new uint[](length);
        ProposalStatus[] memory status = new ProposalStatus[](length);
        if (length > 0) {
            for (uint i = 0; i < length; i++) {
                Proposal storage p = proposals[citizen.myVotedProposals[i]];
                ids[i] = citizen.myVotedProposals[i];
                types[i] = p.proposalType;
                timestamps[i] = p.startTime;
                status[i] = p.status;
            }
        }
        return (ids, types, timestamps, status);
    }

    /// 测试方法。查询成员信息
    function getCitizenInfo(address caller) public view returns(uint, uint, uint, uint, uint[], uint[], PositionType) {
        Citizen storage c = citizens[caller];
        require(c.existed);
        return (c.totalPrestige, c.signUpPrestige, c.electToSelfPrestige, c.electInPrestige, 
            c.myProposals, c.myVotedProposals, c.position);
    }

    /**
     * @dev 查看提议内容详情
     *
     * @param proposalId 提议记录id
     * @return 是否存在记录、分配地址、提议状态、分配金额、截止时间、总投票的人、支持的成员、反对的成员
     */
    function getProposalDetail(uint proposalId) public view returns(bool, address, ProposalStatus, uint, uint, address[], address[], address[]) {
        Proposal storage p = proposals[proposalId];
        if (!p.existed) {
            return (false, 0x0, ProposalStatus.ONGOING, 0, 0, new address[](0), new address[](0), new address[](0));
        }
        return (true, p.receiver, p.status, p.totalPrestige, p.votedPrestige, p.voters, p.approvers, p.rejecters);
    }

    /// 获取个人有效的power
    function getValidPower() public view returns(uint) {
        uint finalHeight = SafeMath.add(roundStartHeight, SafeMath.div(RoundLength, 5));
        uint power = consensusMining.getValidatorPower(msg.sender, finalHeight);
        return power;
    }

    /// 计算准成员总的声望，只包含报名、投票
    function calCitizenTotalPrestige(address citizen) internal view returns(uint) {
        Citizen storage c = citizens[citizen];
        return SafeMath.add(
            SafeMath.add(c.signUpPrestige, c.electToSelfPrestige), 
            c.electInPrestige
        );
    } 

    /// 计算成员总声望值
    function calProposalTotalPrestige(address[] allVoters) internal view returns(uint) {
        uint totalPrestige;
        for (uint i = 0; i < allVoters.length; i++) {
            Citizen storage citizen = citizens[allVoters[i]];
            if (citizen.existed) {
                totalPrestige = SafeMath.add(totalPrestige, citizen.totalPrestige);
            }
        }
        return totalPrestige;
    }

    /// 操作区间合法性校验
    function checkValidOperateInterval(OperateType operateType) internal view {
        uint startTime;
        uint endTime;
        if (operateType == OperateType.SIGN_UP_MEMBER) {
            startTime = roundStartTime;
            endTime = SafeMath.add(roundStartTime, SafeMath.div(RoundLength, 3));
        }
        if (operateType == OperateType.ELECT_MEMBER) {
            startTime = SafeMath.add(roundStartTime, SafeMath.div(RoundLength, 3));
            endTime = SafeMath.add(roundStartTime, SafeMath.div(SafeMath.mul(RoundLength, 5), 6));
        }
        if (operateType == OperateType.SIGN_UP_PERMANENT_MEMBER || operateType == OperateType.SIGN_UP_DIRECTOR 
            || operateType == OperateType.ELECT_PERMANENT_AND_DIRECTOR) {
            startTime = SafeMath.add(roundStartTime, SafeMath.div(SafeMath.mul(RoundLength, 5), 6));
            /// 每一轮最后7天留作一键上任操作
            endTime = SafeMath.add(roundStartTime, SafeMath.div(SafeMath.mul(RoundLength, 173), 180));
        }
        if (operateType == OperateType.TAKE_OFFICE) {
            startTime = SafeMath.add(roundStartTime, SafeMath.div(SafeMath.mul(RoundLength, 173), 180));
            endTime = SafeMath.add(roundStartTime, RoundLength);
        }
        require(block.timestamp > startTime && block.timestamp <= endTime, "invalid operate interval");
    }

    ///  to check whether an address is a citizen of the Genesis Organization
    ///  _citizen the address to check
    function existed(address _citizen) public view returns (bool) {
        if (director == _citizen) {
            return true;
        }
        for (uint i = 0; i < permanentMembers.length; i++) {
            if (permanentMembers[i] == _citizen) {
                return true;
            }
        }
        for (uint j = 0; j < members.length; j++) {
            if (members[j] == _citizen) {
                return true;
            }
        }
        return false;
    }
    
}


