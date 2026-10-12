local shihe = fk.CreateSkill {
  name = "shihe",
}

Fk:loadTranslationTable{
  ["shihe"] = "势吓",
  [":shihe"] = "出牌阶段限一次，你可以与一名其他角色拼点，若你赢，直到其下回合结束，防止其对友方角色造成的伤害；没赢，你随机弃置一张牌。",

  ["#shihe"] = "势吓：你可以拼点，若赢，防止其对你造成伤害；若没赢，你随机弃置一张牌",
  ["@@shihe"] = "势吓",

  ["$shihe1"] = "此举关乎福祸，还请峭王明察！",
  ["$shihe2"] = "汉乃天朝上国，岂是辽东下郡可比？",
}

shihe:addEffect("active", {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#shihe",
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(shihe.name) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and player:canPindian(to_select)
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = shihe.name
    local player = effect.from
    local target = effect.tos[1]
    local pindian = player:pindian({ target }, skillName)
    if pindian.results[target].winner == player then
      if not target:isAlive() then
        return false
      end

      local mark = target:getTableMark("@@shihe")
      table.insertIfNeed(mark, player.id)
      if room:isGameMode("1v2_mode") or room:isGameMode("2v2_mode") then
        for _, p in ipairs(room:getOtherPlayers(player, false)) do
          if p.role == player.role then
            table.insertIfNeed(mark, p.id)
          end
        end
      end
      room:setPlayerMark(target, "@@shihe", mark)
    elseif player:isAlive() and not player:isNude() then
      local id = room:tableRandomPick(player:getCardIds("he"))
      room:throwCard({ id }, skillName, player, player)
    end
  end,
})

shihe:addEffect(fk.DetermineDamageCaused, {
  is_delay_effect = true,
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return
      target and
      target:getMark("@@shihe") ~= 0 and
      data.to == player and
      table.contains(target:getMark("@@shihe"), player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
  end,
})

shihe:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@shihe") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@shihe", 0)
  end,
})

return shihe
