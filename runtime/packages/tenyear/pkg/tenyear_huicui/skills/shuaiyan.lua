local shuaiyan = fk.CreateSkill {
  name = "shuaiyan",
}

Fk:loadTranslationTable{
  ["shuaiyan"] = "率言",
  [":shuaiyan"] = "其他角色摸牌阶段或弃牌阶段结束时，若其手牌数与你相等，你可以摸一张牌或弃置其一张牌。"..
  "你的摸牌阶段或弃牌阶段结束时，你可以摸X张牌（X为手牌数与你相等的角色数）。",

  ["shuaiyan_discard"] = "弃置%dest一张牌",

  ["$shuaiyan1"] = "将军拥众十万，安能坐观豪杰并争？",
  ["$shuaiyan2"] = "我为将军计，不若举州以附曹公。",
}

shuaiyan:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shuaiyan.name) and
      (target.phase == Player.Draw or target.phase == Player.Discard) and
      target:getHandcardNum() == player:getHandcardNum()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if target == player then
      if room:askToSkillInvoke(player, {
        skill_name = shuaiyan.name,
      }) then
        event:setCostData(self, nil)
        return true
      end
    else
      local choices = { "draw1", "shuaiyan_discard::"..target.id, "Cancel" }
      if target:isNude() then
        table.remove(choices, 2)
      end
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = shuaiyan.name
      })
      if choice ~= "Cancel" then
        event:setCostData(self, { tos = {target}, choice = choice })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if target == player then
      local n = #table.filter(room.alive_players, function (p)
        return p:getHandcardNum() == player:getHandcardNum()
      end)
      player:drawCards(n, shuaiyan.name)
    else
      local choice = event:getCostData(self).choice
      if choice == "draw1" then
        player:drawCards(1, shuaiyan.name)
      else
        local card = room:askToChooseCard(player, {
          target = target,
          flag = "he",
          skill_name = shuaiyan.name,
        })
        room:throwCard(card, shuaiyan.name, target, player)
      end
    end
  end,
})

return shuaiyan
