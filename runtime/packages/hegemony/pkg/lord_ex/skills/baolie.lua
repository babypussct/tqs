local baolie = fk.CreateSkill {
  name = "ld__baolie",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["ld__baolie"] = "豹烈",
  [":ld__baolie"] = "锁定技，①出牌阶段开始时，你令所有与你势力不同且攻击范围内含有你的角色依次对你使用一张【杀】，否则你弃置其一张牌。②你对体力值不小于你的角色使用【杀】无距离与次数限制。",
  ["#ld__baolie-use"] = "豹烈：对%src使用一张【杀】，否则其弃置你一张牌",

  ["$ld__baolie1"] = "废话少说，受死吧，喝！",
  ["$ld__baolie2"] = "当今曹营之将，一个能打的都没有！",
}

local H = require "packages.hegemony.util"

baolie:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(baolie.name) and player.phase == Player.Play and
        H.getGeneralsRevealedNum(player) > 0
        and table.find(player.room.alive_players, function(p)
          return (H.compareKingdomWith(p, player, true)) and p:inMyAttackRange(player)
        end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p)
      return (H.compareKingdomWith(p, player, true)) and p:inMyAttackRange(player)
    end)
    if #targets == 0 then return end
    room:doIndicate(player.id, targets)
    for _, p in ipairs(targets) do
      if player.dead then return end
      local to = p
      if not to.dead then
        local use = room:askToUseCard(to, {
          card_name = "slash",
          pattern = "slash",
          skill_name = baolie.name,
          prompt = "#ld__baolie-use:" .. player.id,
          cancelable = true,
          extra_data = { exclusive_targets = { player.id } },
        })
        if use then
          use.extraUse = true
          room:useCard(use)
        elseif not to:isNude() then
          local card = room:askToChooseCard(player, {
            target = to,
            flag = "he",
            skill_name = baolie.name,
          })
          room:throwCard({ card }, baolie.name, to, player)
        end
      end
    end
  end,
})

baolie:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill(baolie.name) and to and to.hp >= player.hp and skill.trueName == "slash_skill"
  end,
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(baolie.name) and to and to.hp >= player.hp and skill.trueName == "slash_skill"
  end,
})

return baolie
