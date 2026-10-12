local kuangli = fk.CreateSkill {
  name = "kuangli",
  tags = { Skill.Compulsory },
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("1v2_mode") then
      return "kuangli_1v2"
    else
      return "kuangli_role_mode"
    end
  end,
}

Fk:loadTranslationTable{
  ["kuangli"] = "狂戾",
  [":kuangli"] = "锁定技，出牌阶段开始时，令随机数量（至少为一）名其他角色获得“狂戾”标记直到回合结束；每阶段限两次" ..
  "（若为斗地主，则改为限一次），当你于出牌阶段内使用牌指定一名拥有“狂戾”标记的角色为目标后，你随机弃置你与其各一张牌，然后你摸两张牌。",

  [":kuangli_1v2"] = "锁定技，出牌阶段开始时，令随机数量（至少为一）名其他角色获得“狂戾”标记直到回合结束；每阶段限一次，" ..
  "当你于出牌阶段内使用牌指定一名拥有“狂戾”标记的角色为目标后，你随机弃置你与其各一张牌，然后你摸两张牌。",
  [":kuangli_role_mode"] = "锁定技，出牌阶段开始时，令随机数量（至少为一）名其他角色获得“狂戾”标记直到回合结束；每阶段限两次，" ..
  "当你于出牌阶段内使用牌指定一名拥有“狂戾”标记的角色为目标后，你随机弃置你与其各一张牌，然后你摸两张牌。",

  ["@@kuangli-turn"] = "狂戾",

  ["$kuangli1"] = "我已受命弑君，汝等还不散去！",
  ["$kuangli2"] = "谁再聚众作乱，我就将其杀之！",
}

kuangli:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kuangli.name) and player.phase == Player.Play and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n = math.random(1, #room.alive_players - 1)
    local targets = room:tableRandomPick(room:getOtherPlayers(player, false), n)
    room:doIndicate(player, targets)
    for _, p in ipairs(targets) do
      room:setPlayerMark(p, "@@kuangli-turn", 1)
    end
  end,
})
kuangli:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kuangli.name) and player.phase == Player.Play and
      not data.to.dead and data.to:getMark("@@kuangli-turn") > 0 and
      player:usedEffectTimes(self.name, Player.HistoryPhase) < (player.room:isGameMode("1v2_mode") and 1 or 2)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if not player:isNude() and not player.dead then
      local id = room:tableRandomPick(player:getCardIds("he"))
      room:throwCard(id, kuangli.name, player, player)
    end
    if not data.to:isNude() and not data.to.dead then
      local id = room:tableRandomPick(data.to:getCardIds("he"))
      room:throwCard(id, kuangli.name, data.to, player)
    end
    if not player.dead then
      player:drawCards(2, kuangli.name)
    end
  end,
})

return kuangli
