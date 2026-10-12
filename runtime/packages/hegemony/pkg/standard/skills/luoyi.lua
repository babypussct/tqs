
local luoyi = fk.CreateSkill{
  name = "hs__luoyi",
}

Fk:loadTranslationTable{
  ["hs__luoyi"] = "裸衣",
  [":hs__luoyi"] = "摸牌阶段结束时，你可弃置一张牌，令你于此回合内执行【杀】或【决斗】的效果造成伤害时，此伤害+1。",

  ["#hs__luoyi-invoke"] = "裸衣：你可以弃置一张牌，本回合【杀】或【决斗】造成伤害+1",
  ["@@hs__luoyi"] = "裸衣",

  ["$hs__luoyi1"] = "脱！",
  ["$hs__luoyi2"] = "谁来与我大战三百回合？",
}

luoyi:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player,{
      min_num = 1,
      max_num = 1,
      cancelable = true,
      skill_name = luoyi.name,
      prompt = "#hs__luoyi-invoke",
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@@hs__luoyi", 1)
    room:throwCard(event:getCostData(self).cards, luoyi.name, player, player)
  end,
})

luoyi:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@hs__luoyi") > 0 and
      data.card and (data.card.trueName == "slash" or data.card.name == "duel") and not data.chain
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(player:getMark("@@hs__luoyi"))
  end,
})

return luoyi

