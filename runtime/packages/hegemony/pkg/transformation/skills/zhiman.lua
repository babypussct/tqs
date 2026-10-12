local zhiman = fk.CreateSkill{
  name = "ld__zhiman",
}

Fk:loadTranslationTable{
  ["ld__zhiman"] = "制蛮",
  [":ld__zhiman"] = "当你对其他角色造成伤害时，你可防止此伤害，你获得其装备区或判定区里的一张牌。若其与你势力相同，你可令其选择是否变更副将。",

  ["#ld__zhiman-invoke"] = "制蛮：你可以防止对 %dest 造成的伤害，获得其场上的一张牌。若其与你势力相同，你可令其选择是否变更副将",
  ["ld__zhiman_transform"] = "令%dest选择是否变更副将",

  ["$ld__zhiman1"] = "兵法谙熟于心，取胜千里之外！",
  ["$ld__zhiman2"] = "丞相多虑，且看我的！",
}

local H = require "packages.hegemony.util"
zhiman:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhiman.name) and data.to ~= player
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zhiman.name,
      prompt = "#ld__zhiman-invoke::"..data.to.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    local target = data.to
    if #target:getCardIds("ej") > 0 then -- 开摆！
      local card = room:askToChooseCard(player, {
        target = target,
        flag = "ej",
        skill_name = zhiman.name,
      })
      room:obtainCard(player, card, true, fk.ReasonPrey)
    end
    if H.compareKingdomWith(target, player)
      and room:askToChoice(player, {
        choices = {"ld__zhiman_transform::" .. target.id, "Cancel"},
        skill_name = zhiman.name,
        prompt = "ld__zhiman_transform::" .. target.id,
      }) ~= "Cancel"
      and room:askToChoice(target, {
        choices = {"transformDeputy", "Cancel"},
        skill_name = zhiman.name,
      }) ~= "Cancel" then
        H.transformGeneral(room, target)
    end
  end
})

return zhiman
