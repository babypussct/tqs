
local xiongsuan = fk.CreateSkill{
  name = "xiongsuan",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["xiongsuan"] = "凶算",
  [":xiongsuan"] = "限定技，出牌阶段，你可以弃置一张手牌并选择与你势力相同的一名角色，"..
  "你对其造成1点伤害，然后你摸三张牌，选择其一个已发动过的限定技，令该技能于此回合结束后视为未发动过。",

  ["#xiongsuan"] = "凶算：弃一张手牌，对一名角色造成1点伤害，你摸三张牌并重置其一个限定技",
  ["#xiongsuan-reset"] = "凶算：请重置 %dest 的一项技能",

  ["$xiongsuan1"] = "此战虽凶，得益颇高。",
  ["$xiongsuan2"] = "谋算计策，吾二人尚有险招。",
}

local H = require "packages.hegemony.util"

xiongsuan:addEffect("active", {
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(xiongsuan.name, Player.HistoryGame) == 0
  end,
  card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 1 and table.contains(player:getCardIds("h"), to_select) and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and H.compareKingdomWith(to_select, player)
  end,
  on_use = function (self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, xiongsuan.name, player, player)
    if player.dead or target.dead then return false end
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = xiongsuan.name,
    }
    if player.dead then return false end
    player:drawCards(3, xiongsuan.name)
    if player.dead or target.dead then return false end
    local skills = table.filter(target.player_skills, function(s)
      return s:hasTag(Skill.Limited) and target:usedSkillTimes(s.name, Player.HistoryGame) > 0
    end)
    if #skills == 0 then return false end
    local skillNames = table.map(skills, Util.NameMapper)
    local skill = room:askToChoice(player, {
      choices = skillNames,
      skill_name = xiongsuan.name,
      prompt = "#xiongsuan-reset::" .. target.id,
    })
    room:sendLog{
      type = "#Choice",
      from = player.id,
      arg = skill,
    }
    room:setPlayerMark(player, "xiongsuan-turn", { skill, target })
  end,
})

xiongsuan:addEffect(fk.TurnEnd, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("xiongsuan-turn") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    local skill = player:getMark("_xiongsuan-turn")[1]
    target = player:getMark("_xiongsuan-turn")[2]
    target:addSkillUseHistory(skill, -1)
  end,
})

return xiongsuan
