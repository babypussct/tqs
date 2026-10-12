local zuoyou = fk.CreateSkill {
  name = "zuoyou",
  tags = { Skill.Switch },
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("2v2_mode") then
      return "zuoyou_2v2"
    else
      return "zuoyou_role_mode"
    end
  end,
}

Fk:loadTranslationTable{
  ["zuoyou"] = "佐佑",
  [":zuoyou"] = "转换技，出牌阶段限一次，阳：你可以令一名角色摸三张牌，然后其弃置两张手牌；阴：" ..
  "你可以令一名角色弃置一张手牌，然后其获得1点护甲（若为2v2模式，则改为令一名角色获得1点护甲）。",

  [":zuoyou_role_mode"] = "转换技，出牌阶段限一次，阳：你可以令一名角色摸三张牌，然后其弃置两张手牌；阴：" ..
  "你可以令一名角色弃置一张手牌，然后其获得1点护甲。",
  [":zuoyou_2v2"] = "转换技，出牌阶段限一次，阳：你可以令一名角色摸三张牌，然后其弃置两张手牌；阴：" ..
  "你可以令一名角色获得1点护甲。",

  ["#zuoyou-yang"] = "佐佑：你可以令一名角色摸三张牌，然后其弃置两张手牌",
  ["#zuoyou-yin"] = "佐佑：你可以令一名角色弃置一张手牌，然后其获得1点护甲",
  ["#zuoyou_2v2-yin"] = "佐佑：你可以令一名角色获得1点护甲",

  ["$zuoyou1"] = "陛下亲讨乱贼，臣等安不随护！",
  ["$zuoyou2"] = "纵有亡身之险，亦忠陛下一人！",
}

local function DoZuoyou(player, status)
  local room = player.room
  if status == "yang" then
    player:drawCards(3, zuoyou.name)
    if not player.dead and not player:isKongcheng() then
      room:askToDiscard(player, {
        min_num = 2,
        max_num = 2,
        include_equip = false,
        skill_name = zuoyou.name,
        cancelable = false,
      })
    end
  else
    if room:isGameMode("2v2_mode") then
      room:changeShield(player, 1)
    elseif player:getHandcardNum() > 0 then
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = zuoyou.name,
        cancelable = false,
      })
      if not player.dead then
        room:changeShield(player, 1)
      end
    end
  end
end
zuoyou:addEffect("active", {
  anim_type = "switch",
  card_num = 0,
  target_num = 1,
  prompt = function(self, player)
    if player:getSwitchSkillState(zuoyou.name, false) == fk.SwitchYang then
      return "#zuoyou-yang"
    else
      if Fk:currentRoom():isGameMode("2v2_mode") then
        return "#zuoyou_2v2-yin"
      else
        return "#zuoyou-yin"
      end
    end
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(zuoyou.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if player:getSwitchSkillState(zuoyou.name, false) == fk.SwitchYang then
      return #selected == 0
    else
      return #selected == 0 and (Fk:currentRoom():isGameMode("2v2_mode") or not to_select:isKongcheng())
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local status = player:getSwitchSkillState(zuoyou.name, true) == fk.SwitchYang and "yang" or "yin"
    room:setPlayerMark(player, "zuoyou-phase", target.id)
    DoZuoyou(target, status)
  end,
})

return zuoyou
