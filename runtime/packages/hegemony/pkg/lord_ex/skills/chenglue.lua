local chenglue = fk.CreateSkill {
  name = "ld__chenglue",
}

Fk:loadTranslationTable {
  ["ld__chenglue"] = "成略",
  [":ld__chenglue"] = "当与你势力相同的角色使用的牌结算结束后，若此牌目标数大于1，你可以令其摸一张牌，然后若你受到过此牌造成的伤害，"..
  "你可以选择一名与你势力相同、武将牌均明置且没有国战标记的角色，令其获得一枚“阴阳鱼”标记。",

  ["#ld__chenglue-ask"] = "成略：你可令 %src 摸一张牌",
  ["#ld__chenglue-give"] = "成略：你可以令一名角色获得一枚“阴阳鱼”标记",
  ["#ld__shicai_getyinyangfish"] = "%from 令 %to 获得了一枚<font color=\"#DC143C\"><b> 阴阳鱼标记",

  ["$ld__chenglue1"] = "阿瞒，苦思之事，我早有良策。",
  ["$ld__chenglue2"] = "策略已有，按部就班即可得胜。",
}

local H = require "packages.hegemony.util"

chenglue:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chenglue.name) and H.compareKingdomWith(target, player) and #data.tos > 1
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = chenglue.name, prompt = "#ld__chenglue-ask:" .. target.id })
  end,
  on_use = function(self, event, target, player, data)
    if target:isAlive() then
      target:drawCards(1, chenglue.name)
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.ld__chenglueUser = player.id
  end,
})

chenglue:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return ((data.extra_data or {}).ld__chenglueUser == player.id) and data.damageDealt and data.damageDealt[player] and
    not player.dead
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.filter(player.room.alive_players, function(p)
      return H.compareKingdomWith(p, player)
          and p:getMark("@!!yinyangfish") == 0 and p:getMark("@!!companion") == 0
          and p:getMark("@!!wild") == 0 and p:getMark("@!!vanguard") == 0 and H.allGeneralsRevealed(p)
    end)
    if #targets == 0 then return end
    local to = player.room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ld__chenglue-give",
      skill_name = chenglue.name,
      cancelable = true,
    })
    if #to == 1 then
      event:setCostData(self, { to = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    H.addHegMark(event:getCostData(self).to[1], "yinyangfish")
    player.room:sendLog {
      type = "#ld__shicai_getyinyangfish",
      from = player.id,
      to = { event:getCostData(self).to[1].id },
      toast = true,
    }
  end,
})

return chenglue
