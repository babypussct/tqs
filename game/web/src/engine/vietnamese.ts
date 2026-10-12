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
};
