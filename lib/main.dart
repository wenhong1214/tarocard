import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  // 确保在加载前 Flutter 框架已经准备好
  WidgetsFlutterBinding.ensureInitialized();
  
  // 加载包含 API Key 的 .env 文件

  
  runApp(const TarotApp());
}

class TarotApp extends StatelessWidget {
  const TarotApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '78张塔罗全牌阵',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E)),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ================= 数据模型 =================
class TarotCard {
  final String name;
  final String number;
  final String arcana;
  final String? suit;
  final String img;
  final String uprightMeaning;
  final String reversedMeaning;

  TarotCard({
    required this.name,
    required this.number,
    required this.arcana,
    this.suit,
    required this.img,
    required this.uprightMeaning,
    required this.reversedMeaning,
  });
}

class DrawnCard {
  final TarotCard card;
  final bool isReversed;
  final String positionMeaning; // 过去、现在、未来

  DrawnCard({required this.card, required this.isReversed, required this.positionMeaning});
}

// ================= 整合你的 78 张牌 JSON 数据 =================
// 自动将 JSON 转换为 Flutter 对象，并生成基础牌意模板
// ================= 整合你的 78 张牌 JSON 数据 =================
final List<TarotCard> tarotDeck = rawTarotData.map((data) {
  return TarotCard(
    name: data['name'],
    number: data['number'],
    arcana: data['arcana'],
    suit: data['suit'],
    img: data['img'],
    // 直接读取我们写好的正逆位解析！
    uprightMeaning: data['upright'] ?? "解析加载中...",
    reversedMeaning: data['reversed'] ?? "解析加载中...",
  );
}).toList();


// ================= 1. 首页 (选择模式) =================
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('塔罗占卜 (78牌完整版)', style: TextStyle(fontFamily: 'serif'))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 80, color: Colors.amber),
            const SizedBox(height: 20),
            const Text('请选择占卜方式', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.touch_app),
              label: const Text('线上虚拟抽牌 (3D翻牌)'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VirtualDrawScreen())),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.view_module),
              label: const Text('现实自主选牌 (手动录入)'),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManualDrawScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= 2. 线上虚拟抽牌 (3D翻牌特效) =================
class VirtualDrawScreen extends StatefulWidget {
  const VirtualDrawScreen({Key? key}) : super(key: key);

  @override
  _VirtualDrawScreenState createState() => _VirtualDrawScreenState();
}

class _VirtualDrawScreenState extends State<VirtualDrawScreen> {
  List<DrawnCard> drawnCards = [];
  int flippedCount = 0;

  @override
  void initState() {
    super.initState();
    // 从 78 张牌中随机洗牌挑 3 张
    final deck = List<TarotCard>.from(tarotDeck)..shuffle();
    final positions = ['过去', '现在', '未来'];
    for (int i = 0; i < 3; i++) {
      drawnCards.add(DrawnCard(
        card: deck[i],
        isReversed: Random().nextBool(), // 随机正逆位
        positionMeaning: positions[i],
      ));
    }
  }

  void onCardFlipped() {
    setState(() {
      flippedCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('三牌阵：过去 / 现在 / 未来')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('冥想你的问题，然后依次翻开卡牌', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(drawnCards[index].positionMeaning, style: const TextStyle(color: Colors.amber)),
                      const SizedBox(height: 10),
                      TarotCardWidget(
                        drawnCard: drawnCards[index],
                        onFlipped: onCardFlipped,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 40),
          if (flippedCount == 3)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ReadingScreen(cards: drawnCards)));
              },
              child: const Text('查看详细牌意解析', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            )
        ],
      ),
    );
  }
}

class TarotCardWidget extends StatefulWidget {
  final DrawnCard drawnCard;
  final VoidCallback onFlipped;

  const TarotCardWidget({Key? key, required this.drawnCard, required this.onFlipped}) : super(key: key);

  @override
  _TarotCardWidgetState createState() => _TarotCardWidgetState();
}

class _TarotCardWidgetState extends State<TarotCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void _flipCard() {
    if (!_isFront) {
      _controller.forward();
      _isFront = true;
      widget.onFlipped(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) 
            ..rotateY(angle);
          final isUnderBack = angle > pi / 2;

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: isUnderBack
                ? Transform(
                    transform: Matrix4.identity()
                      ..rotateY(pi)
                      ..rotateZ(widget.drawnCard.isReversed ? pi : 0),
                    alignment: Alignment.center,
                    child: Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.amber, width: 2)),
                      // 【关键修改】这里改成了加载本地 assets/images/ 里的图片！
                      child: Image.asset('assets/images/${widget.drawnCard.card.img}', height: 160, fit: BoxFit.cover,
                        // 如果你还没放图，这里会友好提示避免崩溃
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 160, color: Colors.grey[800],
                          child: const Center(child: Text('缺图', style: TextStyle(color: Colors.white))),
                        ),
                      ),
                    ),
                  )
                : Container(
                    height: 160,
                    width: 95,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Colors.indigo, Colors.deepPurple]),
                      border: Border.all(color: Colors.white70, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(child: Icon(Icons.star, color: Colors.white54, size: 40)),
                  ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ================= 3. 现实手动录入模式 =================
class ManualDrawScreen extends StatefulWidget {
  const ManualDrawScreen({Key? key}) : super(key: key);

  @override
  _ManualDrawScreenState createState() => _ManualDrawScreenState();
}

class _ManualDrawScreenState extends State<ManualDrawScreen> {
  List<DrawnCard> selectedCards = [];
  final positions = ['过去', '现在', '未来'];

  void _selectCard(TarotCard card) {
    if (selectedCards.length >= 3) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('【${card.name}】的状态是？'),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => selectedCards.add(DrawnCard(card: card, isReversed: false, positionMeaning: positions[selectedCards.length])));
                Navigator.pop(context);
                _checkFinish();
              },
              child: const Text('正位 (Upright)'),
            ),
            TextButton(
              onPressed: () {
                setState(() => selectedCards.add(DrawnCard(card: card, isReversed: true, positionMeaning: positions[selectedCards.length])));
                Navigator.pop(context);
                _checkFinish();
              },
              child: const Text('逆位 (Reversed)', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  void _checkFinish() {
    if (selectedCards.length == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ReadingScreen(cards: selectedCards)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('请选择你抽到的牌 (${selectedCards.length}/3)')),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, childAspectRatio: 0.6, crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemCount: tarotDeck.length,
        itemBuilder: (context, index) {
          final card = tarotDeck[index];
          return GestureDetector(
            onTap: () => _selectCard(card),
            child: GridTile(
              footer: GridTileBar(backgroundColor: Colors.black87, title: Text(card.name, style: const TextStyle(fontSize: 10))),
              // 【关键修改】列表里也改为加载本地图
              child: Image.asset('assets/images/${card.img}', fit: BoxFit.cover,
                 errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported, color: Colors.white24)),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ================= 4. 解牌结果页面 =================
// 需要在文件最顶部（第1行）加入这两个库的引入：
// import 'package:google_generative_ai/google_generative_ai.dart';
// import 'package:flutter_markdown/flutter_markdown.dart';

// ================= 4. 解牌结果页面 (接入免费大模型 AI) =================
class ReadingScreen extends StatefulWidget {
  final List<DrawnCard> cards;

  const ReadingScreen({Key? key, required this.cards}) : super(key: key);

  @override
  _ReadingScreenState createState() => _ReadingScreenState();
}

// ================= 4. 解牌结果页面 (完美结合本地解析与 AI 综合解读) =================

// ================= 4. 解牌结果页面 (通过 Vercel 代理安全调用 Gemini) =================
// 
// 改动说明：
// 1. 移除了 google_generative_ai 包的使用
// 2. 改用 http 包，通过你自己的 /api/gemini 代理发请求
// 3. 不再需要 API Key 在 Flutter 代码里
//
// pubspec.yaml 需要加：
//   http: ^1.2.0
// 然后运行: flutter pub get
//
// 同时删掉 pubspec.yaml 里的：
//   google_generative_ai: ...
//   flutter_dotenv: ...
//
// main() 里的 dotenv 相关代码也可以删掉了


class _ReadingScreenState extends State<ReadingScreen> {
  String aiResponse = "";
  bool isGenerating = false;
  bool showAI = false;
  bool isFinished = false;

  // ✅ 你的 Vercel 代理 URL（不需要 https:// 前面漏掉了，加上）
  final String _proxyUrl = 'https://tai-taro.vercel.app/api/gemini';

  Future<void> _askAI() async {
    setState(() {
      showAI = true;
      isGenerating = true;
      aiResponse = "🔮 灵界连结中，占卜师正在为你综合解读这三张牌的深层联系...\n\n";
    });

    String prompt = "你是一位神秘且专业的塔罗牌占卜师。用户抽到了以下三张牌：\n";

    for (var c in widget.cards) {
      String status = c.isReversed ? '逆位' : '正位';
      prompt += "【${c.positionMeaning}】：${c.card.name}（$status）\n";
    }

    prompt += "\n请结合这三张牌的阵法含义，给出一份深度、神秘、且具有指引和治愈意义的综合解牌。重点分析这三张牌之间的联系。排版清晰。";

    try {
      final response = await http.post(
        Uri.parse(_proxyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "prompt": prompt,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          aiResponse = data['text'] ?? '占卜师暂时无法解读，请稍后再试。';
        });
      } else {
        setState(() {
          aiResponse =
              "⚠️ API 连接失败 (${response.statusCode})\n\n${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        aiResponse = "⚠️ 占卜师暂时失去了连接，请检查网络。($e)";
      });
    } finally {
      setState(() {
        isGenerating = false;
        isFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('你的塔罗指引')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------------- 第1部分：本地基础牌意 ----------------
          ...widget.cards.map((c) {
            final status = c.isReversed ? "逆位" : "正位";
            final meaning = c.isReversed ? c.card.reversedMeaning : c.card.uprightMeaning;

            return Card(
              color: const Color(0xFF2C2C2C),
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform(
                      transform: Matrix4.identity()..rotateZ(c.isReversed ? pi : 0),
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/${c.card.img}',
                        width: 80,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) =>
                            Container(width: 80, height: 140, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '【${c.positionMeaning}】 ${c.card.name}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '状态: $status',
                            style: TextStyle(
                                color: c.isReversed
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                                fontWeight: FontWeight.bold),
                          ),
                          const Divider(color: Colors.white24),
                          Text(
                            meaning,
                            style: const TextStyle(
                                fontSize: 15, height: 1.4, color: Colors.white),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          }).toList(),

          // ---------------- 第2部分：AI 综合解析框 ----------------
          if (showAI)
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.5)),
              ),
              child: MarkdownBody(
                data: aiResponse,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                      fontSize: 16, height: 1.6, color: Colors.white),
                ),
              ),
            ),

          const SizedBox(height: 80),
        ],
      ),

      // ---------------- 第3部分：AI 按钮 ----------------
      floatingActionButton: isFinished
          ? null
          : FloatingActionButton.extended(
              backgroundColor: Colors.amber,
              icon: isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.auto_awesome, color: Colors.black),
              label: Text(
                isGenerating ? '大师正在观星...' : '✨ 请 AI 综合深度解牌',
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold),
              ),
              onPressed: isGenerating ? null : _askAI,
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}


// ================= 你提供的 78 张牌原始 JSON 数据 =================
// ================= 你提供的 78 张牌数据 (完美中英双语版) =================
// ================= 你提供的 78 张牌数据 (终极解析版) =================
const List<Map<String, dynamic>> rawTarotData = [
  {"name": "愚者 (The Fool)", "number": "0", "arcana": "大阿尔卡纳", "suit": null, "img": "m00.jpg",
   "upright": "全新的开始、充满未知的冒险、绝对的自由与天真。放空心思，勇敢踏上未知的旅程，相信宇宙的安排。", 
   "reversed": "鲁莽、不切实际、错失良机。你的行为可能过于冲动，缺乏深思熟虑，小心过度冒险带来的危机。"},
  {"name": "魔术师 (The Magician)", "number": "1", "arcana": "大阿尔卡纳", "suit": null, "img": "m01.jpg",
   "upright": "创造力、行动力、化无为有。你已经拥有了实现目标所需的所有资源，现在是专注并付诸行动的最好时机。", 
   "reversed": "才华未展、缺乏计划、甚至可能遭遇欺骗。你可能在浪费自己的天赋，或者被某些花言巧语所蒙蔽。"},
  {"name": "女祭司 (The High Priestess)", "number": "2", "arcana": "大阿尔卡纳", "suit": null, "img": "m02.jpg",
   "upright": "直觉、潜意识、神秘的内在智慧。顺从你的直觉，现在不是向外行动的时候，而是向内探索、等待时机。", 
   "reversed": "直觉受阻、情绪化、忽略了内心的声音。你可能过于依赖表面的逻辑，而忽略了隐藏在水面下的真相。"},
  {"name": "皇后 (The Empress)", "number": "3", "arcana": "大阿尔卡纳", "suit": null, "img": "m03.jpg",
   "upright": "丰收、母性、培育、创造力。享受生活的美好，感受爱与被爱，你的计划正在孕育并即将开花结果。", 
   "reversed": "过度依赖、溺爱、创造力受阻。你可能在感情或物质上过于索取，或者沉溺于享乐而停滞不前。"},
  {"name": "皇帝 (The Emperor)", "number": "4", "arcana": "大阿尔卡纳", "suit": null, "img": "m04.jpg",
   "upright": "权力、规则、控制、稳定的基础。你需要建立纪律和秩序，用理性和坚定的意志去掌控全局。", 
   "reversed": "独裁、僵化、失去控制。你可能过于固执己见，或者缺乏自律导致原本的计划崩塌。"},
  {"name": "教皇 (The Hierophant)", "number": "5", "arcana": "大阿尔卡纳", "suit": null, "img": "m05.jpg",
   "upright": "传统、信仰、教育、精神指引。遵从传统规则会有所帮助，或者寻找一位经验丰富的导师为你指点迷津。", 
   "reversed": "打破常规、盲从、挑战权威。你不再受制于传统的束缚，渴望开创属于自己的全新信仰或道路。"},
  {"name": "恋人 (The Lovers)", "number": "6", "arcana": "大阿尔卡纳", "suit": null, "img": "m06.jpg",
   "upright": "爱情、和谐、价值观的契合。面临一个重要的选择，请遵从你的真心，一段充满吸引力的关系正在展开。", 
   "reversed": "关系破裂、错误的选择、价值观冲突。感情中可能出现不和，或者你在面临选择时逃避了责任。"},
  {"name": "战车 (The Chariot)", "number": "7", "arcana": "大阿尔卡纳", "suit": null, "img": "m07.jpg",
   "upright": "意志力、胜利、克服困难。通过坚定的决心和强大的自律，你将克服一切阻力，成功掌控眼前的局面。", 
   "reversed": "失去方向、受阻、缺乏自律。你可能感到失控，或者因为内部的冲突而无法向前推进。"},
  {"name": "力量 (Strength)", "number": "8", "arcana": "大阿尔卡纳", "suit": null, "img": "m08.jpg",
   "upright": "内在力量、勇气、耐心。用温柔和同理心去化解冲突，真正的力量来源于内心的平静与坚韧。", 
   "reversed": "自我怀疑、软弱、情绪失控。你可能对自己的能力感到不自信，或者被内心的恐惧和愤怒所支配。"},
  {"name": "隐士 (The Hermit)", "number": "9", "arcana": "大阿尔卡纳", "suit": null, "img": "m09.jpg",
   "upright": "内省、寻找内在智慧、退避深思。暂时远离喧嚣，独处能帮你找到一直苦苦追寻的答案。", 
   "reversed": "孤立、迷失、拒绝外界帮助。过度封闭自我可能让你陷入孤独，是时候重新回到人群中了。"},
  {"name": "命运之轮 (Wheel of Fortune)", "number": "10", "arcana": "大阿尔卡纳", "suit": null, "img": "m10.jpg",
   "upright": "转机、命运的安排、不可避免的变化。运势即将好转，顺应生命周期的起伏，抓住突如其来的好运。", 
   "reversed": "抗拒改变、失去控制、暂时的厄运。事情的发展偏离了预期，不要逆势而为，耐心等待低谷过去。"},
  {"name": "正义 (Justice)", "number": "11", "arcana": "大阿尔卡纳", "suit": null, "img": "m11.jpg",
   "upright": "公平、诚实、因果报应。理性的决定将带来公正的结果，你过去的所作所为正在产生相应的回报。", 
   "reversed": "不公、偏见、逃避责任。可能面临不公平的待遇，或者你在某件事上缺乏诚实和客观的判断。"},
  {"name": "倒吊人 (The Hanged Man)", "number": "12", "arcana": "大阿尔卡纳", "suit": null, "img": "m12.jpg",
   "upright": "换位思考、等待、自愿的牺牲。当前的停滞是为了更深层的顿悟，换个角度看问题，放下无谓的执念。", 
   "reversed": "无谓的牺牲、停滞不前、错失机会。你可能在不值得的事情上浪费精力，且抗拒做出必要的改变。"},
  {"name": "死神 (Death)", "number": "13", "arcana": "大阿尔卡纳", "suit": null, "img": "m13.jpg",
   "upright": "结束与新生、不可逆转的转变。一个旧的阶段彻底结束，勇敢地放手，为全新的开始腾出空间。", 
   "reversed": "恐惧改变、死板、拒绝接受现实。你正紧紧抓住过去不放，这种对改变的抗拒只会延长你的痛苦。"},
  {"name": "节制 (Temperance)", "number": "14", "arcana": "大阿尔卡纳", "suit": null, "img": "m14.jpg",
   "upright": "平衡、中庸、和谐与耐心。将不同的元素完美结合，保持情绪的稳定，稳步走向治愈和提升。", 
   "reversed": "失衡、极端、缺乏耐心。生活可能陷入了某种混乱，你在处理问题时可能采取了过于极端的手段。"},
  {"name": "恶魔 (The Devil)", "number": "15", "arcana": "大阿尔卡纳", "suit": null, "img": "m15.jpg",
   "upright": "诱惑、束缚、沉迷于物质。你感到被某种坏习惯、有毒的关系或物质欲望所困，其实锁链在你手中。", 
   "reversed": "挣脱束缚、克服诱惑、重获自由。你终于意识到了问题的所在，开始摆脱阴暗面，找回自控力。"},
  {"name": "高塔 (The Tower)", "number": "16", "arcana": "大阿尔卡纳", "suit": null, "img": "m16.jpg",
   "upright": "突变、意外的灾难、打破虚假的幻象。建立在不稳固基础上的事物将崩塌，虽然痛苦，但能带来彻底的解脱。", 
   "reversed": "害怕改变、死撑、拖延结局。灾难可能被勉强避免，或者你正竭力维持一个注定要破裂的假象。"},
  {"name": "星星 (The Star)", "number": "17", "arcana": "大阿尔卡纳", "suit": null, "img": "m17.jpg",
   "upright": "希望、宁静、治愈。在经历了风暴之后，灵感与希望重新降临，宇宙正在祝福你，请保持乐观。", 
   "reversed": "绝望、缺乏信心、失去灵感。你可能感到沮丧，对未来失去了希望，需要重新找回内心的光芒。"},
  {"name": "月亮 (The Moon)", "number": "18", "arcana": "大阿尔卡纳", "suit": null, "img": "m18.jpg",
   "upright": "幻觉、恐惧、潜意识的波动。事情并没有表面看起来那么简单，注意隐藏的危险，面对内心的焦虑。", 
   "reversed": "揭露真相、摆脱困惑。迷雾正在散去，你逐渐看清了事情的真相，成功克服了潜意识的恐惧。"},
  {"name": "太阳 (The Sun)", "number": "19", "arcana": "大阿尔卡纳", "suit": null, "img": "m19.jpg",
   "upright": "成功、快乐、充满活力。一切都在朝着最好的方向发展，真相大白，你的努力将获得极大的满足与成就。", 
   "reversed": "暂时的阴霾、成功延迟。虽然依旧是正向的，但快乐可能打了个折扣，或者你需要付出更多努力才能见彩虹。"},
  {"name": "审判 (Judgement)", "number": "20", "arcana": "大阿尔卡纳", "suit": null, "img": "m20.jpg",
   "upright": "觉醒、重生、内心的呼唤。到了总结过去、宽恕自己和他人、并作出影响深远决定的时候了。", 
   "reversed": "自我怀疑、无法释怀、拒绝面对。你可能因为过去的内疚或恐惧，而不敢迎接生命的新阶段。"},
  {"name": "世界 (The World)", "number": "21", "arcana": "大阿尔卡纳", "suit": null, "img": "m21.jpg",
   "upright": "完成、圆满、成功的终点。一个重要的生命周期完美结束，你拥有了一切，即将迈入更高的层次。", 
   "reversed": "未完成、停滞、准备不足。距离成功只有一步之遥，但可能因为某些未解决的问题而暂时受阻。"},

  // 以下为小阿尔卡纳 (极其精简精准的解牌)
  {"name": "圣杯王牌 (Ace of Cups)", "number": "1", "arcana": "小阿尔卡纳", "suit": "圣杯", "img": "c01.jpg",
   "upright": "感情的崭新开始、爱意涌动、新恋情或新友谊的诞生。", "reversed": "情感枯竭、直觉受阻、感情可能遭遇单相思或冷漠。"},
  {"name": "圣杯二 (Two of Cups)", "number": "2", "arcana": "小阿尔卡纳", "suit": "圣杯", "img": "c02.jpg",
   "upright": "完美的伴侣关系、互相吸引、和谐的合作与誓言。", "reversed": "关系破裂、沟通不畅、彼此之间产生不信任或分离。"},
  {"name": "圣杯三 (Three of Cups)", "number": "3", "arcana": "小阿尔卡纳", "suit": "圣杯", "img": "c03.jpg",
   "upright": "庆祝、欢乐的聚会、闺蜜/兄弟般的友谊与分享。", "reversed": "乐极生悲、过度放纵、或者关系中出现了第三方的干扰。"},
  {"name": "圣杯四 (Four of Cups)", "number": "4", "arcana": "小阿尔卡纳", "suit": "圣杯", "img": "c04.jpg",
   "upright": "厌倦、冷漠、对现状不满而错失了外界递来的新机遇。", "reversed": "重新振作、走出低谷、开始愿意接受新的事物和机会。"},
  {"name": "圣杯五 (Five of Cups)", "number": "5", "arcana": "小阿尔卡纳", "suit": "圣杯", "img": "c05.jpg",
   "upright": "悲伤、失落、过度沉溺于已经失去的事物，忽略了剩下的美好。", "reversed": "逐渐走出阴霾、释怀过去的伤痛、重新找回内心的平静。"},
  {"name": "圣杯六 (Six of Cups)", "number": "6", "arcana": "小阿尔卡纳", "suit": "圣杯", "img": "c06.jpg",
   "upright": "童年的回忆、纯真的感情、故人重逢或收到礼物。", "reversed": "过度沉溺过去、拒绝成长、需要面对当前的现实问题。"},
  {"name": "圣杯七 (Seven of Cups)", "number": "7", "arcana": "小阿尔卡纳", "suit": "圣杯", "img": "c07.jpg",
   "upright": "充满幻象与选择、白日梦、需要看清什么才是真实的。", "reversed": "认清现实、做出明确的决定、不再被虚假的诱惑所迷惑。"},
  {"name": "圣杯八 (Eight of Cups)", "number": "8", "arcana": "小阿尔卡纳", "suit": "圣杯", "img": "c08.jpg",
   "upright": "放弃现有的安逸、转身离开、去追寻更高的精神满足。", "reversed": "害怕未知、不敢离开有毒的环境、在去留之间挣扎。"},
  {"name": "圣杯九 (Nine of Cups)", "number": "9", "arcana": "小阿尔卡纳", "suit": "圣杯", "img": "c09.jpg",
   "upright": "美梦成真、极度的物质与精神满足、个人的得意与享受。", "reversed": "贪婪、自满、过度纵欲或者期待的愿望最终落空。"},
  {"name": "圣杯十 (Ten of Cups)", "number": "10", "arcana": "小阿尔卡纳", "suit": "圣杯", "img": "c10.jpg",
   "upright": "美满的家庭、长久的幸福、情感上的终极和谐与平静。", "reversed": "家庭冲突、失去和谐、表面风光但内在情感已经破裂。"},
  {"name": "圣杯侍从 (Page of Cups)", "number": "11", "arcana": "小阿尔卡纳", "suit": "圣杯", "img": "c11.jpg",
   "upright": "浪漫的消息、充满想象力的新起点、敏感而温柔的探索。", "reversed": "情感不成熟、过于情绪化、或者收到令人失望的消息。"},
  {"name": "圣杯骑士 (Knight of Cups)", "number": "12", "arcana": "小阿尔卡纳", "suit": "圣杯", "img": "c12.jpg",
   "upright": "浪漫的追求者、理想主义、顺从内心的冲动与爱意。", "reversed": "虚伪的承诺、嫉妒心强、或者过于情绪化而不切实际。"},
  {"name": "圣杯王后 (Queen of Cups)", "number": "13", "arcana": "小阿尔卡纳", "suit": "圣杯", "img": "c13.jpg",
   "upright": "极强的同理心、温柔、极具直觉力的女性特质与抚慰。", "reversed": "情绪泛滥、过度敏感、容易受外界影响或显得有些病态。"},
  {"name": "圣杯国王 (King of Cups)", "number": "14", "arcana": "小阿尔卡纳", "suit": "圣杯", "img": "c14.jpg",
   "upright": "情感掌控力强、宽容、成熟、能冷静处理复杂的人际关系。", "reversed": "操控他人情感、外表冷静但内心冷漠、或者情绪压抑。"},

  {"name": "宝剑王牌 (Ace of Swords)", "number": "1", "arcana": "小阿尔卡纳", "suit": "宝剑", "img": "s01.jpg",
   "upright": "清晰的思考、突破性的真相、带来胜利的新理念与决断力。", "reversed": "思维混乱、误解、言语伤人或者计划在初期就遭到挫折。"},
  {"name": "宝剑二 (Two of Swords)", "number": "2", "arcana": "小阿尔卡纳", "suit": "宝剑", "img": "s02.jpg",
   "upright": "僵局、逃避现实、在艰难的选择面前蒙住双眼、拒不妥协。", "reversed": "打破僵局、终于看清真相并做出了不得已但必要的选择。"},
  {"name": "宝剑三 (Three of Swords)", "number": "3", "arcana": "小阿尔卡纳", "suit": "宝剑", "img": "s03.jpg",
   "upright": "令人心碎的痛苦、悲伤、背叛、或是必须要面对的残酷真相。", "reversed": "痛苦逐渐减轻、开始疗愈内心的创伤、学会释怀与原谅。"},
  {"name": "宝剑四 (Four of Swords)", "number": "4", "arcana": "小阿尔卡纳", "suit": "宝剑", "img": "s04.jpg",
   "upright": "休息、恢复、静修冥想、在强烈的压力后需要退避修养。", "reversed": "被迫行动、疲劳过度、或者已经休息完毕准备重新出发。"},
  {"name": "宝剑五 (Five of Swords)", "number": "5", "arcana": "小阿尔卡纳", "suit": "宝剑", "img": "s05.jpg",
   "upright": "不择手段的胜利、冲突、损人不利己、充满敌意的环境。", "reversed": "和解、放下恩怨、或者是冲突升级导致不可挽回的伤害。"},
  {"name": "宝剑六 (Six of Swords)", "number": "6", "arcana": "小阿尔卡纳", "suit": "宝剑", "img": "s06.jpg",
   "upright": "逐渐渡过难关、向平静的彼岸过渡、带着伤痛继续前行。", "reversed": "困境难逃、抗拒改变、或者过去的阴影仍在纠缠不休。"},
  {"name": "宝剑七 (Seven of Swords)", "number": "7", "arcana": "小阿尔卡纳", "suit": "宝剑", "img": "s07.jpg",
   "upright": "欺骗、背着人做事、策略性的撤退或是通过捷径获取利益。", "reversed": "谎言被揭穿、必须面对现实、不再自欺欺人。"},
  {"name": "宝剑八 (Eight of Swords)", "number": "8", "arcana": "小阿尔卡纳", "suit": "宝剑", "img": "s08.jpg",
   "upright": "自我限制、感到被束缚、画地为牢，其实解开眼罩就能自由。", "reversed": "挣脱束缚、重获自由、看清了现实并找到了出路。"},
  {"name": "宝剑九 (Nine of Swords)", "number": "9", "arcana": "小阿尔卡纳", "suit": "宝剑", "img": "s09.jpg",
   "upright": "极度的焦虑、梦魇、失眠、内疚与过度的精神折磨。", "reversed": "从噩梦中醒来、恐惧减轻、开始正视并解决心中的烦恼。"},
  {"name": "宝剑十 (Ten of Swords)", "number": "10", "arcana": "小阿尔卡纳", "suit": "宝剑", "img": "s10.jpg",
   "upright": "毁灭、彻底结束、跌入谷底，但这同时也意味着苦难已到尽头。", "reversed": "绝处逢生、重新开始、从致命的打击中逐渐恢复过来。"},
  {"name": "宝剑侍从 (Page of Swords)", "number": "11", "arcana": "小阿尔卡纳", "suit": "宝剑", "img": "s11.jpg",
   "upright": "保持警觉、旺盛的好奇心、直言不讳、机智的观察者。", "reversed": "充满敌意、流言蜚语、显得尖酸刻薄或过于冲动。"},
  {"name": "宝剑骑士 (Knight of Swords)", "number": "12", "arcana": "小阿尔卡纳", "suit": "宝剑", "img": "s12.jpg",
   "upright": "行动极其迅速、雷厉风行、急躁的推进者，但也可能缺乏思考。", "reversed": "鲁莽冲撞、不切实际、因过于急躁而导致严重的错误。"},
  {"name": "宝剑王后 (Queen of Swords)", "number": "13", "arcana": "小阿尔卡纳", "suit": "宝剑", "img": "s13.jpg",
   "upright": "独立、理智、洞察秋毫、用清晰的逻辑去剥离感情的干扰。", "reversed": "冷酷无情、尖酸刻薄、过度防御或是利用聪明才智去伤人。"},
  {"name": "宝剑国王 (King of Swords)", "number": "14", "arcana": "小阿尔卡纳", "suit": "宝剑", "img": "s14.jpg",
   "upright": "绝对的理性、权威、公正、逻辑严密且富有决断力的领导者。", "reversed": "滥用权力、独断专行、操纵欲强或是过于冷血无情。"},

  {"name": "权杖王牌 (Ace of Wands)", "number": "1", "arcana": "小阿尔卡纳", "suit": "权杖", "img": "w01.jpg",
   "upright": "强烈的灵感、爆发的创造力、充满热情的新行动或新计划。", "reversed": "缺乏动力、计划延迟、错失良机或是热情迅速消退。"},
  {"name": "权杖二 (Two of Wands)", "number": "2", "arcana": "小阿尔卡纳", "suit": "权杖", "img": "w02.jpg",
   "upright": "长远的规划、远见卓识、站在人生的十字路口决定未来的方向。", "reversed": "害怕未知、缺乏计划、将自己局限在舒适区内不敢探索。"},
  {"name": "权杖三 (Three of Wands)", "number": "3", "arcana": "小阿尔卡纳", "suit": "权杖", "img": "w03.jpg",
   "upright": "向外探索、事业初见成效、期待着更广阔的海外或跨界合作。", "reversed": "合作不顺、计划受阻、付出的努力迟迟看不到回报。"},
  {"name": "权杖四 (Four of Wands)", "number": "4", "arcana": "小阿尔卡纳", "suit": "权杖", "img": "w04.jpg",
   "upright": "庆祝、稳固的里程碑、繁荣、买房或是迈入婚姻等喜悦时刻。", "reversed": "基础不稳固、失去和谐、庆祝活动被推迟或是家庭出现不和。"},
  {"name": "权杖五 (Five of Wands)", "number": "5", "arcana": "小阿尔卡纳", "suit": "权杖", "img": "w05.jpg",
   "upright": "激烈的竞争、冲突、众人七嘴八舌的争辩、意见无法统一。", "reversed": "逃避竞争、达成共识、内部矛盾逐渐平息并找到了解决方法。"},
  {"name": "权杖六 (Six of Wands)", "number": "6", "arcana": "小阿尔卡纳", "suit": "权杖", "img": "w06.jpg",
   "upright": "光荣的胜利、获得公众的认可与赞赏、充满自信地站在巅峰。", "reversed": "骄傲自大、失去支持、名誉受损或者是期待的表彰落空。"},
  {"name": "权杖七 (Seven of Wands)", "number": "7", "arcana": "小阿尔卡纳", "suit": "权杖", "img": "w07.jpg",
   "upright": "顽强的防御、坚持自己的立场、以一敌多地克服重重阻力。", "reversed": "感到力不从心、屈服于压力、放弃抵抗或是立场动摇。"},
  {"name": "权杖八 (Eight of Wands)", "number": "8", "arcana": "小阿尔卡纳", "suit": "权杖", "img": "w08.jpg",
   "upright": "快速的行动、事情飞速进展、即将收到期待已久的消息或旅行。", "reversed": "严重的延迟、失去方向、忙乱中出错或者是沟通遇到障碍。"},
  {"name": "权杖九 (Nine of Wands)", "number": "9", "arcana": "小阿尔卡纳", "suit": "权杖", "img": "w09.jpg",
   "upright": "保持警惕、虽然疲惫但仍在坚持最后一道防线、韧性极强。", "reversed": "彻底放弃、过度防御导致偏执、体力和意志力已经耗尽。"},
  {"name": "权杖十 (Ten of Wands)", "number": "10", "arcana": "小阿尔卡纳", "suit": "权杖", "img": "w10.jpg",
   "upright": "沉重的负担、压力巨大、一个人扛下了所有责任，过度劳累。", "reversed": "终于卸下重担、学会放权、或是被压力彻底压垮无法承受。"},
  {"name": "权杖侍从 (Page of Wands)", "number": "11", "arcana": "小阿尔卡纳", "suit": "权杖", "img": "w11.jpg",
   "upright": "充满活力的探索者、热情的新想法、即将收到令人兴奋的好消息。", "reversed": "缺乏耐心、容易三分钟热度、或者是坏消息的传来。"},
  {"name": "权杖骑士 (Knight of Wands)", "number": "12", "arcana": "小阿尔卡纳", "suit": "权杖", "img": "w12.jpg",
   "upright": "勇敢的冒险家、精力充沛、充满激情但有时会显得做事冲动。", "reversed": "鲁莽好战、容易放弃、做事不计后果或者是暴躁易怒。"},
  {"name": "权杖王后 (Queen of Wands)", "number": "13", "arcana": "小阿尔卡纳", "suit": "权杖", "img": "w13.jpg",
   "upright": "极具魅力的女性、自信、热情开朗、在职场或社交中大放异彩。", "reversed": "固执己见、嫉妒心重、专横跋扈或是因为情绪失控而惹麻烦。"},
  {"name": "权杖国王 (King of Wands)", "number": "14", "arcana": "小阿尔卡纳", "suit": "权杖", "img": "w14.jpg",
   "upright": "天生的领导者、拥有宏大的愿景与非凡的魅力、事业上的开拓者。", "reversed": "独裁专制、冲动傲慢、为了达到目的可能会显得冷酷和霸道。"},

  {"name": "星币王牌 (Ace of Pentacles)", "number": "1", "arcana": "小阿尔卡纳", "suit": "星币", "img": "p01.jpg",
   "upright": "财富的新起点、实质性的回报、带来物质繁荣的新机遇或投资。", "reversed": "错失良机、财务损失、贪婪或者是新项目缺乏资金支持。"},
  {"name": "星币二 (Two of Pentacles)", "number": "2", "arcana": "小阿尔卡纳", "suit": "星币", "img": "p02.jpg",
   "upright": "灵活的资金周转、在多重任务中保持平衡、生活中的变动与适应。", "reversed": "失去平衡、财务危机、手忙脚乱或是过度透支了精力与金钱。"},
  {"name": "星币三 (Three of Pentacles)", "number": "3", "arcana": "小阿尔卡纳", "suit": "星币", "img": "p03.jpg",
   "upright": "完美的团队合作、精湛的技艺、在学习和工作中获得了初步成就。", "reversed": "缺乏协作、技术不精、工作态度敷衍或者是团队内部出现分歧。"},
  {"name": "星币四 (Four of Pentacles)", "number": "4", "arcana": "小阿尔卡纳", "suit": "星币", "img": "p04.jpg",
   "upright": "保守理财、物质上的安全感、但同时也要注意避免过度吝啬与固执。", "reversed": "挥霍无度、放弃控制、或者是终于学会了分享不再守财奴。"},
  {"name": "星币五 (Five of Pentacles)", "number": "5", "arcana": "小阿尔卡纳", "suit": "星币", "img": "p05.jpg",
   "upright": "贫困、孤立无援、物质或健康上的困境，感觉被剥夺了安全感。", "reversed": "经济状况好转、脱离困境、在最黑暗的时候找到了援助之手。"},
  {"name": "星币六 (Six of Pentacles)", "number": "6", "arcana": "小阿尔卡纳", "suit": "星币", "img": "p06.jpg",
   "upright": "慷慨、慈善、资源的合理分配、收到奖金或是在需要时获得帮助。", "reversed": "自私自利、债务纠纷、分配不公或者是别人给你的帮助带有附加条件。"},
  {"name": "星币七 (Seven of Pentacles)", "number": "7", "arcana": "小阿尔卡纳", "suit": "星币", "img": "p07.jpg",
   "upright": "长远的投资、耐心等待收成、停下来评估目前的进度与付出。", "reversed": "缺乏耐心、投资失败、付出了巨大的努力却没有得到相应的回报。"},
  {"name": "星币八 (Eight of Pentacles)", "number": "8", "arcana": "小阿尔卡纳", "suit": "星币", "img": "p08.jpg",
   "upright": "极度的专注、勤奋工作、通过不断打磨工艺来获得专业的提升。", "reversed": "缺乏热情、粗心大意、工作乏味或者是只看重钱而忽略了质量。"},
  {"name": "星币九 (Nine of Pentacles)", "number": "9", "arcana": "小阿尔卡纳", "suit": "星币", "img": "p09.jpg",
   "upright": "富足、独立自主、个人的成功与优雅、享受自己辛勤劳动换来的成果。", "reversed": "过度依赖他人、物质匮乏、或者是表面风光背地里却为了钱牺牲了自由。"},
  {"name": "星币十 (Ten of Pentacles)", "number": "10", "arcana": "小阿尔卡纳", "suit": "星币", "img": "p10.jpg",
   "upright": "财富的传承、家族的繁荣、长期的财务安全与稳固的物质基础。", "reversed": "财务纠纷、家庭破裂、投资遭受重大损失或者是传统价值的崩塌。"},
  {"name": "星币侍从 (Page of Pentacles)", "number": "11", "arcana": "小阿尔卡纳", "suit": "星币", "img": "p11.jpg",
   "upright": "好学务实、脚踏实地的新项目、即将收到关于金钱或事业的可靠消息。", "reversed": "懒惰、缺乏目标、计划不切实际或者是在学习上无法集中注意力。"},
  {"name": "星币骑士 (Knight of Pentacles)", "number": "12", "arcana": "小阿尔卡纳", "suit": "星币", "img": "p12.jpg",
   "upright": "稳重勤奋、绝对可靠、虽然进展缓慢但一定会把事情坚持到底。", "reversed": "极其固执、停滞不前、因循守旧或者是工作狂导致忽略了生活。"},
  {"name": "星币王后 (Queen of Pentacles)", "number": "13", "arcana": "小阿尔卡纳", "suit": "星币", "img": "p13.jpg",
   "upright": "丰饶、慷慨、贤惠且极具商业头脑、能完美平衡家庭与物质生活。", "reversed": "贪婪、过度依赖物质、极度缺乏安全感或者是忽略了家人的感受。"},
  {"name": "星币国王 (King of Pentacles)", "number": "14", "arcana": "小阿尔卡纳", "suit": "星币", "img": "p14.jpg",
   "upright": "巨大的财富、事业上的巅峰、稳重且值得信赖的成功人士或赞助者。", "reversed": "腐败、极端的物质主义、顽固不化或者是为了金钱而不择手段。"}
];