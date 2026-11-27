
local baowei = fk.CreateSkill {
  name = "m_heg__baowei",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["m_heg__baowei"] = "暴威",
  [":m_heg__baowei"] = "锁定技，你使用【杀】指定目标后，若目标：1.主将未亮明，其不可响应此牌。2.副将未亮明或是士兵，此牌对其造成伤害+1。"..
  "乘势：所有势力与你相同，且武将牌有士兵的角色摸一张牌。",

  ["$m_heg__baowei1"] = "老夫面前，你又算是什么东西？",
  ["$m_heg__baowei2"] = "忠心难表？老夫自可剜之明辨！",
  ["$m_heg__baowei3"] = "将士们，举杯共庆这场杀戮！",
  ["$m_heg__baowei4"] = "来人！把这叛徒的血肉，赐给诸公享用！",
}

local H = require "packages.hegemony.util"

baowei:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasShownSkill(baowei.name) and
      data.card.trueName == "slash" and
      (data.to.general == "anjiang" or table.contains({ "anjiang", "blank_shibing", "blank_nvshibing" }, data.to.deputyGeneral))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local yes1 = data.to.general == "anjiang"
    local yes2 = table.contains({ "anjiang", "blank_shibing", "blank_nvshibing" }, data.to.deputyGeneral)
    if yes1 then
      data:setDisresponsive(data.to)
    end
    if yes2 then
      data.additionalDamage = (data.additionalDamage or 0) + 1
      if yes1 then
        local targets = table.filter(room:getAlivePlayers(), function (p)
          return H.compareKingdomWith(player, p) and
            (table.contains({ "blank_shibing", "blank_nvshibing" }, data.to.general) or
            table.contains({ "blank_shibing", "blank_nvshibing" }, data.to.deputyGeneral))
        end)
        for _, p in ipairs(targets) do
          if not p.dead then
            p:drawCards(1, baowei.name)
          end
        end
      end
    end
  end,
})

return baowei
