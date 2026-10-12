
local jvjiang = fk.CreateSkill {
  name = "m_heg__jvjiang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["m_heg__jvjiang"] = "据江",
  [":m_heg__jvjiang"] = "锁定技，若吴势力不为大势力，你的同势力角色指定你为目标的非伤害牌（不含装备牌与延时锦囊牌）额外结算一次。",

  ["$m_heg__jvjiang1"] = "三江为府，太仓为库，此吴之基也！",
  ["$m_heg__jvjiang2"] = "孤统东南之地，辎财永不竭矣！",
  ["$m_heg__jvjiang3"] = "孤力难分成败，何不坐待其机？",
  ["$m_heg__jvjiang4"] = "孤如江中石，观英雄如东去之水！",
}

local H = require "packages.hegemony.util"

jvjiang:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jvjiang.name) and
      not data.card.is_damage_card and data.card.type ~= Card.TypeEquip and data.card.sub_type ~= Card.SubtypeDelayedTrick and
      table.contains(data.tos, player) and H.compareKingdomWith(player, data.from) and
      not table.find(player.room.alive_players, function (p)
        return H.isBigKingdomPlayer(p) and H.getKingdom(p) == "wu"
      end)
  end,
  on_use = function(self, event, target, player, data)
    data.additionalEffect = (data.additionalEffect or 0) + 1
  end,
})

return jvjiang
