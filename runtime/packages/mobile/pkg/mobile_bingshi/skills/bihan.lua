
local bihan = fk.CreateSkill {
  name = "bihan",
}

Fk:loadTranslationTable{
  ["bihan"] = "蔽扞",
  [":bihan"] = "一名角色受到【杀】的伤害时，你可以令你或其将手牌弃至当前体力值，令此【杀】伤害-1。",

  ["#bihan-choose"] = "蔽扞：令你或 %dest 将手牌弃至当前体力值，此【杀】对其伤害-1",

  ["$bihan1"] = "江东有我在日，孙氏自然不倾！",
  ["$bihan2"] = "少主如若有失，我罪万死难赎！",
}

bihan:addEffect(fk.DamageInflicted, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(bihan.name) and
      data.card and data.card.trueName == "slash" and
      table.find({ player, data.to }, function (p)
        return p:getHandcardNum() > p.hp
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter({ player, data.to }, function (p)
      return p:getHandcardNum() > p.hp
    end)
    if #table.filter(player:getCardIds("h"), function (id)
      return player:prohibitDiscard(id)
    end) > player.hp then
      table.removeOne(targets, player)
    end
    if #targets == 0 then
      room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = bihan.name,
        pattern = "false",
        prompt = "#bihan-choose::"..data.to.id,
        cancelable = true,
      })
    else
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = bihan.name,
        prompt = "#bihan-choose::"..data.to.id,
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, { tos = to })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if #table.filter(player:getCardIds("h"), function (id)
      return player:prohibitDiscard(id)
    end) > player.hp then
      return
    end
    room:askToDiscard(to, {
      min_num = to:getHandcardNum() - to.hp,
      max_num = to:getHandcardNum() - to.hp,
      include_equip = false,
      skill_name = bihan.name,
      cancelable = false,
    })
    data:changeDamage(-1)
  end,
})

return bihan
