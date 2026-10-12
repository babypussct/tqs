local xuechang = fk.CreateSkill {
  name = "os__xuechang",
}

Fk:loadTranslationTable{
  ["os__xuechang"] = "血偿",
  [":os__xuechang"] = "出牌阶段限两次，你可以摸一张牌并与一名其他角色拼点，若你赢，你获得其至多两张牌，若其中有装备牌，" ..
  "则你视为对其使用一张【杀】；若你没赢，你受到其造成的1点伤害，你下次对其造成的伤害+1。",

  ["#os__xuechang"] = "血偿：摸一张牌并与一名角色拼点，若你赢获得其牌，没赢你受到其伤害",

  ["$os__xuechang1"] = "风尘难掩忠魂血，杀尽宦祸不得偿！",
  ["$os__xuechang2"] = "霜刃绚练，血舞婆娑。",
}

xuechang:addEffect("active", {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#os__xuechang",
  times = function (self, player)
    return player.phase == Player.Play and 2 - player:usedSkillTimes(xuechang.name, Player.HistoryPhase) or -1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(xuechang.name, Player.HistoryPhase) < 2
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and player:canPindian(to_select) and to_select ~= player
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = xuechang.name
    local player = effect.from
    local target = effect.tos[1]
    player:drawCards(1, xuechang.name)
    if player.dead or target.dead or not player:canPindian(target) then return end
    local pindian = player:pindian({target}, skillName)
    if player.dead then return end
    if pindian.results[target].winner == player then
      if target:isNude() then return false end
      local cards = room:askToChooseCards(player, {
        min = 1,
        max = 2,
        target = target,
        flag = "he",
        skill_name = skillName,
      })
      local yes = table.find(cards, function (id)
        return Fk:getCardById(id).type == Card.TypeEquip
      end)
      room:obtainCard(player, cards, false, fk.ReasonPrey, player, skillName)
      if yes and not player.dead and not target.dead then
        room:useVirtualCard("slash", nil, player, target, skillName, true)
      end
    else
      room:damage{
        from = target,
        to = player,
        damage = 1,
        skillName = skillName,
      }
      room:addPlayerMark(player, "_os__xuechang+" .. target.id, 1)
    end
  end,
})

xuechang:addEffect(fk.DamageCaused, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("_os__xuechang+" .. data.to.id) > 0
  end,
  on_use = function(self, event, target, player, data)
    local damageBuff = player:getMark("_os__xuechang+" .. data.to.id)
    player.room:setPlayerMark(player, "_os__xuechang+" .. data.to.id, 0)
    data:changeDamage(damageBuff)
  end,
})

return xuechang
