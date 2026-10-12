
local keshou = fk.CreateSkill{
  name = "nos_heg__keshou",
}

Fk:loadTranslationTable{
  ["nos_heg__keshou"] = "恪守",
  [":nos_heg__keshou"] = "当你受到伤害时，你可以弃置两张颜色相同的手牌，令此伤害-1。"..
  "然后若没有与你势力相同的其他角色，你进行一次判定，若结果为红色，你摸一张牌。",

  ["#nos_heg__keshou-invoke"] = "恪守：是否弃置两张颜色相同的牌，令你受到的%arg点伤害-1",

  ["$nos_heg__keshou1"] = "仁以待民，自处不败之势。",
  ["$nos_heg__keshou2"] = "宽济百姓，则得战前养备之机。",
}

keshou:addAuxActiveSkill("#nos_heg__keshou_active", {
  card_num = 2,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 or
      table.every(selected, function(id)
        return Fk:getCardById(to_select).color == Fk:getCardById(id).color
      end)
  end,
})

local H = require "packages.hegemony.util"

keshou:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(keshou.name) and
      player:getHandcardNum() > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "#nos_heg__keshou_active",
      prompt = "#nos_heg__keshou-invoke:::" .. data.damage,
    })
    if success and dat then
      event:setCostData(self, { cards = dat.cards })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, keshou.name, player, player)
    data:changeDamage(-1)
    if not player.dead and H.getKingdomPlayersNum(room)[H.getKingdom(player)] == 1 then
      local judge = {
        who = player,
        reason = keshou.name,
        pattern = ".|.|red",
      }
      room:judge(judge)
      if judge:matchPattern() and not player.dead then
        player:drawCards(1, keshou.name)
      end
    end
  end,
})

return keshou
