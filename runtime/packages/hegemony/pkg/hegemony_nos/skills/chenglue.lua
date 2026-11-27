
local chenglue = fk.CreateSkill {
  name = "nos_heg__chenglue",
}

Fk:loadTranslationTable {
  ["nos_heg__chenglue"] = "成略",
  [":nos_heg__chenglue"] = "当势力与你相同的角色使用的牌结算结束后，若此牌目标数大于1，你可以令其摸一张牌，"..
  "然后若你受到过此牌造成的伤害，你可以选择一名势力与你相同、武将牌均明置且没有阴阳鱼标记的角色，令其获得一枚“阴阳鱼”标记。",

  ["#nos_heg__chenglue-draw"] = "成略：你可以令 %dest 摸一张牌",
  ["#nos_heg__chenglue-mark"] = "成略：你可以令一名角色获得一枚“阴阳鱼”标记",

  ["$nos_heg__chenglue1"] = "阿瞒，苦思之事，我早有良策。",
  ["$nos_heg__chenglue2"] = "策略已有，按部就班即可得胜。",
}

local H = require "packages.hegemony.util"

chenglue:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chenglue.name) and
      H.compareKingdomWith(target, player) and #data.tos > 1 and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = chenglue.name,
      prompt = "#nos_heg__chenglue-draw::" .. target.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    target:drawCards(1, chenglue.name)
    if player.dead then return end
    if data.damageDealt and data.damageDealt[player] then
      local targets = table.filter(room:getAlivePlayers(false), function(p)
        return H.compareKingdomWith(p, player) and H.allGeneralsRevealed(p) and p:getMark("@!!yinyangfish") == 0
      end)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#nos_heg__chenglue-mark",
          skill_name = chenglue.name,
          cancelable = true,
        })
        if #to > 0 then
          H.addHegMark(to[1], "yinyangfish")
        end
      end
    end
  end,
})

return chenglue
