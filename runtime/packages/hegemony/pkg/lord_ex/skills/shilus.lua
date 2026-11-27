
local shilus = fk.CreateSkill {
  name = "shilus",
}

Fk:loadTranslationTable {
  ["shilus"] = "嗜戮",
  [":shilus"] = "当一名角色死亡时，你可以将其所有武将牌置于你的武将牌旁，称为“戮”；" ..
  "若杀死其的角色为你，你可以移除一名与其势力相同的角色的副将牌并置为“戮”。",

  ["@&massacre"] = "戮",
  ["#shilus-invoke"] = "嗜戮：是否获得 %dest 的武将牌作为“戮”？",
  ["#shilus-choose"] = "嗜戮：你可以移除一名角色的副将牌，并置为“戮”",

  ["$shilus1"] = "以杀立威，谁敢反我？",
  ["$shilus2"] = "将这些乱臣贼子，尽皆诛之！",
}

local H = require "packages.hegemony.util"

shilus:addEffect(fk.Death, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shilus.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = shilus.name,
      prompt = "#shilus-invoke::" .. target.id,
    }) then
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    local general, deputyGeneral = H.getActualGeneral(target), H.getActualGeneral(target, true)
    if general and general ~= "" and not general:startsWith("blank_") then
      room:findGeneral(general)
      table.insert(cards, general)
    end
    if deputyGeneral and deputyGeneral ~= "" and not deputyGeneral:startsWith("blank_") then
      room:findGeneral(deputyGeneral)
      table.insert(cards, deputyGeneral)
    end
    if #cards > 0 then
      local generals = player:getTableMark("@&massacre")
      table.insertTableIfNeed(generals, cards)
      room:setPlayerMark(player, "@&massacre", generals)
    end
    if data.killer == player then
      local targets = table.filter(room:getAlivePlayers(false), function (p)
        return H.compareKingdomWith(target, p) and
          H.getActualGeneral(p, true) and not H.getActualGeneral(p, true):startsWith("blank_")
      end)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = shilus.name,
          prompt = "#shilus-choose",
          cancelable = true,
        })
        if #to > 0 then
          to = to[1]
          deputyGeneral = H.getActualGeneral(to, true)
          room:findGeneral(deputyGeneral)
          room:addTableMarkIfNeed(player, "@&massacre", deputyGeneral)
          H.removeGeneral(to, true)
        end
      end
    end
  end,
})

shilus:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:returnToGeneralPile(player:getTableMark("@&massacre"))
  room:setPlayerMark(player, "@&massacre", 0)
end)

return shilus
