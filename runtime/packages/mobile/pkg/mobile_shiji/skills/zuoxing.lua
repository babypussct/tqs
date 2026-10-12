local zuoxing = fk.CreateSkill {
  name = "zuoxing",
}

Fk:loadTranslationTable{
  ["zuoxing"] = "佐幸",
  [":zuoxing"] = "出牌阶段限一次，你可以令神郭嘉减1点体力上限，视为使用一张普通锦囊牌。",

  ["#zuoxing"] = "佐幸：你可以令 %dest 减1点体力上限，视为使用一张普通锦囊牌",

  ["$zuoxing1"] = "以聪虑难，悉咨于上。",
  ["$zuoxing2"] = "身计国谋，不可两遂。",
}

zuoxing:addEffect("viewas", {
  prompt = function (self, player, selected_cards, selected)
    local src = table.find(player:getTableMark("mobile__tianyi_src"), function(id)
      return not Fk:currentRoom():getPlayerById(id).dead
    end)
    return "#zuoxing::"..src
  end,
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("t")
    local names = player:getViewAsCardNames(zuoxing.name, all_names)
    if #names == 0 then return end
    return UI.CardNameBox {choices = names, all_choices = all_names}
  end,
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {}
  },
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = zuoxing.name
    return card
  end,
  before_use = function(self, player)
    local room = player.room
    local src = table.find(player:getTableMark("mobile__tianyi_src"), function(id)
      return not room:getPlayerById(id).dead
    end)
    if src then
      room:changeMaxHp(room:getPlayerById(src), -1)
    end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(zuoxing.name, Player.HistoryPhase) == 0 and
      table.find(player:getTableMark("mobile__tianyi_src"), function(id)
        return not Fk:currentRoom():getPlayerById(id).dead
      end)
  end,
})

return zuoxing
