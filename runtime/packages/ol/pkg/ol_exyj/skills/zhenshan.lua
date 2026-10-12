
local zhenshan = fk.CreateSkill {
  name = "ol_ex__zhenshan",
}

Fk:loadTranslationTable{
  ["ol_ex__zhenshan"] = "赈赡",
  [":ol_ex__zhenshan"] = "每回合限一次，当你需要使用或打出基本牌时，你可以与手牌数小于你的一名角色交换手牌，视为使用或打出之，"..
  "然后可以发动一次〖邀名〗。",

  ["#ol_ex__zhenshan"] = "赈赡：与一名手牌数少于你的角色交换手牌，视为使用或打出基本牌（先选择使用的牌名和目标）",
  ["#ol_ex__zhenshan-choose"] = "赈赡：与一名手牌数少于你的角色交换手牌",

  ["$ol_ex__zhenshan1"] = "看我如何以无用之力换己所需，哈哈哈！",
  ["$ol_ex__zhenshan2"] = "民不足食，何以养军？",
}

zhenshan:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = "#ol_ex__zhenshan",
  card_filter = Util.FalseFunc,
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {}
  },
  interaction_helper = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(zhenshan.name, all_names, {})
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  view_as = function(self, player, cards)
    if not self.interaction.data then return end
    return Fk:cloneCard(self.interaction.data, nil, nil, zhenshan.name)
  end,
  before_use = function(self, player)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p:getHandcardNum() < player:getHandcardNum()
    end)
    if #targets == 0 then return "" end
    local to = room:askToChoosePlayers(player, {
      skill_name = zhenshan.name,
      min_num = 1,
      max_num = 1,
      targets = targets,
      prompt = "#ol_ex__zhenshan-choose",
      cancelable = false,
    })[1]
    room:swapAllCards(player, { player, to }, zhenshan.name, "h")
  end,
  after_use = function(self, player, use)
    if not player.dead then
      local room = player.room
      local to = room:askToChoosePlayers(player, {
        targets = room.alive_players,
        min_num = 1,
        max_num = 1,
        prompt = "#ol_ex__yaoming-choose",
        skill_name = "ol_ex__yaoming",
      })
      if #to > 0 then
        player:broadcastSkillInvoke("ol_ex__yaoming")
        room:notifySkillInvoked(player, "ol_ex__yaoming", "control")
        to = to[1]
        local yes1 = to:getHandcardNum() >= player:getHandcardNum() and not to:isNude()
        local yes2 = to:getHandcardNum() <= player:getHandcardNum()
        if yes1 then
          local id = room:askToChooseCard(player, {
            target = to,
            flag = "he",
            skill_name = "ol_ex__yaoming",
          })
          room:throwCard(id, "ol_ex__yaoming", to, player)
        end
        if yes2 and not to.dead then
          to:drawCards(1, "ol_ex__yaoming")
        end
        if player:hasSkill("ol_ex__yaoming", true) then
          room:addTableMarkIfNeed(player, "@[list]ol_ex__yaoming", to)
        end
      end
    end
  end,
  enabled_at_play = function(self, player)
    return (player:usedSkillTimes(zhenshan.name, Player.HistoryTurn) == 0 or
      table.contains(player:getTableMark("@[list]ol_ex__yaoming"), Fk:currentRoom():getCurrent())) and
      table.find(Fk:currentRoom().alive_players, function(p)
        return p:getHandcardNum() < player:getHandcardNum()
      end)
  end,
  enabled_at_response = function(self, player)
    return (player:usedSkillTimes(zhenshan.name, Player.HistoryTurn) == 0 or
      table.contains(player:getTableMark("@[list]ol_ex__yaoming"), Fk:currentRoom():getCurrent())) and
      table.find(Fk:currentRoom().alive_players, function(p)
        return p:getHandcardNum() < player:getHandcardNum()
      end)
  end,
})

return zhenshan
