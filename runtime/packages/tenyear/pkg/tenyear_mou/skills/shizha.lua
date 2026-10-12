local shizha = fk.CreateSkill {
  name = "shizha",
}

Fk:loadTranslationTable{
  ["shizha"] = "识诈",
  [":shizha"] = "每回合限一次，有角色体力变化后，你可观看牌堆顶三张牌并选择其中一张牌获得并秘密记录此牌名，"..
    "直至本轮结束该牌名牌被使用时移除记录牌名，你可令此牌无效。",

  ["@[private]$shizha-round"] = "识诈",
  ["#shizha-invoke"] = "识诈：是否令 %dest 使用的%arg无效？",

  ["$shizha1"] = "不好，江东鼠辈欲趁东风来袭！",
  ["$shizha2"] = "江上起东风，恐战局生变。",
}

local U = require "packages.utility.utility"

---@param player ServerPlayer
local shizhaOnUse = function(_, _, _, player, _)
  local room = player.room
  local ids = room:getNCards(3)
  room:turnOverCardsFromDrawPile(player, ids, shizha.name, false)
  local id = room:askToChooseCard(player, {
    target = player,
    flag = {
      card_data = {
        { "shizha", ids }
      }
    },
    skill_name = shizha.name
  })
  local mark = U.getPrivateMark(player, "$shizha-round")
  if table.insertIfNeed(mark, Fk:getCardById(id).trueName) then
    U.setPrivateMark(player, "$shizha-round", mark)
  end
  room:obtainCard(player, id, false, fk.ReasonJustMove, player, shizha.name)
  table.removeOne(ids, id)
  room:returnCardsToDrawPile(player, ids, shizha.name, "top", false)
end

shizha:addEffect(fk.HpRecover, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shizha.name) and player:usedSkillTimes(shizha.name) == 0
  end,
  on_use = shizhaOnUse,
})

shizha:addEffect(fk.HpChanged, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return data.num <= 0 and player:hasSkill(shizha.name) and player:usedSkillTimes(shizha.name) == 0
  end,
  on_use = shizhaOnUse,
})

shizha:addEffect(fk.CardUsing, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shizha.name) and table.contains(U.getPrivateMark(player, "$shizha-round"), data.card.trueName)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = U.getPrivateMark(player, "$shizha-round")
    table.removeOne(mark, data.card.trueName)
    if #mark > 0 then
      U.setPrivateMark(player, "$shizha-round", mark)
    else
      room:setPlayerMark(player, "@[private]$shizha-round", 0)
    end
    if room:askToSkillInvoke(player, {
      skill_name = shizha.name,
      prompt = "#shizha-invoke::"..target.id..":"..data.card:toLogString(),
    }) then
      --data.toCard = nil
      --data:removeAllTargets()
      data:setNullified()
    end
  end,
})

shizha:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, "@[private]$shizha-round", 0)
end)

return shizha
