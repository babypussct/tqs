
local jianxiong = fk.CreateSkill{
  name = "ofl_heg__jianxiong",
}

Fk:loadTranslationTable{
  ["ofl_heg__jianxiong"] = "奸雄",
  [":ofl_heg__jianxiong"] = "当你受到伤害后，你可以选择一项：1.获得对造成伤害的牌；2.摸一张牌。",

  ["ofl_heg__jianxiong_prey"] = "获得%arg",

  ["$ofl_heg__jianxiong1"] = "宁教我负天下人，休教天下人负我！",
  ["$ofl_heg__jianxiong2"] = "吾好梦中杀人！",
}

jianxiong:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = { "draw1", "Cancel" }
    if data.card and room:getCardArea(data.card) == Card.Processing then
      table.insert(choices, 1, "ofl_heg__jianxiong_prey:::"..data.card:toLogString())
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = jianxiong.name,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == "draw1" then
      player:drawCards(1, jianxiong.name)
    else
      room:obtainCard(player, data.card, true, fk.ReasonJustMove, player, jianxiong.name)
    end
  end,
})

return jianxiong
