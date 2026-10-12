local fangzhu = fk.CreateSkill {
  name = "mobile_qianlong__fangzhu",
  tags = { Skill.Permanent },
}

Fk:loadTranslationTable{
  ["mobile_qianlong__fangzhu"] = "放逐",
  [":mobile_qianlong__fangzhu"] = "持恒技，出牌阶段限一次，你可以选择一项令一名其他角色执行" ..
  "（不可选择从你的上个回合开始至今期间你上次以此法选择的角色）：1.直到其下个回合结束，其不能使用除锦囊牌外的手牌；2.直到其下个回合结束，其所有技能失效。",

  ["#mobile_qianlong__fangzhu"] = "放逐：你可以选择一名角色，对其进行限制",
  ["@mobile_qianlong__fangzhu_limit"] = "放逐限",
  ["@@mobile_qianlong__fangzhu_skill_nullified"] = "放逐 技能失效",
  ["mobile_qianlong_only_trick"] = "只可使用锦囊牌",
  ["mobile_qianlong_nullify_skill"] = "武将技能失效",

  ["$mobile_qianlong__fangzhu1"] = "卿当竭命纳忠，何为此逾矩之举！",
  ["$mobile_qianlong__fangzhu2"] = "朕继文帝风流，亦当效其权略！",
}

fangzhu:addEffect("active", {
  anim_type = "control",
  prompt = "#mobile_qianlong__fangzhu",
  card_num = 0,
  target_num = 1,
  interaction = UI.ComboBox { choices = {
      "mobile_qianlong_only_trick",
      "mobile_qianlong_nullify_skill",
    } },
  can_use = function(self, player)
    return player:usedSkillTimes(fangzhu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and
      player:getMark("mobile_qianlong__fangzhu_target") ~= to_select.id and
      player:getMark("mobile_qianlong__fangzhu_target-turn") ~= to_select.id
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    if player:getMark("mobile_qianlong__fangzhu_target-turn") ~= 0 then
      room:setPlayerMark(player, "mobile_qianlong__fangzhu_target-turn", 0)
    end
    room:setPlayerMark(player, "mobile_qianlong__fangzhu_target", target.id)

    local choice = self.interaction.data
    if choice == "mobile_qianlong_only_trick" then
      room:setPlayerMark(target, "@mobile_qianlong__fangzhu_limit", "trick_char")
    elseif choice == "mobile_qianlong_nullify_skill" then
      room:setPlayerMark(target, "@@mobile_qianlong__fangzhu_skill_nullified", 1)
    end
  end,
})
fangzhu:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("mobile_qianlong__fangzhu_target") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local fangzhuTarget = player:getMark("mobile_qianlong__fangzhu_target")
    room:setPlayerMark(player, "mobile_qianlong__fangzhu_target", 0)
    room:setPlayerMark(player, "mobile_qianlong__fangzhu_target-turn", fangzhuTarget)
  end,
})
fangzhu:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function (self, event, target, player, data)
    return target == player and
      table.find({ "@mobile_qianlong__fangzhu_limit", "@@mobile_qianlong__fangzhu_skill_nullified" }, function(markName)
        return player:getMark(markName) ~= 0
      end)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, markName in ipairs({ "@mobile_qianlong__fangzhu_limit", "@@mobile_qianlong__fangzhu_skill_nullified" }) do
      room:setPlayerMark(player, markName, 0)
    end
  end,
})
fangzhu:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local typeLimited = player:getMark("@mobile_qianlong__fangzhu_limit")
    if type(typeLimited) == "string" and typeLimited ~= card:getTypeString() .. "_char" then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds("h"), id)
      end)
    end
  end,
})
fangzhu:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    return
      from:getMark("@@mobile_qianlong__fangzhu_skill_nullified") > 0 and skill:isPlayerSkill(from, true)
  end
})

return fangzhu
