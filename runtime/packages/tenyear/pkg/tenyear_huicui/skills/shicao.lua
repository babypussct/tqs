local shicao = fk.CreateSkill {
  name = "shicao",
}

Fk:loadTranslationTable{
  ["shicao"] = "识草",
  [":shicao"] = "出牌阶段，你可以声明一种类别，从牌堆顶/牌堆底摸一张牌，若此牌不为你声明的类别，你观看牌堆底/牌堆顶的两张牌，"..
  "此技能本回合失效。",

  ["#shicao"] = "识草：选择从牌堆顶/牌堆底摸一张牌，并猜测摸牌的类别，若猜错则本回合失效",
  ["shicao_type"] = "%arg | %arg2",
  ["#shicao-viewtop"] = "正在观看牌堆顶的牌（左边是最牌堆顶）",
  ["#shicao-viewbottom"] = "正在观看牌堆底的牌（右边是最牌堆底）",

  ["$shicao1"] = "药长于草木，然草木非皆可入药。",
  ["$shicao2"] = "掌中非药，乃活人之根本。",
}

shicao:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#shicao",
  card_num = 0,
  target_num = 0,
  interaction = function(self, player)
    return UI.ComboBox {choices = {
      "shicao_type:::basic:Top", "shicao_type:::basic:Bottom",
      "shicao_type:::trick:Top", "shicao_type:::trick:Bottom",
      "shicao_type:::equip:Top", "shicao_type:::equip:Bottom",
    } }
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local shicao_type = self.interaction.data:split(":")
    local from_place = shicao_type[5]:lower()
    local ids = room:drawCards(player, 1, shicao.name, from_place)
    if #ids == 0 or player.dead then return end
    if Fk:getCardById(ids[1]):getTypeString() ~= shicao_type[4] then
      if from_place == "top" then
        ids = room:getNCards(2, "bottom")
      else
        ids = room:getNCards(2)
      end
      room:viewCards(player, {
        cards = ids,
        skill_name = shicao.name,
        prompt = from_place == "top" and "#shicao-viewbottom" or "#shicao-viewtop",
      })
      room:invalidateSkill(player, shicao.name, "-turn", shicao.name)
    end
  end,
})

return shicao
