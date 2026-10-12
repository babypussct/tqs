
local chuanxin = fk.CreateSkill{
  name = "chuanxin",
}

Fk:loadTranslationTable{
  ["chuanxin"] = "穿心",
  [":chuanxin"] = "当你于出牌阶段内使用【杀】或【决斗】对目标角色造成伤害时，若其与你势力不同且有副将，你可以防止此伤害。"..
  "若如此做，该角色选择一项：1.弃置装备区里的所有牌，失去1点体力；2.移除副将。",

  ["#chuanxin-invoke"] = "穿心：你可以防止对 %dest 造成的伤害，其选择弃置装备并失去体力，或移除副将",
  ["chuanxin_discard"] = "弃置所有装备，失去1点体力",
  ["chuanxin_deputy"] = "移除副将%arg",

  ["$chuanxin1"] = "一箭穿心，哪里可逃？",
  ["$chuanxin2"] = "穿心之痛，细细品吧，哈哈哈哈！",
}

local H = require "packages.hegemony.util"

chuanxin:addEffect(fk.DetermineDamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and target:hasSkill(chuanxin.name) and player.phase == Player.Play and
      data.card and table.contains({"slash", "duel"}, data.card.trueName) and not data.chain and
      H.compareExpectedKingdomWith(player, data.to, true) and H.hasGeneral(data.to, true) and not data.to.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = chuanxin.name,
      prompt = "#chuanxin-invoke::" .. data.to.id,
    }) then
      event:setCostData(self, { tos = { data.to } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    local all_choices = { "chuanxin_discard", "chuanxin_deputy:::" .. H.getActualGeneral(player, true) }
    local choices = table.clone(all_choices)
    if #data.to:getCardIds("e") == 0 then
      table.remove(choices, 1)
    end
    local choice = room:askToChoice(data.to, {
      choices = choices,
      skill_name = chuanxin.name,
      all_choices = all_choices,
    })
    if choice:startsWith("chuanxin_deputy") then
      H.removeGeneral(data.to, true)
    else
      data.to:throwAllCards("e", chuanxin.name)
      if not data.to.dead then
        room:loseHp(data.to, 1, chuanxin.name)
      end
    end
  end,
})

return chuanxin
