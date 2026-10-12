
local shiyan = fk.CreateSkill {
  name = "shiyan",
}

Fk:loadTranslationTable{
  ["shiyan"] = "豕宴",
  [":shiyan"] = "出牌阶段限一次，你可以摸体力上限张牌（至多摸五张），然后交给等量名其他角色各一张手牌。"..
  "这些角色同时猜测你的手牌中非伤害牌与伤害牌哪个数量更多，每有一名猜对的角色便防止你本阶段受到的一次伤害，"..
  "然后猜错的角色依次视为对你使用【杀】，你受到此【杀】造成的伤害后减少1点体力上限。",

  ["#shiyan"] = "豕宴：你可以摸%arg张牌并分配给等量名其他角色",
  ["#shiyan-give"] = "豕宴：交给%arg名角色各一张手牌，这些角色猜测你手牌中非伤害牌与伤害牌哪个数量更多",
  ["#shiyan-choice"] = "豕宴：猜测 %src 手牌中非伤害牌与伤害牌哪个更多，猜对其防止伤害，猜错则视为对其使用【杀】",
  ["shiyan_none_damage"] = "非伤害牌更多",
  ["shiyan_damage"] = "伤害牌更多",
  ["@shiyan-phase"] = "豕宴",

  ["$shiyan1"] = "",
  ["$shiyan2"] = "",
}

shiyan:addEffect("active", {
  anim_type = "drawcard",
  prompt = function(self, player)
    return "#shiyan:::" .. math.min(player.maxHp, 5)
  end,
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  can_use = function (self, player)
    return player:usedSkillTimes(shiyan.name, Player.HistoryPhase) == 0
  end,
  on_use = function (self, room, effect)
    local player = effect.from
    local n = math.min(player.maxHp, 5)
    player:drawCards(n, shiyan.name)
    n = math.min(n, player:getHandcardNum(), #room:getOtherPlayers(player, false))
    if n == 0 then return end
    local result = room:askToYiji(player, {
      min_num = n,
      max_num = n,
      targets = room:getOtherPlayers(player, false),
      single_max = 1,
      skill_name = shiyan.name,
      prompt = "#shiyan-give:::"..n,
      cards = player:getCardIds("h"),
    })
    if player.dead then return end
    local targets = {}
    for pid, ids in pairs(result) do
      if #ids > 0 and not room:getPlayerById(tonumber(pid)).dead then
        table.insert(targets, room:getPlayerById(tonumber(pid)))
      end
    end
    if #targets == 0 then return end
    result = room:askToJointChoice(player, {
      players = targets,
      choices = { "shiyan_none_damage", "shiyan_damage" },
      skill_name = shiyan.name,
      prompt = "#shiyan-choice:"..player.id,
      send_log = true,
    })
    local damage_num = #table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id).is_damage_card
    end)
    local right, wrong = {}, {}
    for _, p in ipairs(targets) do
      if (result[p] == "shiyan_none_damage" and damage_num < player:getHandcardNum() / 2) or
        (result[p] == "shiyan_damage" and damage_num > player:getHandcardNum() / 2) then
        table.insert(right, p)
      else
        table.insert(wrong, p)
      end
    end
    if #right > 0 then
      room:addPlayerMark(player, "@shiyan-phase", #right)
    end
    room:sortByAction(wrong)
    for _, p in ipairs(wrong) do
      if not player.dead then
        room:useVirtualCard("slash", nil, p, player, shiyan.name, true, { shiyan = player })
      end
    end
  end,
})

shiyan:addEffect(fk.DetermineDamageInflicted, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@shiyan-phase") > 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:removePlayerMark(player, "@shiyan-phase", 1)
    data:preventDamage()
  end,
})

shiyan:addEffect(fk.Damaged, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if target == player and data.card and table.contains(data.card.skillNames, shiyan.name) and not player.dead then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      return use_event and use_event.data.extra_data and use_event.data.extra_data.shiyan == player
    end
  end,
  on_use = function (self, event, target, player, data)
    player.room:changeMaxHp(player, -1)
  end,
})

return shiyan
