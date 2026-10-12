local weijie = fk.CreateSkill{
  name = "weijie",
}

Fk:loadTranslationTable{
  ["weijie"] = "诿解",
  [":weijie"] = "每回合限一次，当你于其他角色的回合内需要使用/打出基本牌时，你可以弃置距离为1的一名角色的一张手牌，"..
  "若此牌与你需要使用/打出的牌牌名相同，你视为使用/打出此牌名的牌。",

  ["#weijie"] = "诿解：选择视为使用/打出的基本牌，弃置距离1角色一张牌，若与你需要的牌相同则视为使用/打出之",
  ["#weijie-choose"] = "诿解：弃置距离1一名角色的一张牌，若为【%arg】则视为你使用或打出之",

  ["$weijie1"] = "败战之罪在你，休要多言！",
  ["$weijie2"] = "纵汝舌灿莲花，亦难逃死罪。",
}

weijie:addEffect("viewas", {
  anim_type = "control",
  pattern = ".|.|.|.|.|basic",
  prompt = "#weijie",
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {}
  },
  card_filter = Util.FalseFunc,
  interaction_helper = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(weijie.name, all_names, {})
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  view_as = function(self, player, cards)
    if self.interaction.data == nil then return end
    return Fk:cloneCard(self.interaction.data, nil, nil, weijie.name)
  end,
  before_use = function(self, player)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return not p:isKongcheng() and player:distanceTo(p) == 1
    end)
    if #targets == 0 then return "" end
    local name = Fk:cloneCard(self.interaction.data).trueName
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = weijie.name,
      prompt = "#weijie-choose:::"..name,
      cancelable = false,
    })[1]
    local card = room:askToChooseCard(player, {
      target = to,
      flag = "h",
      skill_name = weijie.name,
    })
    local yes = Fk:getCardById(card).trueName == name
    room:throwCard(card, weijie.name, to, player)
    if not yes then return "" end
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player, response)
    return player:usedSkillTimes(weijie.name, Player.HistoryTurn) == 0 and
      Fk:currentRoom().current ~= player and
      table.find(Fk:currentRoom().alive_players, function (p)
        return not p:isKongcheng() and player:distanceTo(p) == 1
      end)
  end,
})

return weijie
