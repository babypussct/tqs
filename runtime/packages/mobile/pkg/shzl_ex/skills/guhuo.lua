local guhuo = fk.CreateSkill{
  name = "m_ex__guhuo",
  related_skills = { "chanyuan" },
}

Fk:loadTranslationTable{
  ["m_ex__guhuo"] = "蛊惑",
  [":m_ex__guhuo"] = "每回合限一次，你可以扣置一张手牌当任意一张基本牌或普通锦囊牌使用或打出。使用此牌前，令所有其他角色依次选择是否质疑，"..
  "若有角色质疑则翻开此牌：若为假，则此牌作废；若为真，则该色获得〖缠怨〗。",

  ["#m_ex__guhuo"] = "蛊惑：扣置一张手牌并声明一种基本牌或普通锦囊牌，若无人质疑，则按牌名使用或打出",
  ["#mex_guhuo_query"] = "%from 选择 %arg",

  ["$m_ex__guhuo1"] = "道法玄机，变幻莫测。",
  ["$m_ex__guhuo2"] = "如真似幻，扑朔迷离。",
}

guhuo:addEffect("viewas", {
  pattern = ".",
  prompt = "#m_ex__guhuo",
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("bt")
    local names = player:getViewAsCardNames(guhuo.name, all_names)
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|.|^equip",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addFakeSubcards(cards)
    card.skillName = guhuo.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    local cards = use.card.fake_subcards
    local card_id = cards[1]
    room:moveCardTo(cards, Card.Processing, nil, fk.ReasonPut, guhuo.name, nil, false, player)
    if #use.tos > 0 then
      room:sendLog{
        type = "#guhuo_use",
        from = player.id,
        to = table.map(use.tos, Util.IdMapper),
        arg = use.card.name,
        arg2 = guhuo.name
      }
      room:doIndicate(player, use.tos)
    else
      room:sendLog{
        type = "#guhuo_no_target",
        from = player.id,
        arg = use.card.name,
        arg2 = guhuo.name,
      }
    end

    local canuse = true
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p:hasSkill("chanyuan") and p:isAlive() then
        local choice = room:askToChoice(p, {
          choices = {"noquestion", "question"},
          skill_name = guhuo.name,
          prompt = "#guhuo-ask::"..player.id..":"..use.card.name,
        })
        room:sendLog{
          type = "#mex_guhuo_query",
          from = p.id,
          arg = choice,
          toast = true,
        }
        if choice ~= "noquestion" then
          player:showCards(card_id)
          if use.card.name == Fk:getCardById(card_id).name then
            room:setCardEmotion(card_id, "judgegood")
            room:handleAddLoseSkills(p, "chanyuan")
          else
          room:setCardEmotion(card_id, "judgebad")
            canuse = false
          end
          break
        end
      end
    end

    if canuse then
      use.card:addSubcard(card_id)
    else
      room:moveCardTo(card_id, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, guhuo.name)
      return ""
    end
  end,
  enabled_at_play = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(guhuo.name, Player.HistoryTurn) == 0
  end,
  enabled_at_response = function(self, player, response)
    return not player:isKongcheng() and player:usedSkillTimes(guhuo.name, Player.HistoryTurn) == 0
  end,
})

return guhuo
