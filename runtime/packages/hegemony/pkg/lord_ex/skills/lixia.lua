local lixia = fk.CreateSkill {
  name = "ld__lixia",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["ld__lixia"] = "礼下",
  [":ld__lixia"] = "锁定技，其他势力角色的准备阶段，若你不在其攻击范围内，该角色须选择一项" ..
      "：1.令你摸一张牌；2.弃置你装备区内的一张牌，该角色失去1点体力。",

  ["ld__lixia_drawcards"] = "令 %src 摸一张牌",
  ["ld__lixia_loseHp"] = "弃置 %src 装备区内的一张牌并失去1点体力",

  ["$ld__lixia1"] = "将军真乃国之栋梁。",
  ["$ld__lixia2"] = "英雄可安身立命于交州之地。",
}

local H = require "packages.hegemony.util"

lixia:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(lixia.name) and not H.compareKingdomWith(player, target) and target ~= player
        and target.phase == Player.Start and not target.dead and not target:inMyAttackRange(player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    table.insert(choices, "ld__lixia_drawcards:" .. player.id)
    if not target.dead and #player:getCardIds("e") > 0 then
      table.insert(choices, "ld__lixia_loseHp:" .. player.id)
    end
    local choice = room:askToChoice(target, { choices = choices, skill_name = lixia.name })
    if choice == "ld__lixia_drawcards:" .. player.id then
      player:drawCards(1, lixia.name)
    elseif choice == "ld__lixia_loseHp:" .. player.id then
      if #player.player_cards[Player.Equip] > 0 then
        local id = room:askToChooseCard(target, {
          target = player,
          flag = "e",
          skill_name = lixia.name,
        })
        room:throwCard({ id }, lixia.name, player, target)
      end
      room:loseHp(target, 1, lixia.name)
    end
  end,
})

return lixia
