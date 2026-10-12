local yimie = fk.CreateSkill {
  name = "heg__yimie",
  attached_skill_name = "heg__yimie_viewAs&",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["heg__yimie"] = "夷灭",
  [":heg__yimie"] = "锁定技，你的回合内，与处于濒死状态角色势力相同/势力不同的角色不能使用【桃】/可将一张<font color='red'>♥</font>手牌当【桃】对处于濒死状态的角色使用。",
  ["#heg__yimie_prompt_use_peach"] = "夷灭：你可将一张<font color='red'>♥</font>手牌对濒死状态角色使用",

  ["$heg__yimie1"] = "汝大逆不道，当死无赦!",
  ["$heg__yimie2"] = "斩草除根，灭其退路！",

}

local H = require "packages.hegemony.util"

local yimie_spec = {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local players = room.alive_players
    local simashis = table.filter(players, function(p) return p:hasShownSkill(yimie.name) end)
    local targets_map = {}
    for _, p in ipairs(players) do
      local will_attach = false
      for _, pid in ipairs(simashis) do
        if (p ~= pid and p.kingdom ~= "unknown") then
          will_attach = true
          break
        end
      end
      targets_map[p] = will_attach
    end
    for p, v in pairs(targets_map) do
      if v ~= p:hasSkill("heg__yimie_viewAs&") then
        room:handleAddLoseSkills(p, v and yimie.attached_skill_name or "-" .. yimie.attached_skill_name, nil, false, true)
      end
    end
  end,
}

yimie:addEffect("viewas", {
  pattern = "peach",
  prompt = "#heg__yimie_prompt_use_peach",
  card_filter = function(self, player, to_select, selected)
    return #selected < 1 and Fk:getCardById(to_select).suit == Card.Heart and
        table.contains(player:getCardIds("h"), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return nil end
    local card = Fk:cloneCard("peach")
    card:addSubcard(cards[1])
    card.skillName = yimie.name
    return card
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player, response)
    return not response and table.find(Fk:currentRoom().alive_players, function(p)
      return p.phase ~= Player.NotActive and p:hasShownSkill(yimie.name)
    end) and table.find(Fk:currentRoom().alive_players, function(p)
      return p.dying and H.compareKingdomWith(p, player, true)
    end)
  end
})

yimie:addEffect(fk.EnterDying, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_refresh = function(self, event, target, player, data)
    return player:hasShownSkill(yimie.name) and player.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, yimie.name)
    player:broadcastSkillInvoke(yimie.name)
  end,
})

yimie:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if card.name == "peach" then
      return table.find(Fk:currentRoom().alive_players, function(p)
        return p.phase ~= Player.NotActive and p:hasShownSkill(yimie.name)
      end) and table.find(Fk:currentRoom().alive_players, function(p)
        return p.dying and H.compareKingdomWith(p, player)
      end)
    end
  end,
})

local addLoseEffect = function(self, player, _)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    if p ~= player and p.kingdom ~= "unknown" then
      room:handleAddLoseSkills(p, yimie.attached_skill_name, nil, false, true)
    end
  end
end
yimie:addAcquireEffect(addLoseEffect)
yimie:addLoseEffect(addLoseEffect)

yimie:addEffect(fk.AfterPropertyChange, yimie_spec)
yimie:addEffect(fk.GeneralRevealed, yimie_spec)
yimie:addEffect(fk.GeneralHidden, yimie_spec)
yimie:addEffect(fk.Deathed, yimie_spec)

return yimie
