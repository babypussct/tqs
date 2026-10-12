
local hanyong = fk.CreateSkill{
  name = "mobile__hanyong",
}

Fk:loadTranslationTable{
  ["mobile__hanyong"] = "悍勇",
  [":mobile__hanyong"] = "你使用牌指定多名角色为目标后，若你已受伤，你可以选择一项：1.摸两张牌；2.令此牌伤害+1；背水：获得1个“燃”。",

  ["mobile__hanyong_damage"] = "令此牌伤害+1",
  ["mobile__hanyong_beishui"] = "背水：获得1个“燃”",

  ["$mobile__hanyong1"] = "找死！",
  ["$mobile__hanyong2"] = "这就让你们见识见识！哈哈……",
}

hanyong:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hanyong.name) and
      data.firstTarget and #data.use.tos > 1 and player:isWounded()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = { "draw2", "mobile__hanyong_damage", "mobile__hanyong_beishui" },
      skill_name = hanyong.name,
      cancelable = true,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice ~= "mobile__hanyong_damage" then
      player:drawCards(2, hanyong.name)
    end
    if choice ~= "draw2" then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
    if choice == "mobile__hanyong_beishui" and player:hasSkill("mobile__ranshang", true) then
      room:addPlayerMark(player, "@wutugu_ran", 1)
    end
  end,
})

return hanyong
