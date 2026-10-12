local jilun = fk.CreateSkill {
  name = "os__jilun"
}

Fk:loadTranslationTable{
  ["os__jilun"] = "机论",
  [":os__jilun"] = "当你受到伤害后，你可选择一项：1.摸X张牌（X为以“急筹”使用过的锦囊牌数，至少为1至多为5）；"..
  "2.视为使用一种以“急筹”使用过的牌（每牌名限一次）。",

  ["os__jilun_draw"] = "摸%arg张牌",
  ["@$os__jilun"] = "机论",
  ["os__jilun_use"] = "视为使用一种以“急筹”使用过的牌（每牌名限一次）",
  ["#os__jilun-ask"] = "机论：请选择一项",

  ["$os__jilun1"] = "时移不移，违天之祥也。",
  ["$os__jilun2"] = "民望不因，违人之咎也。",
}

jilun:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_cost = function(self, event, target, player)
    local num = #player:getTableMark("@$os__jichou")
    local choices = { "os__jilun_draw:::" .. math.min(math.max(num, 1), 5), "Cancel" }
    if #player:getViewAsCardNames(jilun.name, player:getTableMark("@$os__jilun")) > 0 then
      table.insert(choices, 2, "os__jilun_use")
    end
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = jilun.name,
      prompt = "#os__jilun-ask",
    })
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = jilun.name
    local room = player.room
    local choice = event:getCostData(self)
    if choice == "os__jilun_use" then
      local use = room:askToUseVirtualCard(player, {
        name = player:getTableMark("@$os__jilun"),
        skill_name = skillName,
        prompt = "os__jilun_use",
        cancelable = false,
      })
      if use then
        room:removeTableMark(player, "@$os__jilun", use.card.name)
      end
    else
      local num = #player:getTableMark("@$os__jichou")
      player:drawCards(math.min(math.max(num, 1), 5), skillName)
    end
  end,
})

return jilun
