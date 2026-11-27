
local qiance = fk.CreateSkill {
  name = "ld__qiance",
}

Fk:loadTranslationTable {
  ["ld__qiance"] = "谦策",
  [":ld__qiance"] = "与你势力相同的角色使用锦囊牌指定目标后，其可以令其中的大势力角色不能响应此牌。",

  ["#ld__qiance-ask"] = "谦策：是否令所有大势力角色不能响应此牌",

  ["$ld__qiance1"] = "开言纳谏，社稷之福。",
  ["$ld__qiance2"] = "如此如此，敌军自破！",
}

local H = require "packages.hegemony.util"

qiance:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    return H.compareKingdomWith(target, player) and player:hasSkill(qiance.name) and data.card:isCommonTrick()
        and (player:hasShownSkill(qiance.name) or target == player)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(target, { skill_name = qiance.name, prompt = "#ld__qiance-ask" })
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(data.tos) do
      if H.isBigKingdomPlayer(p) then
        data:setDisresponsive(p)
      end
    end
  end,
})

return qiance
