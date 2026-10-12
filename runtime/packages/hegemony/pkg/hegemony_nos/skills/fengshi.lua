
local fengshi = fk.CreateSkill{
  name = "nos_heg__fengshi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["nos_heg__fengshi"] = "锋矢",
  [":nos_heg__fengshi"] = "阵法技，若你是围攻角色，则此围攻角色使用【杀】指定被围攻角色为目标后，你令被围攻角色角色弃置装备区里的一张牌。",

  ["#nos_heg__fengshi-discard"] = "锋矢：弃置装备区里的一张牌",

  ["$nos_heg__fengshi1"] = "大军压境，还不卸甲受降！",
  ["$nos_heg__fengshi2"] = "放下兵器，饶你不死！",
}

local H = require "packages.hegemony.util"

fengshi:addEffect("arraysummon", {
  array_type = "siege",
})

fengshi:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return H.inSiegeRelation(target, player, data.to) and player:hasShownSkill(fengshi.name) and
      data.card.trueName == "slash" and #data.to:getCardIds("e") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:askToDiscard(data.to, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = fengshi.name,
      pattern = ".|.|.|equip",
      prompt = "#nos_heg__fengshi-discard",
      cancelable = false,
    })
  end,
})

return fengshi
