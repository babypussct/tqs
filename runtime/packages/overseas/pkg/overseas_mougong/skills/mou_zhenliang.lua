
local zhenliang = fk.CreateSkill({
  name = "os_mou__zhenliang",
  tags = { Skill.Switch }
})

Fk:loadTranslationTable{
  ["os_mou__zhenliang"] = "贞良",
  [":os_mou__zhenliang"] = "转换技，阳：出牌阶段限一次，你可以选择一名你攻击范围内的其他角色并弃置X张与“任”颜色相同的牌，" ..
  "对其造成1点伤害（X为你与其体力值之差且至少为1）；<br>"..
  "阴：你的回合外，当一名角色使用或打出牌结算结束后，若此牌与“任”类别相同，则你可以令至多两名角色各摸两张牌。",

  ["#os_mou__zhenliang-damage"] = "贞良：弃置与“任”颜色相同的牌，对攻击范围内一名角色造成伤害",
  ["#os_mou__zhenliang-choose"] = "贞良：你可以令至多两名角色各摸两张牌",

  ["$os_mou__zhenliang1"] = "汉室艰祸繁兴，老夫岂忍宸极失御！",
  ["$os_mou__zhenliang2"] = "犹思中兴之美，尚怀来苏之望！",
}

zhenliang:addEffect("active", {
  anim_type = "switch",
  prompt = "#os_mou__zhenliang-damage",
  can_use = function(self, player)
    return player:usedSkillTimes(zhenliang.name, Player.HistoryPhase) < 1 and player:getSwitchSkillState(zhenliang.name) == fk.SwitchYang
  end,
  card_filter = function(self, player, to_select, selected)
    local cid = player:getPile("$os_mou__duty")[1]
    if not cid then return end
    return Fk:getCardById(cid).color == Fk:getCardById(to_select).color and not player:prohibitDiscard(to_select)
  end,
  target_num = 1,
  target_filter = function(self, player, to_select, selected, cards)
    return #selected == 0 and player:inMyAttackRange(to_select, nil, cards) and #cards == math.max(1, math.abs(player.hp - to_select.hp))
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, zhenliang.name, player, player)
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = zhenliang.name,
      }
    end
  end,
})

local spec = {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhenliang.name) and
      player:getSwitchSkillState(zhenliang.name) == fk.SwitchYin and
      player.room:getCurrent() ~= player and
      #player:getPile("$os_mou__duty") > 0 and
      data.card.type == Fk:getCardById(player:getPile("$os_mou__duty")[1]).type
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 2,
      prompt = "#os_mou__zhenliang-choose",
      skill_name = zhenliang.name,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(event:getCostData(self).tos) do
      if not p.dead then
        p:drawCards(2, zhenliang.name)
      end
    end
  end,
}
zhenliang:addEffect(fk.CardUseFinished, spec)
zhenliang:addEffect(fk.CardRespondFinished, spec)

return zhenliang
