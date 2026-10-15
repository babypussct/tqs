import { VI_SKILL_TRANSLATIONS } from './vietnameseSkills';
import { VI_SKILL_REFINEMENTS } from './vietnameseSkillRefinements';
import { VI_SKILL_REVIEWED } from './vietnameseSkillReviewed';

/** Web display additions for the pinned Hegemony package, which has no vi_VN table.
 * Names and common UI prompts only: variant skill rules are never copied from another version. */
const names = `
bailingyun=Bách Linh Quân
bianfuren=Biện Phu Nhân
bulianshi=Bộ Luyện Sư
caiwenji=Thái Văn Cơ
caizhenji=Thái Trinh Cơ
caoang=Tào Ngang
caocao=Tào Tháo
caochun=Tào Thuần
caohong=Tào Hồng
caopi=Tào Phi
caoren=Tào Nhân
caorui=Tào Duệ
caozhi=Tào Thực
cenhun=Sầm Hôn
chendao=Trần Đáo
chengjiw=Thành Tế
chengpu=Trình Phổ
chengyu=Trình Dục
chenwudongxi=Trần Vũ · Đổng Tập
cuiyanmaojie=Thôi Diễm · Mao Giới
daqiao=Đại Kiều
dengai=Đặng Ngải
dengzhi=Đặng Chi
dianwei=Điển Vi
diaochan=Điêu Thuyền
dingfeng=Đinh Phụng
dingyuan=Đinh Nguyên
dongcheng=Đổng Thừa
dongyun=Đổng Doãn
dongzhao=Đổng Chiêu
dongzhuo=Đổng Trác
duanwei=Đoàn Ổi
duyu=Đỗ Dự
fazheng=Pháp Chính
feiyi=Phí Y
fengxi=Phùng Tập
fengxiw=Phùng Hi
fuqian=Phó Thiêm
furong=Phó Dung
fuwan=Phục Hoàn
ganfuren=Cam Phu Nhân
ganning=Cam Ninh
gaolan=Cao Lãm
gongsunfan=Công Tôn Phạm
gongsunyuan=Công Tôn Uyên
gongsunzan=Công Tôn Toản
guanping=Quan Bình
guanqiujian=Vô Khâu Kiệm
guansuo=Quan Sách
guanyinping=Quan Ngân Bình
guanyu=Quan Vũ
guohuai=Quách Hoài
guohuaij=Quách Hòe
guojia=Quách Gia
guyong=Cố Ung
hetaihou=Hà Thái Hậu
himiko=Himiko
huanggai=Hoàng Cái
huangquan=Hoàng Quyền
huangyueying=Hoàng Nguyệt Anh
huangzhong=Hoàng Trung
huangzu=Hoàng Tổ
huatuo=Hoa Đà
huaxin=Hoa Hâm
huaxiong=Hoa Hùng
huojun=Hoắc Tuấn
jiachong=Giả Sung
jiananfeng=Giả Nam Phong
jianggan=Tưởng Cán
jiangqin=Tưởng Khâm
jiangwanfeiyi=Tưởng Uyển · Phí Y
jiangwei=Khương Duy
jianshuo=Kiển Thạc
jiaxu=Giả Hủ
jiling=Kỷ Linh
kongrong=Khổng Dung
liangxing=Lương Hưng
liaohua=Liêu Hóa
lidian=Lý Điển
lifeng=Lý Phong
lijueguosi=Lý Giác · Quách Dĩ
lingcao=Lăng Thao
lingtong=Lăng Thống
liuba=Lưu Ba
liubei=Lưu Bị
liufuren=Lưu Phu Nhân
liuqi=Lưu Kỳ
liushan=Lưu Thiện
liuxie=Lưu Hiệp
liuyan=Lưu Yên
liuzan=Lưu Tán
liwei=Lý Vĩ
lizhaojiaobo=Lý Triệu · Tiêu Bá
lordcaocao=Tào Tháo (Quân chủ)
lordliubei=Lưu Bị (Quân chủ)
lordsimayi=Tư Mã Ý (Quân chủ)
lordsunquan=Tôn Quyền (Quân chủ)
lordyuanshao=Viên Thiệu (Quân chủ)
lordzhangjiao=Trương Giác (Quân chủ)
lukang=Lục Kháng
lusu=Lỗ Túc
luxun=Lục Tốn
luyusheng=Lục Úc Sinh
luzhiw=Lỗ Chi
lvbu=Lữ Bố
lvdai=Lữ Đại
lvfan=Lữ Phạm
lvlingqi=Lữ Linh Khởi
lvmeng=Lữ Mông
machao=Mã Siêu
madai=Mã Đại
malong=Mã Long
maojie=Mao Giới
masu=Mã Tắc
mateng=Mã Đằng
mayunlu=Mã Vân Lộc
mengda=Mạnh Đạt
menghuo=Mạnh Hoạch
mifangfushiren=Mi Phương · Phó Sĩ Nhân
mifuren=Mi Phu Nhân
miheng=Nễ Hành
mizhu=Mi Trúc
nanhualaoxian=Nam Hoa Lão Tiên
panfeng=Phan Phượng
pangde=Bàng Đức
pangtong=Bàng Thống
panjun=Phan Tuấn
pengyang=Bành Dạng
qinmi=Tần Mật
quancong=Toàn Tông
quyi=Khúc Nghĩa
shamoke=Sa Ma Kha
shibao=Thạch Bao
shie=Sĩ Nhiếp
shixie=Sĩ Nhiếp
simajiong=Tư Mã Quýnh
simaliang=Tư Mã Lượng
simalun=Tư Mã Luân
simashi=Tư Mã Sư
simawei=Tư Mã Vĩ
simayi=Tư Mã Ý
simayij=Tư Mã Nghệ
simaying=Tư Mã Dĩnh
simayong=Tư Mã Ngung
simayue=Tư Mã Việt
simazhao=Tư Mã Chiêu
simazhou=Tư Mã Trụ
sufei=Tô Phi
sunce=Tôn Sách
sunchen=Tôn Lâm
sundeng=Tôn Đăng
sunjian=Tôn Kiên
sunjun=Tôn Tuấn
sunluban=Tôn Lỗ Ban
sunquan=Tôn Quyền
sunshangxiang=Tôn Thượng Hương
sunxiuj=Tôn Tú
sunyi=Tôn Dực
taishici=Thái Sử Từ
tangzi=Đường Tư
tianfeng=Điền Phong
tianyu=Điền Dự
wangjun=Vương Tuấn
wangling=Vương Lăng
wangping=Vương Bình
wangrongh=Vương Vinh
wangxiang=Vương Tường
wangyuanji=Vương Nguyên Cơ
wangyue=Vương Duyệt
weiguan=Vệ Quán
weiyan=Ngụy Diên
wenqin=Văn Khâm
wenyang=Văn Ương
wolong=Ngọa Long Gia Cát Lượng
wuban=Ngô Ban
wuguotai=Ngô Quốc Thái
wujing=Ngô Cảnh
wuyi=Ngô Ý
xiahouba=Hạ Hầu Bá
xiahoudun=Hạ Hầu Đôn
xiahouhui=Hạ Hầu Huy
xiahoushang=Hạ Hầu Thượng
xiahouyuan=Hạ Hầu Uyên
xiahouzieh=Hạ Hầu Tử Ngạc
xiaoqiao=Tiểu Kiều
xingcai=Tinh Thái
xinxianying=Tân Hiến Anh
xuchu=Hứa Chử
xuhuang=Từ Hoảng
xunchen=Tuân Kham
xunyou=Tuân Du
xunyu=Tuân Úc
xurong=Từ Vinh
xusheng=Từ Thịnh
xushu=Từ Thứ
xuyou=Hứa Du
yanbaihu=Nghiêm Bạch Hổ
yangfeng=Dương Phụng
yanghu=Dương Hỗ
yanghuiyu=Dương Huy Du
yangjun=Dương Tuấn
yangwan=Dương Uyển
yangxiu=Dương Tu
yanjun=Nghiêm Tuấn
yanliangwenchou=Nhan Lương · Văn Xú
yanrou=Diêm Nhu
yuanshao=Viên Thiệu
yuanshu=Viên Thuật
yuejin=Nhạc Tiến
yuji=Vu Cát
yujin=Vu Cấm
zangba=Tang Bá
zhangchangpu=Trương Xương Bồ
zhangchunhua=Trương Xuân Hoa
zhangfei=Trương Phi
zhanghe=Trương Cáp
zhanghuyuechen=Trương Hổ · Nhạc Sâm
zhangjiao=Trương Giác
zhangliao=Trương Liêu
zhanglu=Trương Lỗ
zhangren=Trương Nhậm
zhangsong=Trương Tùng
zhangxiu=Trương Tú
zhangyiy=Trương Dực
zhangzhaozhanghong=Trương Chiêu · Trương Hoành
zhaotongzhaoguang=Triệu Thống · Triệu Quảng
zhaoyun=Triệu Vân
zhenji=Chân Cơ
zhonghui=Chung Hội
zhongyao=Chung Diêu
zhouchu=Chu Xử
zhoufang=Chu Phường
zhoutai=Chu Thái
zhouyi=Chu Di
zhouyu=Chu Du
zhugedan=Gia Cát Đản
zhugejin=Gia Cát Cẩn
zhugeke=Gia Cát Khác
zhugeliang=Gia Cát Lượng
zhugezhan=Gia Cát Chiêm
zhuhuan=Chu Hoàn
zhuling=Chu Linh
zhuran=Chu Nhiên
zhurong=Chúc Dung
zongyu=Tông Dự
zoushi=Trâu Thị
zumao=Tổ Mậu
zuoci=Tả Từ
`;
export const VI_NAMES: Record<string, string> = Object.fromEntries(names.trim().split('\n').map((line) => line.split('=')));
export const VI_ADDITIONS: Record<string, string> = {
  // Generated from the effective CP19 skill inventory; the precise hand-written
  // entries below intentionally override this broad translation baseline.
  ...VI_SKILL_TRANSLATIONS,
  ...VI_SKILL_REFINEMENTS,
  ...VI_SKILL_REVIEWED,
  '#TargetCancelled': 'Mục tiêu %to đã bị hủy khỏi lá %arg do %from sử dụng.',
  '#AskForSkillInvoke': 'Bạn có muốn kích hoạt %arg?',
  '#AskForUseActiveSkill': 'Hãy phát động kỹ năng %arg',
  '#AskForUseCard': 'Hãy sử dụng lá %arg',
  '#AskForResponseCard': 'Hãy đánh ra lá %arg',
  '#AskForPeaches': '%src đang hấp hối, cần hồi %arg máu. Dùng Đào để cứu hoặc bấm Hủy để bỏ qua.',
  '#AskForPeachesSelf': 'Bạn đang hấp hối, cần hồi %arg máu. Dùng Đào hoặc Rượu để tự cứu, hoặc bấm Hủy để bỏ qua.',
  '#peach_dying': 'Dùng Đào cứu %dest. Mục tiêu đã được khóa; bấm Xác nhận để dùng bài.',
  '#peach_skill': 'Dùng bài để hồi 1 máu cho bản thân. Bấm Xác nhận để tiếp tục.',
  '#web-peach-battle-new': 'Quyết chiến mới: Đào thường không thể dùng để hồi máu. Có thể chuyển thành Rượu qua kỹ năng Quyết chiến; Rượu chỉ tự cứu, không cứu người khác.',
  '#web-peach-battle-old': 'Quyết chiến cũ: Đào thường không thể dùng để hồi máu. Có thể chuyển thành Sát hoặc Thiểm qua kỹ năng Quyết chiến.',
  '#wild-choose': 'Dã tâm gia lập quốc: chọn quốc hiệu của bạn.',
  '#ChooseHegInitialKingdom': 'Luật Quốc Chiến: chọn thế lực ban đầu của bạn.',
  '#HegPrepareConvertLord': 'Luật Quốc Chiến: chọn tướng để lật. Chỉ lần này, nếu lật chủ tướng, bạn có thể chuyển thành Quân chủ.',
  ConvertToLord: 'Chuyển thành %arg!',
  '#WildChooseKingdom': 'Một Dã tâm gia đã chọn quốc hiệu %arg.',
  '#EnterBattleRoyalMode': 'Bước vào Quyết chiến cũ: mọi lá Đào chỉ có thể dùng hoặc đánh ra như Sát hay Thiểm, không thể dùng để hồi máu.',
  '#EnterNewBattleRoyalMode': 'Bước vào Quyết chiến mới: mọi lá Đào chỉ có thể dùng hoặc đánh ra như Rượu, không thể dùng để hồi máu.',
  '#EnterBattleRoyalModeLog': 'Trận đấu bước vào giai đoạn Quyết chiến.',
  // Nine Variations / new Hegemony battle royal: descriptions follow the pinned Lua rules.
  turban_shell_cup: 'Anh Vũ Bôi',
  ':turban_shell_cup': 'Trang bị · Bảo vật, Kỳ Trân. Mỗi lượt tối đa 9 lần, bạn có thể dùng lá trên cùng chồng bài như Tửu.',
  'turban_shell_cup_skill&': 'Anh Vũ Bôi',
  ':turban_shell_cup_skill&': 'Mỗi lượt tối đa 9 lần, bạn có thể dùng lá trên cùng chồng bài như Tửu.',
  '#turban_shell_cup_skill&': 'Anh Vũ Bôi: có thể dùng lá trên cùng chồng bài như Tửu.',
  overbearing: 'Đốt Đốt Bức Nhân', overbearing_skill: 'Đốt Đốt Bức Nhân',
  ':overbearing': 'Cẩm nang. Giai đoạn đánh bài: chọn một nhân vật đã xác định thế lực; họ có thể đổi phó tướng, sau đó bạn gây 1 sát thương cho họ.',
  '#overbearing_skill': 'Cho một nhân vật đổi phó tướng, sau đó bạn gây 1 sát thương cho họ.',
  reveal_intention: 'Đồ Cùng Chủy Hiện', reveal_intention_skill: 'Đồ Cùng Chủy Hiện',
  ':reveal_intention': 'Cẩm nang. Giai đoạn đánh bài: chọn một nhân vật khác. Bạn chọn một lá Kỳ Trân trong chồng bài bỏ để mục tiêu sử dụng; mục tiêu được xem như nằm trong tầm đánh của bạn đến hết lượt.',
  '#reveal_intention_skill': 'Chọn một nhân vật sử dụng một lá Kỳ Trân từ chồng bài bỏ; nhân vật đó nằm trong tầm đánh của bạn đến hết lượt.',
  '#reveal_intention-ask': 'Chọn một lá Kỳ Trân để %dest sử dụng.',
  tricky_heist: 'Xảo Thủ Hào Đoạt', tricky_heist_skill: 'Xảo Thủ Hào Đoạt',
  ':tricky_heist': 'Cẩm nang. Giai đoạn đánh bài: chọn tối đa hai nhân vật khác. Họ lần lượt công khai bài trên tay; bạn lấy tất cả lá trang bị được công khai theo cách này.',
  '#tricky_heist_skill': 'Tối đa hai nhân vật khác công khai bài trên tay; bạn lấy các lá trang bị được công khai.',
  unworthy_continuation: 'Cẩu Vĩ Tục Điêu', unworthy_continuation_skill: 'Cẩu Vĩ Tục Điêu',
  ':unworthy_continuation': 'Cẩm nang. Giai đoạn đánh bài: chọn tất cả nhân vật. Mỗi mục tiêu lần lượt chọn và dùng một lá Kỳ Trân trong chồng bài bỏ; nếu không có thì rút một lá.',
  '#unworthy_continuation_skill': 'Mọi nhân vật dùng một lá Kỳ Trân từ chồng bài bỏ; nếu không có thì rút một lá.',
  '#unworthy_continuation-ask': 'Hãy sử dụng một lá Kỳ Trân trong các lá này.',
  amiantus_robe: 'Hỏa Hoán Y', '#amiantus_robe_skill': 'Hỏa Hoán Y',
  ':amiantus_robe': 'Trang bị · Giáp, Kỳ Trân. Ngăn sát thương có thuộc tính mà bạn phải chịu. Khi trở thành mục tiêu của Sát, bạn có thể bỏ một lá trên tay để gây 1 sát thương Hỏa cho người sử dụng.',
  '#amiantus_robe-invoke': 'Hỏa Hoán Y: bạn có thể bỏ một lá trên tay để gây 1 sát thương Hỏa cho %dest.',
  rob__jink: 'Lược Thiểm', '#rob__jink_skill': 'Lược Thiểm',
  ':rob__jink': 'Bài cơ bản. Khi Sát có hiệu lực với bạn: vô hiệu hóa Sát đó, sau đó bạn có thể lấy một lá Kỳ Trân trong khu trang bị của người đã dùng Sát.',
  yangsui_spear: 'Dương Toại Thương', '#yangsui_spear_skill': 'Dương Toại Thương',
  ':yangsui_spear': 'Trang bị · Vũ khí, tầm đánh 3, Kỳ Trân. Khóa định: sau khi Sát của bạn gây sát thương cho mục tiêu, mục tiêu chịu thêm 1 sát thương Hỏa không có nguồn gây sát thương.',
  white_kylin: 'Bạch Kỳ Lân', '#white_kylin_skill': 'Bạch Kỳ Lân',
  ':white_kylin': 'Trang bị · Tọa kỵ, Kỳ Trân. Khoảng cách từ người khác đến bạn +2. Khi dùng lá này, lần lượt gây 1 sát thương Lôi cho mỗi nhân vật có máu nhiều hơn bạn.',
  tianlu: 'Thiên Lộc', '#tianlu_skill': 'Thiên Lộc',
  ':tianlu': 'Trang bị · Tọa kỵ, Kỳ Trân. Khoảng cách từ bạn đến người khác −3. Nếu trên bàn không có Quân chủ cùng thế lực với bạn, bạn được xem là có kỹ năng Quân chủ của thế lực mình.',
  dunjia_book: 'Độn Giáp Thiên Thư', 'dunjia_book_skill&': 'Độn Giáp Thiên Thư',
  ':dunjia_book': 'Trang bị · Bảo vật, Kỳ Trân. Trong giai đoạn đánh bài, tối đa hai lần, bạn có thể đổi phó tướng.',
  ':dunjia_book_skill&': 'Trong giai đoạn đánh bài, tối đa hai lần, bạn có thể đổi phó tướng.',
  '#dunjia_book_skill&': 'Độn Giáp Thiên Thư: bạn có thể đổi phó tướng.',
  rare_treasure: 'Kỳ Trân',
  ':rare_treasure': 'Kỳ Trân: sau khi một nhân vật có trang bị Kỳ Trân chịu sát thương từ Sát, người gây sát thương có thể lấy một lá Kỳ Trân trong khu trang bị của nhân vật đó. Các lá Kỳ Trân gồm Trảm Xà Kiếm, Dương Toại Thương, Hỏa Hoán Y, Bạch Kỳ Lân, Thiên Lộc, Độn Giáp Thiên Thư, Anh Vũ Bôi và Cửu Châu Đỉnh.',
  '#rare_treasure-prey': 'Bạn có muốn lấy một lá Kỳ Trân trong khu trang bị của %dest không?',
  nine_tripod_cauldrons: 'Cửu Châu Đỉnh', '#nine_tripod_cauldrons_skill': 'Cửu Châu Đỉnh',
  ':nine_tripod_cauldrons': 'Trang bị · Bảo vật, Kỳ Trân. Trước khi phát bài trên tay hoặc sau khi xáo bài, đặt lá này từ chồng bài rút vào chồng bài bỏ. Khóa định: nếu khu trang bị của bạn có ít nhất 4 lá Kỳ Trân, phe hiện tại của bạn thắng trận.',
  analeptic: 'Tửu', triblade: 'Tam Tiêm Lưỡng Nhận Đao',
  '#new_battle_royal_event&': 'Quyết chiến',
  '@[:]new_battle_royal_event': 'Sự kiện vòng này',
  '@[:]battle_royal_used_event': 'Những sự kiện đã xuất hiện',
  'new_battle_royal_event-log': 'Sự kiện vòng này: %arg. %arg2',
  battle_royal_bujinzetui: 'Bất Tiến Tắc Thoái',
  ':battle_royal_bujinzetui': 'Trong vòng này, cuối lượt của mỗi nhân vật, nếu nhân vật đó chưa gây sát thương trong lượt thì mất 1 máu.',
  battle_royal_fuli: 'Phú Lễ',
  ':battle_royal_fuli': 'Trong vòng này, trước giai đoạn rút bài, mỗi nhân vật có thể bỏ qua giai đoạn đó để lấy tối đa 2 lá Kỳ Trân từ chồng bài bỏ.',
  '#battle_royal_fuli': 'Phú Lễ: bạn có thể bỏ qua giai đoạn rút bài để lấy tối đa 2 lá Kỳ Trân từ chồng bài bỏ.',
  battle_royal_luoshi: 'Lạc Thạch',
  ':battle_royal_luoshi': 'Khi lật lá sự kiện này, tất cả nhân vật đã xác định thế lực lần lượt đổi phó tướng.',
  battle_royal_shengzheweiwang: 'Thắng Giả Vi Vương',
  ':battle_royal_shengzheweiwang': 'Trong vòng này, khi một nhân vật chết, người giết họ được rút thêm 3 lá ở mỗi giai đoạn rút bài từ đó đến hết trận.',
  '@battle_royal_shengzheweiwang': 'Thắng Giả Vi Vương',
  battle_royal_huoqi: 'Họa Khởi',
  ':battle_royal_huoqi': 'Trong vòng này, sát thương mọi nhân vật phải chịu tăng thêm 1.',
  battle_royal_jili: 'Kích Lệ',
  ':battle_royal_jili': 'Trong vòng này, Sát không bị giới hạn số lần dùng hoặc khoảng cách.',
  '$RoundStart': 'Bắt đầu vòng %arg', '$RoundEnd': 'Kết thúc vòng %arg',
  '$TurnStart': 'Bắt đầu lượt của %from', '$TurnEnd': 'Kết thúc lượt của %from',
  '$ExtraTurnStart': 'Bắt đầu lượt bổ sung %arg của %from',
  '$ExtraTurnEnd': 'Kết thúc lượt bổ sung %arg của %from',
  '#ImperialOrderRemoved': '%card bị loại khỏi trận.',
  ':BattleRoyalMode': 'Trong Quyết chiến cũ, Đào chỉ được dùng hoặc đánh ra như Sát hay Thiểm, không thể hồi máu.',
  ':NewBattleRoyalMode': 'Trong Quyết chiến mới, Đào chỉ được dùng hoặc đánh ra như Rượu, không thể hồi máu.',
  'heg: besieged on all sides': 'Tứ diện Sở ca: tất cả chủ tướng đã lật, bị người cùng thế lực bao vây.',
  '@@alliance': 'Kết minh', '@@alliance-public': 'Kết minh', '@@alliance-inhand': 'Kết minh',
  '@@alliance-inhand-turn': 'Kết minh', stack: 'Chồng bài',
  game_rule: 'Luật trận đấu', heg_rule: 'Luật Quốc Chiến',
  heg_qin: 'Tần', heg_qi: 'Tề', heg_chu: 'Sở', heg_yan: 'Yên', heg_zhao: 'Triệu', heg_hanr: 'Hàn',
  heg_jin: 'Tấn', heg_han: 'Hán', heg_xia: 'Hạ', heg_shang: 'Thương', heg_zhou: 'Chu', heg_liang: 'Lương',
  '$ViewCards': 'Xem các lá bài, sau đó xác nhận để tiếp tục.',
  '#known_both-choice': 'Tri Kỷ Tri Bỉ: chọn thông tin muốn xem của %dest.',
  '#known_both-hand': 'Tri Kỷ Tri Bỉ: xem bài trên tay của %dest.',
  'known_both_main': 'Xem chủ tướng', 'known_both_deputy': 'Xem phó tướng', 'known_both_hand': 'Xem bài trên tay',
  '#AskForChooseCard': '%arg: hãy chọn một lá bài của %src',
  '#AskForChooseCards': '%arg: hãy chọn từ %arg2 đến %arg3 lá bài của %src',
  ...VI_NAMES,
  // Pinned hegemony/pkg/standard: Zou Shi (hs__zoushi).
  // Keep these rules separate from any other variant sharing a skill label.
  hs__zoushi: 'Trâu Thị',
  '#hs__zoushi': 'Mị hoặc lòng người',
  '~hs__zoushi': 'Ta đã già, nhan sắc phai tàn rồi sao?',
  huoshui: 'Họa Thủy',
  ':huoshui': 'Khóa định: Trong lượt của bạn, các nhân vật khác không thể lật tướng; nhân vật khác thế lực với bạn mà còn tướng úp không thể dùng hoặc đánh ra Thiểm để đáp lại lá bài do bạn sử dụng.',
  '$huoshui1': 'Không đi nổi nữa sao?',
  '$huoshui2': 'Đừng đi, ở lại chơi thêm một lát nhé~',
  qingcheng: 'Khuynh Thành',
  ':qingcheng': 'Giai đoạn đánh bài: bạn có thể bỏ 1 lá màu Đen và chọn một nhân vật khác đã lật cả hai tướng để úp một tướng của họ. Nếu lá bỏ là bài trang bị màu Đen, bạn có thể chọn thêm một nhân vật khác đã lật cả hai tướng để úp một tướng của họ.',
  '#qingcheng-again': 'Khuynh Thành: bạn có thể chọn thêm một nhân vật khác để úp một tướng của họ.',
  '$qingcheng1': 'Ta thật có duyên với các ngươi.',
  '$qingcheng2': 'Hừ, mắt nhìn không chớp luôn rồi kìa.',
  // Pinned hegemony/pkg/lord_ex: Shi Xie (ld__shixie).
  ld__shixie: 'Sĩ Nhiếp',
  '#ld__shixie': 'Danh sĩ đất Bách Việt',
  '~ld__shixie': 'Một đời này của ta, đã đủ rồi…',
  ld__lixia: 'Lễ Hạ',
  ':ld__lixia': 'Khóa định: Đầu giai đoạn chuẩn bị của nhân vật khác thế lực với bạn, nếu bạn nằm ngoài phạm vi tấn công của người đó, họ phải chọn một: cho bạn rút 1 lá; hoặc bỏ 1 lá trong khu trang bị của bạn rồi họ mất 1 máu.',
  ld__lixia_drawcards: 'Cho %src rút 1 lá bài',
  ld__lixia_loseHp: 'Bỏ 1 lá trong khu trang bị của %src và mất 1 máu',
  '$ld__lixia1': 'Tướng quân quả là rường cột của đất nước.',
  '$ld__lixia2': 'Anh hùng có thể an cư lập nghiệp tại đất Giao Châu.',
  ld__biluan: 'Tị Loạn',
  ':ld__biluan': 'Khóa định: khoảng cách từ các nhân vật khác đến bạn +X, với X là số lá bài trong khu trang bị của bạn.',
  qiangxi: 'Cường Tập', 'm_heg__qiangxi': 'Cường Tập',
  '#m_heg__qiangxi': 'Cường Tập: bỏ một lá vũ khí hoặc không chọn bài để tự nhận 1 sát thương; gây 1 sát thương cho mục tiêu trong phạm vi công kích.',
  heg__nullification: 'Vô Giải (Quốc Chiến)', heg__nullification_skill: 'Vô Giải (Quốc Chiến)',
  serpent_slayer_sword: 'Trảm Xà Kiếm', '#serpent_slayer_sword_skill': 'Trảm Xà Kiếm',
  ':serpent_slayer_sword': 'Trang bị · Vũ khí, tầm đánh 2, Kỳ Trân. Sau khi Sát của bạn gây sát thương cho mục tiêu, bạn hồi 1 máu; nếu mục tiêu là Quân chủ hoặc Dã tâm gia, tiêu diệt mục tiêu đó.',
  known_both: 'Tri Kỷ Tri Bỉ', await_exhausted: 'Dĩ Dật Đãi Lao',
  burning_camps: 'Hỏa Thiêu Liên Doanh', fight_together: 'Lục Lực Đồng Tâm',
  ':burning_camps': 'Cẩm nang. Giai đoạn đánh bài: gây 1 sát thương Hỏa cho người chơi kế tiếp và tất cả người chơi khác cùng đội hình với họ.',
  '#burning_camps_skill': 'Gây 1 sát thương Hỏa cho người chơi kế tiếp và mỗi người cùng đội hình với họ.',
  liulongcanjia: 'Lục Long Tham Giá',
  ':liulongcanjia': 'Trang bị · Tọa kỵ. Khóa định: khoảng cách người khác đến bạn +1; khoảng cách từ bạn đến người khác −1. Khi trang bị lá này, bỏ mọi tọa kỵ khác trong khu trang bị của bạn; bạn không thể dùng bài tọa kỵ.',
  '@@liulongcanjia': 'Lục Long Tham Giá',
  mobile__liulongcanjia: 'Lục Long Tham Giá',
  ':mobile__liulongcanjia': 'Trang bị · Tọa kỵ. Khóa định: khoảng cách từ bạn đến tất cả người chơi khác −3.',
  '#mobile__liulongcanjia_skill': 'Lục Long Tham Giá',
  part_ways: 'Phân Đạo Dương Tiêu', part_ways_skill: 'Phân Đạo Dương Tiêu',
  ':part_ways': 'Cẩm nang. Giai đoạn đánh bài: chọn một người chơi khác cùng thế lực. Bạn rút 6 lá, giao cho họ 3 lá, sau đó trở thành Dã tâm gia.',
  '#part_ways_skill': 'Chọn người chơi khác cùng thế lực: bạn rút 6 lá, giao họ 3 lá, sau đó trở thành Dã tâm gia.',
  '#part_ways-give': 'Hãy giao cho %dest 3 lá bài.',
  hs__shuangxiong: 'Song Hùng', '@hs__shuangxiong-turn': 'Song Hùng',
  ':hs__shuangxiong': 'Đầu giai đoạn đánh bài, bạn có thể cho một người chơi bỏ 1 lá. Trong lượt này, bạn có thể dùng 1 lá trên tay khác màu với lá vừa bỏ như Quyết Đấu.',
  '#hs__shuangxiong': 'Song Hùng: bạn có thể dùng 1 lá trên tay màu %arg như Quyết Đấu.',
  '#hs__shuangxiong-choose': 'Song Hùng: chọn một người chơi bỏ 1 lá. Trong giai đoạn này, bạn có thể dùng lá trên tay khác màu với lá đó như Quyết Đấu.',
  '#hs__shuangxiong-discard': 'Song Hùng: hãy bỏ 1 lá. Trong giai đoạn này, %src có thể dùng lá trên tay khác màu với lá đó như Quyết Đấu.',
  red: 'Đỏ', black: 'Đen',
  // Offline Hegemony Mi Zhu: rules from pkg/offline_heg/skills/{jugu,ziyuan}.lua.
  ofl_heg__jugu: 'Cự Cổ',
  ':ofl_heg__jugu': 'Khóa định: khi lật tướng này, bạn rút X lá bài và giới hạn bài trên tay tăng X, với X bằng máu tối đa của bạn.',
  ofl_heg__ziyuan: 'Tư Viện',
  ':ofl_heg__ziyuan': 'Giai đoạn đánh bài, một lần: bạn có thể giao các lá trên tay có tổng điểm bằng 13 cho một người chơi khác cùng thế lực; họ hồi 1 máu.',
  '#ofl_heg__ziyuan': 'Tư Viện: giao các lá trên tay có tổng điểm bằng 13 cho một người chơi khác cùng thế lực để họ hồi 1 máu.',
  alliance_feast: 'Liên Minh Thịnh Yến', threat: 'Hiệp Thiên Tử Dĩ Lệnh Chư Hầu',
  imperial_order: 'Sắc Lệnh', drowning: 'Thủy Yêm Thất Quân',
  breastplate: 'Hộ Tâm Kính', iron_armor: 'Minh Quang Khải', wooden_ox: 'Mộc Ngưu Lưu Mã',
  six_swords: 'Ngô Lục Kiếm', dragon_phoenix: 'Phi Long Đoạt Phượng',
  jade_seal: 'Ngọc Tỷ', lure_tiger: 'Điệu Hổ Ly Sơn', befriend_attacking: 'Viễn Giao Cận Công',
  formation: 'Trận pháp', heg: 'Quốc Chiến', new_heg_mode: 'Quốc Chiến',
  alliance: 'Kết minh', new_battle_royal: 'Quyết chiến', yinyangfish_skill: 'Âm Dương Ngư',
  'yinyangfish_skill&': 'Âm Dương Ngư', 'alliance&': 'Kết minh', 'new_battle_royal&': 'Quyết chiến',
  'battle_royal&': 'Quyết chiến', 'vanguard_skill&': 'Tiên phong',
  vanguard: 'Tiên phong',
  '#vanguard_skill&': 'Bạn có thể bỏ 1 dấu Tiên phong, rút bài trên tay đến đủ 4 lá, sau đó xem 1 tướng chưa lật của người chơi khác.',
  ':vanguard_skill&': 'Giai đoạn đánh bài: bạn có thể bỏ 1 dấu Tiên phong, rút bài trên tay đến đủ 4 lá, sau đó xem 1 tướng chưa lật của người chơi khác.',
  ':@!!vanguard': 'Giai đoạn đánh bài: bạn có thể bỏ 1 dấu Tiên phong, rút bài trên tay đến đủ 4 lá, sau đó xem 1 tướng chưa lật của người chơi khác.',
  'companion_skill&': 'Châu Liên Bích Hợp',
  '#companion_skill&': 'Bỏ một dấu Châu Liên Bích Hợp để dùng Đào hoặc rút hai lá bài.',
  '@!!vanguard': 'Tiên phong', '@!!yinyangfish': 'Âm Dương Ngư',
  '@!!companion': 'Châu Liên Bích Hợp', '@!!wild': 'Dã tâm gia',
  '@[:]BattleRoyalDummy': 'Chế độ quyết chiến', NewBattleRoyalMode: 'Quyết chiến mới', BattleRoyalMode: 'Quyết chiến cũ',
  revealMain: 'Lật chủ tướng: %arg', revealDeputy: 'Lật phó tướng: %arg', revealAll: 'Lật cả hai tướng',
  '#HegRevealGenerals': 'Bạn có muốn lật tướng?', Cancel: 'Hủy',
  wei: 'Ngụy', shu: 'Thục', wu: 'Ngô', qun: 'Quần', jin: 'Tấn', wild: 'Dã tâm',
  // Room pool packages
  hegemony_standard: 'Quốc Chiến Tiêu Chuẩn',
  hegemony_nos: 'Quốc Chiến Cổ Điển',
  momentum: 'Biến Cục',
  transformation: 'Biến Hóa',
  power: 'Quyền Lực',
  lord_ex: 'Quân Chủ Mở Rộng',
  zqdl: 'Tử Khí Đông Lai (Tấn)',
  jyzs: 'Kim Ấn Tử Thụ (Tấn)',
  zfxp: 'Tử Phượng Hàm Bội (Tấn)',
  online_heg: 'Bản Quyền OL',
  mobile_heg: 'Bản Quyền Mobile',
  tenyear_heg: 'Quốc Chiến Thập Niên',
  overseas_heg: 'Quốc Chiến Quốc Tế',
  offline_heg: 'Quốc Chiến Ngoại Tuyến',
  hegemony_cards: 'Bài Tiêu Chuẩn',
  strategic_advantage: 'Ưu Thế Chiến Lược',
  nine_variations: 'Quốc Chiến Cửu Biến',
  lord_cards: 'Quân Lâm Thiên Hạ',
  m_lord_cards: 'Quân Lâm Thiên Hạ Mobile',

  // Standard Basic & Trick Cards
  slash: 'Sát', fire_slash: 'Hỏa Sát', fire__slash: 'Hỏa Sát', thunder_slash: 'Lôi Sát', thunder__slash: 'Lôi Sát',
  jink: 'Thiểm', peach: 'Đào',
  duel: 'Quyết Đấu', dismantlement: 'Quá Hà Đoạt Kiều', snatch: 'Thuận Thủ Khiên Dương',
  ex_nihilo: 'Vô Trung Sinh Hữu', nullification: 'Vô Giải Khả Kích', god_salvation: 'Đào Viên Kết Nghĩa',
  amazing_grace: 'Ngũ Cốc Phong Đăng', savage_assault: 'Nam Man Xâm Nhập', archery_attack: 'Vạn Tiễn Tề Phát',
  iron_chain: 'Thiết Tỏa Liên Hoàn', collateral: 'Tá Đao Sát Nhân', fire_attack: 'Hỏa Công',
  lightning: 'Sấm Sét', indulgence: 'Lạc Bất Tư Thục', supply_shortage: 'Binh Lương Thốn Đoạn',

  // Weapons
  crossbow: 'Chư Cát Liên Nỗ', zhuge_crossbow: 'Chư Cát Liên Nỗ', qinggang_sword: 'Thanh Cương Kiếm',
  double_swords: 'Thư Hùng Song Cổ Kiếm', blade: 'Thanh Long Yển Nguyệt Đao', spear: 'Trượng Bát Xà Mâu',
  axe: 'Quán Thạch Phủ', halberd: 'Phương Thiên Họa Kích', kylin_bow: 'Kỳ Lân Cung',
  ice_sword: 'Hàn Băng Kiếm', guding_blade: 'Cổ Đĩnh Đao', fan: 'Chu Tước Phiến',

  // Armors
  eight_diagram: 'Bát Quái Trận', nioh_shield: 'Nhân Vương Thuẫn', silver_lion: 'Bạch Ngân Sư Tử', vine: 'Đằng Giáp',

  // Defensive Rides (+1)
  jueying: 'Tuyệt Ảnh', dilu: 'Đích Lô', zhuahuangfeidian: 'Trảo Hoàng Phi Điện',

  // Offensive Rides (-1)
  chitu: 'Xích Thố', dayuan: 'Đại Uyển', zixing: 'Tử Tinh',

  // Treasures
  role__wooden_ox: 'Mộc Ngưu Lưu Mã',

  // Card Descriptions
  ':slash': 'Bài cơ bản. Trong giai đoạn ra bài, sử dụng lên một mục tiêu trong phạm vi tấn công. Gây 1 sát thương nếu đối phương không đánh ra 【Thiểm】.',
  ':fire_slash': 'Bài cơ bản. Gây 1 sát thương hỏa. Kích hoạt liên hoàn nếu mục tiêu bị xích.',
  ':thunder_slash': 'Bài cơ bản. Gây 1 sát thương lôi. Bỏ qua Đằng Giáp và kích hoạt liên hoàn.',
  ':jink': 'Bài cơ bản. Đánh ra trong giai đoạn phản hồi để hóa giải một lá 【Sát】.',
  ':peach': 'Bài cơ bản. Hồi 1 điểm sinh lực trong giai đoạn ra bài, hoặc cứu người đang hấp hối.',
  ':analeptic': 'Bài cơ bản. Giúp đòn 【Sát】 kế tiếp +1 sát thương, hoặc tự hồi 1 máu khi hấp hối.',
  ':duel': 'Cẩm nang. Chỉ định 1 người chơi quyết đấu: Lần lượt đánh ra 【Sát】. Ai không ra được chịu 1 sát thương.',
  ':dismantlement': 'Cẩm nang. Bỏ 1 lá bài bất kỳ trên tay, khu trang bị hoặc khu phán xét của người khác.',
  ':snatch': 'Cẩm nang. Lấy 1 lá bài trên tay, khu trang bị hoặc phán xét của người trong cự ly 1.',
  ':ex_nihilo': 'Cẩm nang. Ngay lập tức rút 2 lá bài từ chồng bài rút.',
  ':nullification': 'Cẩm nang. Vô hiệu hóa tác dụng của một lá Cẩm Nang đang thi triển.',
  ':god_salvation': 'Cẩm nang. Tất cả nhân vật bị thương hồi 1 máu theo thứ tự lượt.',
  ':amazing_grace': 'Cẩm nang. Lật số lá bài bằng số người sống, mỗi người lần lượt chọn 1 lá.',
  ':savage_assault': 'Cẩm nang. Tất cả người khác phải đánh ra 【Sát】, nếu không sẽ chịu 1 sát thương.',
  ':archery_attack': 'Cẩm nang. Tất cả người khác phải đánh ra 【Thiểm】, nếu không sẽ chịu 1 sát thương.',
  ':iron_chain': 'Cẩm nang. Chọn tối đa 2 người để xích/tháo xích, hoặc trùng chú (bỏ để rút 1 lá).',
  ':collateral': 'Cẩm nang. Buộc 1 người có vũ khí dùng 【Sát】 lên mục tiêu bạn chọn, nếu không bạn lấy vũ khí của họ.',
  ':fire_attack': 'Cẩm nang. Mục tiêu công khai 1 lá bài; nếu bạn bỏ lá cùng chất thì mục tiêu chịu 1 sát thương Hỏa.',
  ':lightning': 'Cẩm nang trì hoãn. Đầu lượt phán xét: nếu lật trúng Bích 2..9 thì chịu 3 sát thương sấm sét.',
  ':indulgence': 'Cẩm nang trì hoãn. Đầu lượt phán xét: nếu không phải Cơ thì bị bỏ qua giai đoạn Ra Bài.',
  ':supply_shortage': 'Cẩm nang trì hoãn. Đầu lượt phán xét: nếu không phải Chuồn thì bị bỏ qua giai đoạn Rút Bài.',
  ':befriend_attacking': 'Cẩm nang. Chọn người chơi khác thế lực: Bạn rút 1 lá bài, họ rút 3 lá bài.',
  ':lure_tiger': 'Cẩm nang. Chọn tối đa 2 người chơi: Họ không thể dùng bài hoặc bị chọn làm mục tiêu đến hết lượt.',

  ':crossbow': 'Trang bị · Vũ khí, tầm 1. Khóa định: Trong giai đoạn ra bài, không giới hạn số lần dùng 【Sát】.',
  ':zhuge_crossbow': 'Trang bị · Vũ khí, tầm 1. Khóa định: Trong giai đoạn ra bài, không giới hạn số lần dùng 【Sát】.',
  ':qinggang_sword': 'Trang bị · Vũ khí, tầm 2. Khóa định: Khi dùng 【Sát】, bỏ qua mọi phòng cụ của mục tiêu.',
  ':double_swords': 'Trang bị · Vũ khí, tầm 2. Khi dùng 【Sát】 lên mục tiêu khác giới, họ chọn bỏ 1 lá trên tay hoặc bạn rút 1 lá.',
  ':blade': 'Trang bị · Vũ khí, tầm 3. Khi 【Sát】 bị 【Thiểm】 hóa giải, bạn có thể ngay lập tức dùng thêm 1 lá 【Sát】 lên cùng mục tiêu.',
  ':spear': 'Trang bị · Vũ khí, tầm 3. Bạn có thể coi 2 lá bài bất kỳ trên tay như một lá 【Sát】.',
  ':axe': 'Trang bị · Vũ khí, tầm 3. Khi 【Sát】 bị hóa giải, có thể bỏ 2 lá để ép đòn 【Sát】 trúng đích.',
  ':halberd': 'Trang bị · Vũ khí, tầm 4. Nếu 【Sát】 là lá duy nhất trên tay, có thể chỉ định tối đa 3 mục tiêu.',
  ':kylin_bow': 'Trang bị · Vũ khí, tầm 5. Khi 【Sát】 gây sát thương, bạn có thể bắn hạ 1 Tọa Kỵ của mục tiêu.',
  ':ice_sword': 'Trang bị · Vũ khí, tầm 2. Khi 【Sát】 trúng mục tiêu, có thể bỏ 2 lá của họ thay vì gây sát thương.',
  ':guding_blade': 'Trang bị · Vũ khí, tầm 2. Khi 【Sát】 gây sát thương lên mục tiêu không có bài trên tay, sát thương +1.',
  ':fan': 'Trang bị · Vũ khí, tầm 4. Bạn có thể coi một lá 【Sát】 thường như 【Hỏa Sát】.',
  ':triblade': 'Trang bị · Vũ khí, tầm 3. Sau khi gây sát thương bằng 【Sát】, có thể bỏ 1 lá trên tay để gây 1 sát thương cho nhân vật khác trong cự ly 1 của mục tiêu.',
  ':six_swords': 'Trang bị · Vũ khí, tầm 2. Khóa định: Khoảng cách từ người khác đến các tướng Ngô +1.',
  ':dragon_phoenix': 'Trang bị · Vũ khí, tầm 2. Khi dùng 【Sát】 gây sát thương, có thể lấy 1 lá trang bị của mục tiêu.',

  ':eight_diagram': 'Trang bị · Phòng cụ. Mỗi khi cần ra 【Thiểm】, bạn có thể phán xét: nếu là bài Đỏ, tính như đã ra 【Thiểm】.',
  ':nioh_shield': 'Trang bị · Phòng cụ. Khóa định: Mọi lá 【Sát】 màu đen sử dụng lên bạn đều vô hiệu.',
  ':silver_lion': 'Trang bị · Phòng cụ. Khóa định: Chỉ chịu tối đa 1 sát thương mỗi lần nhận đòn. Khi mất giáp, hồi 1 máu.',
  ':vine': 'Trang bị · Phòng cụ. Khóa định: Vô hiệu hóa Sát thường, Nam Man, Vạn Tiễn; nhưng chịu thêm 1 sát thương Hỏa.',
  ':breastplate': 'Trang bị · Phòng cụ. Khi chịu sát thương hấp hối, bạn có thể bỏ lá này để hồi về 1 máu.',
  ':iron_armor': 'Trang bị · Phòng cụ. Khóa định: Khi có bài trong vùng phán xét, bạn miễn nhiễm sát thương từ Sát và Cẩm Nang.',

  ':jueying': 'Trang bị · Tọa kỵ (+1 Mã). Khóa định: Khoảng cách từ tất cả người khác đến bạn +1.',
  ':dilu': 'Trang bị · Tọa kỵ (+1 Mã). Khóa định: Khoảng cách từ tất cả người khác đến bạn +1.',
  ':zhuahuangfeidian': 'Trang bị · Tọa kỵ (+1 Mã). Khóa định: Khoảng cách từ tất cả người khác đến bạn +1.',
  ':chitu': 'Trang bị · Tọa kỵ (-1 Mã). Khóa định: Khoảng cách từ bạn đến tất cả người khác -1.',
  ':dayuan': 'Trang bị · Tọa kỵ (-1 Mã). Khóa định: Khoảng cách từ bạn đến tất cả người khác -1.',
  ':zixing': 'Trang bị · Tọa kỵ (-1 Mã). Khóa định: Khoảng cách từ bạn đến tất cả người khác -1.',

  ':wooden_ox': 'Trang bị · Bảo vật. Giai đoạn ra bài: cất tối đa 5 lá vào Mộc Ngưu và chuyển sang cho người khác.',
  ':role__wooden_ox': 'Trang bị · Bảo vật. Giai đoạn ra bài: cất tối đa 5 lá vào Mộc Ngưu và chuyển sang cho người khác.',
  ':jade_seal': 'Trang bị · Bảo vật. Khóa định: Bạn coi như có kỹ năng Quân chủ của phe mình. Đầu lượt rút bài, rút thêm 1 lá.',

  // Equipment Skill Names & Prompts
  eight_diagram_skill: 'Bát Quái Trận', '#eight_diagram_skill': 'Bát Quái Trận: bạn có thể phán xét để hóa giải đòn đánh.',
  qinggang_sword_skill: 'Thanh Cương Kiếm', '#qinggang_sword_skill': 'Thanh Cương Kiếm: bỏ qua phòng cụ mục tiêu.',
  double_swords_skill: 'Thư Hùng Song Cổ Kiếm', '#double_swords_skill': 'Thư Hùng Song Cổ Kiếm: mục tiêu khác giới chọn bỏ 1 bài hoặc bạn rút 1 bài.',
  blade_skill: 'Thanh Long Yển Nguyệt Đao', '#blade_skill': 'Thanh Long Đao: bạn có thể dùng thêm 1 lá Sát lên mục tiêu.',
  spear_skill: 'Trượng Bát Xà Mâu', '#spear_skill': 'Trượng Bát Xà Mâu: dùng 2 lá bài trên tay như một lá Sát.',
  axe_skill: 'Quán Thạch Phủ', '#axe_skill': 'Quán Thạch Phủ: bỏ 2 lá bài để ép Sát trúng đích.',
  kylin_bow_skill: 'Kỳ Lân Cung', '#kylin_bow_skill': 'Kỳ Lân Cung: bạn có thể bắn hạ 1 Tọa Kỵ của mục tiêu.',
  crossbow_skill: 'Chư Cát Liên Nỗ', '#crossbow_skill': 'Chư Cát Liên Nỗ: không giới hạn số lần dùng Sát.',
  zhuge_crossbow_skill: 'Chư Cát Liên Nỗ', '#zhuge_crossbow_skill': 'Chư Cát Liên Nỗ: không giới hạn số lần dùng Sát.',
  ice_sword_skill: 'Hàn Băng Kiếm', '#ice_sword_skill': 'Hàn Băng Kiếm: bạn có thể bỏ 2 lá của mục tiêu thay vì gây sát thương.',
  guding_blade_skill: 'Cổ Đĩnh Đao', '#guding_blade_skill': 'Cổ Đĩnh Đao: tăng sát thương lên mục tiêu không có bài.',
  fan_skill: 'Chu Tước Phiến', '#fan_skill': 'Chu Tước Phiến: biến Sát thường thành Hỏa Sát.',
  nioh_shield_skill: 'Nhân Vương Thuẫn', '#nioh_shield_skill': 'Nhân Vương Thuẫn: vô hiệu hóa Sát đen.',
  silver_lion_skill: 'Bạch Ngân Sư Tử', '#silver_lion_skill': 'Bạch Ngân Sư Tử: chỉ chịu tối đa 1 sát thương / hồi 1 máu khi mất giáp.',
  vine_skill: 'Đằng Giáp', '#vine_skill': 'Đằng Giáp: miễn dịch Sát thường/Vạn Tiễn/Nam Man.',
  wooden_ox_skill: 'Mộc Ngưu Lưu Mã', '#wooden_ox_skill': 'Mộc Ngưu Lưu Mã: cất giữ hoặc di chuyển bài.',

  // Common interactive prompts and requests
  '#AskForCard': 'Hãy chọn một lá bài theo yêu cầu.',
  '#AskForCards': 'Hãy chọn các lá bài theo yêu cầu.',
  '#AskForGeneral': 'Hãy chọn võ tướng.',
  '#AskForChoice': 'Hãy chọn một phương án.',
  '#AskForNullification': 'Có ai muốn dùng Vô Giải Khả Kích cho %arg không?',
  '#AskForCardChosen': '%arg: hãy chọn một lá bài của %src.',
  '#AskForCardShow': 'Hãy công khai một lá bài.',
  '#AskForDiscard': 'Hãy chọn các lá bài để bỏ.',
  '#AskForPoxi': 'Bố Tích: hãy chọn các lá bài.',
  '#slash-jink': 'Xin hãy dùng Thiểm để né Sát của %src.',
  '#slash_skill': 'Dùng lá Sát lên một mục tiêu trong tầm.',
  '#jink_skill': 'Dùng Thiểm để né đòn.',
  '#duel-slash': 'Quyết đấu: hãy dùng Sát hoặc nhận 1 sát thương từ %src.',
  '#savage_assault-slash': 'Nam Man Xâm Nhập: hãy dùng Sát hoặc mất 1 máu.',
  '#archery_attack-jink': 'Vạn Tiễn Tề Phát: hãy dùng Thiểm hoặc mất 1 máu.',
  '#fire_attack-discard': 'Hỏa Công: hãy bỏ 1 lá bài cùng chất với lá công khai.',
  '#collateral-slash': 'Tá Đao Sát Nhân: hãy dùng Sát nhắm vào %dest hoặc giao nộp vũ khí.',
  '#snatch-card': 'Thuận Thủ Khiên Dương: hãy chọn một lá bài của %src.',
  '#dismantlement-card': 'Quá Hà Đoạt Kiều: hãy chọn một lá bài của %src.',
  '#iron_chain-card': 'Thiết Tỏa Liên Hoàn: chọn mục tiêu để xích/mở xích hoặc trùng chú.',
  'iron_chain_skill': 'Thiết Tỏa Liên Hoàn',
  '#iron_chain_skill': 'Thiết Tỏa Liên Hoàn: Chọn 1-2 người để đổi trạng thái xích (hoặc chọn Trùng Chú để đổi lá)',
  ':iron_chain_skill': 'Chọn 1-2 người để đổi trạng thái xích, hoặc chọn Trùng Chú để đặt lá này vào chồng bài bỏ và rút 1 lá mới.',
  'recast': 'Trùng Chú',
  '#recast': 'Trùng Chú: Đặt lá này vào chồng bài bỏ và rút 1 lá',
  ':recast': 'Bạn có thể đặt lá này vào chồng bài bỏ, sau đó rút 1 lá.',
  'reveal_skill&': 'Mở tướng',
  '#reveal_skill&': 'Chọn một tướng để mở tướng',
  ':reveal_skill&': 'Giai đoạn ra bài, bạn có thể mở 1 tướng có Tỏa định kỹ.',
  'fenji': 'Phấn Kích',
  ':fenji': 'Trong giai đoạn kết thúc của một người, nếu người đó không có bài trên tay, bạn có thể cho người đó rút 2 lá, rồi bạn mất 1 máu.',
  '#fenji-invoke': 'Phấn Kích: Bạn có muốn cho %dest rút 2 lá bài và bạn mất 1 máu không?',
  'm_ex__fenji': 'Phấn Kích',
  ':m_ex__fenji': 'Trong giai đoạn kết thúc của một người, nếu người đó không có bài trên tay, bạn có thể cho người đó rút 2 lá, rồi bạn mất 1 máu.',
  '#m_ex__fenji-invoke': 'Phấn Kích: Bạn có muốn cho %dest rút 2 lá bài và bạn mất 1 máu không?',
  'hs__fenji': 'Phấn Kích',
  ':hs__fenji': 'Trong giai đoạn kết thúc của một người, nếu người đó không có bài trên tay, bạn có thể cho người đó rút 2 lá, rồi bạn mất 1 máu.',
  '#hs__fenji-invoke': 'Phấn Kích: Bạn có muốn cho %dest rút 2 lá bài và bạn mất 1 máu không?',
  '#wooden_ox-put': 'Mộc Ngưu Lưu Mã: chọn bài để cất vào Mộc Ngưu.',
  '#wooden_ox-move': 'Mộc Ngưu Lưu Mã: di chuyển Mộc Ngưu sang người chơi khác.',
  amazing_grace_skill: 'Ngũ Cốc Phong Đăng',
  '#amazing_grace_skill': 'Lật ra số lá trên đỉnh chồng bài rút bằng số người chơi, mỗi người thu lấy 1 lá.',
  ':amazing_grace_skill': 'Lật ra số lá trên đỉnh chồng bài rút bằng số người chơi, mỗi người thu lấy 1 lá.',
  god_salvation_skill: 'Đào Viên Kết Nghĩa',
  '#god_salvation_skill': 'Tất cả người chơi hồi 1 máu.',
  ':god_salvation_skill': 'Tất cả người chơi hồi 1 máu.',
  dismantlement_skill: 'Quá Hà Sách Kiều',
  '#dismantlement_skill': 'Chọn 1 người khác có bài trong vùng chơi, bạn bỏ 1 lá trong vùng chơi của họ.',
  ':dismantlement_skill': 'Chọn 1 người khác có bài trong vùng chơi, bạn bỏ 1 lá trong vùng chơi của họ.',
  snatch_skill: 'Thuận Thủ Khiên Dương',
  '#snatch_skill': 'Chọn 1 người ở khoảng cách 1 và có bài trong vùng chơi, bạn thu lấy 1 lá của họ.',
  ':snatch_skill': 'Chọn 1 người ở khoảng cách 1 và có bài trong vùng chơi, bạn thu lấy 1 lá của họ.',
  ex_nihilo_skill: 'Vô Trung Sinh Hữu',
  '#ex_nihilo_skill': 'Bạn rút 2 lá.',
  ':ex_nihilo_skill': 'Bạn rút 2 lá.',
  savage_assault_skill: 'Nam Man Xâm Nhập',
  '#savage_assault_skill': 'Tất cả người khác cần đánh ra 1 【Sát】, nếu không, họ nhận 1 sát thương.',
  ':savage_assault_skill': 'Tất cả người khác cần đánh ra 1 【Sát】, nếu không, họ nhận 1 sát thương.',
  archery_attack_skill: 'Vạn Tiễn Tề Phát',
  '#archery_attack_skill': 'Tất cả người khác cần đánh ra 1 【Thiểm】, nếu không, họ nhận 1 sát thương.',
  ':archery_attack_skill': 'Tất cả người khác cần đánh ra 1 【Thiểm】, nếu không, họ nhận 1 sát thương.',
  duel_skill: 'Quyết Đấu',
  '#duel_skill': 'Chọn 1 người khác, bắt đầu từ họ, lần lượt đánh ra 1 lá 【Sát】.',
  ':duel_skill': 'Chọn 1 người khác, bắt đầu từ họ, lần lượt đánh ra 1 lá 【Sát】.',
  collateral_skill: 'Tá Đao Sát Nhân',
  '#collateral_skill': 'Chọn 1 người khác có vũ khí trong vùng trang bị.',
  ':collateral_skill': 'Chọn 1 người khác có vũ khí trong vùng trang bị.',
  fire_attack_skill: 'Hỏa Công',
  '#fire_attack_skill': 'Chọn 1 người có bài trên tay, người này công khai 1 lá.',
  ':fire_attack_skill': 'Chọn 1 người có bài trên tay, người này công khai 1 lá.',
  nullification_skill: 'Vô Giải Khả Kích',
  '#nullification_skill': 'Vô hiệu hóa một lá Cẩm Nang.',
  ':nullification_skill': 'Vô hiệu hóa một lá Cẩm Nang.',
  '#PreventDamage': 'Do %arg, %arg3 điểm sát thương %arg2 do %to sắp gây ra cho %from đã được ngăn chặn.',
  '#PreventDamageWithNoFrom': 'Do %arg, %arg3 điểm sát thương %arg2 mà %from sắp phải chịu đã được ngăn chặn.',
  '$ShuffleDrawPile': 'Đã xáo lại chồng bài, chồng bài hiện có %arg lá bài.',
};
