---@class HegUtil
local HegUtil = require "packages.hegemony.utilevent._base"

--- CommandData 描述和一次执行军令有关的数据
---@class HegUtil.CommandDataSpec
---@field public tos ServerPlayer[] @ 执行军令的角色
---@field public from ServerPlayer @ 发起军令的角色
---@field public num? integer @ 抽取的军令数量（默认为2）（有command时不需要填）
---@field public pool? string[] @ 可选军令列表（默认为六个command军令）（有command时不需要填）
---@field public command? string @ 军令名
---@field public command_data? table|CostData @ 军令相关数据
---@field public skillName string @ 军令技能名
---@field public forced? boolean @ 是否强制执行军令？
---@field public forced_list? ServerPlayer[] @ 以下目标必须执行军令
---@field public succeed? boolean @ 最近一名目标是否执行军令？
---@field public succeed_list? ServerPlayer[] @ 以下目标执行了军令
---@field public no_log? boolean @ 是否不显示具体选择军令？
---@field public no_indicate? boolean @ 是否不显示指示线？

--- 描述和一次执行军令有关的数据
---@class HegUtil.CommandData: HegUtil.CommandDataSpec, TriggerData
HegUtil.CommandData = TriggerData:subclass("HegUtil.CommandData")

---@class HegUtil.CommandEvent: TriggerEvent
---@field data HegUtil.CommandData

HegUtil.CommandEvent = TriggerEvent:subclass("HegUtil.CommandEvent")

---@alias HegUtil.CommandTrigFunc fun(self: TriggerSkill, event: HegUtil.CommandEvent,
---  target: ServerPlayer, player: ServerPlayer, data: HegUtil.CommandData): any

---@class SkillSkeleton
---@field public addEffect fun(self: SkillSkeleton, key: HegUtil.CommandEvent,
---  data: TrigSkelSpec<HegUtil.CommandTrigFunc>, attr: TrigSkelAttribute?): SkillSkeleton

--- 时机

--- 执行军令时
---@class HegUtil.CommandExecuting: HegUtil.CommandEvent
HegUtil.CommandExecuting = HegUtil.CommandEvent:subclass("HegUtil.CommandExecuting")
--- 执行军令后
---@class HegUtil.CommandExecuted: HegUtil.CommandEvent
HegUtil.CommandExecuted = HegUtil.CommandEvent:subclass("HegUtil.CommandExecuted")

-- 军令效果，分为准备和执行两部分
---@class HegUtil.CommandEffectSpec
---@field on_prepare? fun(from: ServerPlayer, data: HegUtil.CommandData) @ 军令准备函数
---@field on_use fun(target: ServerPlayer, from: ServerPlayer, data: HegUtil.CommandData) @ 军令效果函数

-- 军令效果列表
---@private
---@type table<string, HegUtil.CommandEffectSpec>
HegUtil.CommandList = {}

--- 注册一个军令
---@param name string @ 军令名
---@param spec HegUtil.CommandEffectSpec @ 军令效果
function HegUtil.registerCommand(name, spec)
  assert(HegUtil.CommandList[name] == nil, "Command "..name.." is already registered.")
  HegUtil.CommandList[name] = {
    on_prepare = spec.on_prepare,
    on_use = spec.on_use,
  }
end

--- 执行军令的准备效果
---@param name string @ 军令名
---@param data HegUtil.CommandData @ 军令数据
function HegUtil.CommandPrepare(name, data)
  assert(HegUtil.CommandList[name] ~= nil, "Command "..name.." is not registered.")
  local prepare = HegUtil.CommandList[name].on_prepare
  if prepare then
    prepare(data.from, data)
  end
end

--- 执行军令的实际效果
---@param name string @ 军令名
---@param target ServerPlayer @ 军令执行者
---@param data HegUtil.CommandData @ 军令数据
function HegUtil.CommandCB(name, target, from, data)
  assert(HegUtil.CommandList[name] ~= nil, "Command "..name.." is not registered.")
  HegUtil.CommandList[name].on_use(target, data.from, data)
end

local allCommands = {"command1", "command2", "command3", "command4", "command5", "command6"}

---@class HegUtil.AskToCommandParams: AskToSkillInvokeParams
---@field tos ServerPlayer[] @ 军令执行者
---@field num? integer @ 抽取数量，默认为2
---@field pool? string[] @ 可选军令列表，默认为六个command军令
---@field forced? boolean @ 是否强制执行军令？
---@field skip? boolean @ 是否跳过执行军令？
---@field no_log? boolean @ 是否不显示具体选择军令？
---@field no_indicate? boolean @ 是否不显示指示线？

--- 对某角色发起军令（抽取、选择、询问）
---@param player ServerPlayer @ 军令发起者
---@param params HegUtil.AskToCommandParams @ 参数表
---@return boolean?, HegUtil.CommandDataSpec? @ 第一项为军令是否执行，第二项为军令执行数据
function HegUtil.askToCommand(player, params)
  local from, tos = player, params.tos
  if from.dead or table.every(tos, function(p) return p.dead end) then
    return nil
  end
  local room = from.room
  room:sendLog{
    type = "#AskCommandTo",
    from = from.id,
    to = table.map(tos, Util.IdMapper),
    arg = params.skill_name,
    toast = true,
  }

  local data = {
    tos = tos,
    from = from,
    num = params.num or 2,
    pool = params.pool or allCommands,
    skillName = params.skill_name,
    forced = params.forced,
    no_log = params.no_log,
    no_indicate = params.no_indicate,
  }

  if not params.skip then
    HegUtil.Command(data)
  end

  return data.succeed, data
end

---@class HegUtil.AskToStartCommandParams: AskToSkillInvokeParams
---@field num? integer @ 抽取数量，默认为2
---@field pool? string[] @ 总军令列表，默认为六个command军令
---@field skill_name? string @ 询问技能名（烧条时显示的技能名）
---@field no_log? boolean @ 是否不显示具体选择军令？

--- 军令发起者抽取并选择军令
---@param player ServerPlayer @ 军令发起者
---@param params? HegUtil.AskToStartCommandParams @ 参数表
---@return string?, string[] @ 选择的军令名，若未选择则返回nil；第二项为备选军令列表
function HegUtil.askToStartCommand(player, params)
  local room = player.room
  params = params or {}
  local pool = params.pool or allCommands
  local num = params.num or 2

  assert(num <= #pool, "HegUtil.askToStartCommand: num is larger than pool size.")
  if num < 1 or #pool < 1 then
    return nil, {}
  end

  local commands = table.random(pool, num)
  local choice = room:askToChoice(player, {
    choices = commands,
    prompt = params.prompt,
    skill_name = params.skill_name or "start_command",
    detailed = true,
  })

  room:doBroadcastNotify("GameLog", {
    type = "#CommandAsk",
    from = player.id,
    arg = choice,
    arg2 = ":"+choice,
    toast = true,
  }, params.no_log and { player } or room.players)

  return choice, commands
end

---@deprecated 请使用 HegUtil.askToStartCommand
--- 军令发起者抽取并选择军令
---@param from ServerPlayer @ 军令发起者
---@param skill_name? string @ 技能名
---@param num? integer @ 抽取数量
---@return integer @ 选择的军令序号
function HegUtil.startCommand(from, skill_name, num)
  local choice = HegUtil.askToStartCommand(from, {
    skill_name = skill_name or "start_command",
    num = num or 2,
    pool = allCommands,
  })

  return table.indexOf(allCommands, choice)
end

--- 执行一个军令（无command则先选择军令）
---@param spec HegUtil.CommandDataSpec @ 军令数据
---@return boolean @ 是否选择执行军令
function HegUtil.Command(spec)
  local data = HegUtil.CommandData:new(spec)
  local event = HegUtil.GameEvent.Command:create(data)
  event:exec()
  return data.succeed
end

---@deprecated 请使用 HegUtil.Command
--- 询问军令执行者是否执行军令（执行效果也在这里）
---@param to ServerPlayer @ 军令执行者
---@param skill_name string @ 技能名
---@param index integer @ 军令序数
---@param from ServerPlayer @ 军令发起者
---@param forced? boolean @ 是否强制执行
---@return boolean @ 是否执行
function HegUtil.doCommand(to, skill_name, index, from, forced)
  if to.dead or from.dead then return false end
  local command = allCommands[index]
  local ret = HegUtil.Command{
    tos = { to },
    from = from,
    command = command,
    skillName = skill_name,
    forced = forced,
  }
  return ret
end

HegUtil.registerCommand("command1", {
  on_prepare = function (from, data)
    local room = from.room
    local dest = room:askToChoosePlayers(from, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#command1-damage:::" .. table.concat(
        table.map(data.tos, Player.__touistring), "、"),
      skill_name = data.skillName,
      cancelable = false,
    })[1]
    room:sendLog{
      type = "#Command1Damage",
      from = from.id,
      to = {dest.id},
    }
    room:doIndicate(from, {dest})
    data.command_data = { tos = { dest } }
  end,
  on_use = function(to, from, data)
  local room = to.room
  local target = data.command_data.tos[1]
  if target.dead then return end
  room:damage{
    from = to,
    to = target,
    damage = 1,
    skillName = "command",
  }
end
})
HegUtil.registerCommand("command2", {
  on_use = function(to, from)
    local room = to.room
    to:drawCards(1, "command")
    if to == from or to:isNude() then return true end
    local cards = room:askToCards(to,{
      min_num = 2,
      max_num = 2,
      include_equip = true,
      skill_name = "command",
      prompt = "#command2-give::" .. from.id,
      cancelable = false,
    })
    room:moveCardTo(cards, Player.Hand, from, fk.ReasonGive, "command", nil, false, from)
  end
})
HegUtil.registerCommand("command3", {
  on_use = function(to)
    to.room:loseHp(to, 1, "command")
  end
})
HegUtil.registerCommand("command4", {
  on_use = function(to)
    local room = to.room
    room:setPlayerMark(to, "@@command4_effect-turn", 1)
    room:addPlayerMark(to, MarkEnum.UncompulsoryInvalidity .. "-turn")
    room:addSkill("#command_skill")
  end
})
HegUtil.registerCommand("command5", {
  on_use = function(to)
    local room = to.room
    to:turnOver()
    room:setPlayerMark(to, "@@command5_effect-turn", 1)
    room:addSkill("#command_skill")
  end
})
HegUtil.registerCommand("command6", {
    on_use = function(to)
    local room = to.room
    if to:getHandcardNum() < 2 and #to:getCardIds("e") < 2 then return true end
    local to_remain = {}
    if not to:isKongcheng() then
      table.insert(to_remain, to:getCardIds("h")[1])
    end
    if #to:getCardIds("e") > 0 then
      table.insert(to_remain, to:getCardIds("e")[1])
    end
    local _, ret = room:askToUseActiveSkill(to, {
      skill_name = "#command_skill",
      prompt = "#command6-select",
      extra_data = {
        skillName = "command",
      },
      cancelable = false,
    })
    if ret then
      to_remain = ret.cards
    end
    local cards = table.filter(to:getCardIds("he"), function (id)
      return not (table.contains(to_remain, id) or to:prohibitDiscard(Fk:getCardById(id)))
    end)
    if #cards > 0 then
      room:throwCard(cards, "command", to)
    end
  end
})

-- 初始化事件
local Command = require "packages.hegemony.utilevent.events.command"
HegUtil.GameEvent.Command = Command

Fk:loadTranslationTable{
  ["command"] = "军令",

  ["command1"] = "军令一",
  [":command1"] = "对发起者指定的角色造成1点伤害",
  ["command2"] = "军令二",
  [":command2"] = "摸一张牌，然后交给发起者两张牌",
  ["command3"] = "军令三",
  [":command3"] = "失去1点体力",
  ["command4"] = "军令四",
  [":command4"] = "本回合不能使用或打出手牌且所有非锁定技失效",
  ["command5"] = "军令五",
  [":command5"] = "叠置，本回合不能回复体力",
  ["command6"] = "军令六",
  [":command6"] = "选择一张手牌和一张装备区里的牌，弃置其余的牌",

  ["start_command"] = "发起军令",
  ["#AskCommandTo"] = "%from 发动了 “%arg”，对 %to 发起了 <font color='#0598BC'><b>军令</b></font>",

  ["#CommandAsk"] = "%from 选择 %arg：%arg2",

  ["do_command"] = "执行军令",
  ["#CommandChoice"] = "%from %arg",
  ["#commandselect_yes"] = "执行军令",
  ["#commandselect_no"] = "不执行军令",

  ["#command1-damage"] = "军令：请选择要造成伤害的目标",
  ["#Command1Damage"] = "%from 选择对 %to 造成伤害",
  ["#command2-give"] = "军令：请选择两张牌交给 %dest",
  ["@@command4_effect-turn"] = "军令禁出牌技能",
  ["@@command5_effect-turn"] = "军令 不能回血",
  ["#command6-select"] = "军令：请选择要保留的一张手牌和一张装备",
}
