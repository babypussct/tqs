local hanjie = fk.CreateSkill{
  name = "hanjie",
}

Fk:loadTranslationTable{
  ["hanjie"] = "悍捷",
  [":hanjie"] = "其他角色回合开始时，若其体力值不小于你，你可以将一张黑色手牌当一张伤害牌对其使用。",

  ["#hanjie-invoke"] = "悍捷：你可以将一张黑色手牌当伤害牌对 %dest 使用",

  ["$hanjie1"] = "飞燕喋血无数，今日便再饮几条亡魂！",
  ["$hanjie2"] = "某家让汝三更死，谁敢留命到五更！",
}

hanjie:addEffect(fk.TurnStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      target ~= player and
      target.hp >= player.hp and
      target:isAlive() and
      player:hasSkill(hanjie.name) and
      not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player:getMark(hanjie.name) == 0 then
      local names = {}
      for _, name in ipairs(Fk:getAllCardNames("bt")) do
        if Fk:cloneCard(name).is_damage_card then
          table.insert(names, name)
        end
      end
      room:setPlayerMark(player, hanjie.name, names)
    end
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id).color == Card.Black
    end)
    if #cards == 0 then
      room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = hanjie.name,
        pattern = "false",
        prompt = "#hanjie-invoke::"..target.id,
        cancelable = true,
      })
    else
      local use = room:askToUseVirtualCard(player, {
        name = player:getTableMark(hanjie.name),
        skill_name = hanjie.name,
        prompt = "#hanjie-invoke::"..target.id,
        cancelable = true,
        extra_data = {
          bypass_distances = true,
          bypass_times = true,
          extraUse = true,
          exclusive_targets = { target.id },
        },
        card_filter = {
          n = 1,
          cards = cards,
        },
        skip = true,
      })
      if use then
        event:setCostData(self, {extra_data = use})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useCard(event:getCostData(self).extra_data)
  end,
})

return hanjie
