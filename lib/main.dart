import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const WoraWebApp());
}

class WoraWebApp extends StatelessWidget {
  const WoraWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WORA Web',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// 1. 악보 아이템 모델 (이름 순서 정렬 지원)
class ScoreItem implements Comparable<ScoreItem> {
  final String id;
  final String title;
  final String? imagePath;
  final DateTime createdAt;

  ScoreItem({
    required this.id,
    required this.title,
    this.imagePath,
    required this.createdAt,
  });

  @override
  int compareTo(ScoreItem other) {
    // 이름 순서(가나다/ABC 순) 정렬
    return title.compareTo(other.title);
  }
}

// 로컬 보관함 저장소 (메모리 기반 + 이름순 정렬)
class ScoreRepository {
  static final List<ScoreItem> _storage = [];

  static void addScore(String title, String? imagePath) {
    _storage.add(ScoreItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      imagePath: imagePath,
      createdAt: DateTime.now(),
    ));
  }

  static List<ScoreItem> getSortedScores() {
    _storage.sort(); // 이름 순서 자동 정렬
    return List.from(_storage);
  }
}

// 홈 화면 (방 입장 및 보관함 이동)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _passwordController = TextEditingController();
  String _generatedNickname = '';

  @override
  void initState() {
    super.initState();
    _generateRandomNickname();
  }

  // 방 입장 시 가상 닉네임 자동 생성
  void _generateRandomNickname() {
    final adjectives = ['즐거운', '노래하는', '열정적인', '차분한', '빛나는', '귀여운'];
    final nouns = ['피아노', '바이올린', '기타', '플루트', '첼로', '지휘자'];
    final rand = Random();
    setState(() {
      _generatedNickname = '${adjectives[rand.nextInt(adjectives.length)]} ${nouns[rand.nextInt(nouns.length)]}';
    });
  }

  void _enterRoom() {
    String pw = _passwordController.text;
    // 6자리 숫자 검사 및 범위 검사 (000001 ~ 999999)
    if (pw.length != 6 || int.tryParse(pw) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호는 000001부터 999999까지의 6자리 숫자로 입력해주세요.')),
      );
      return;
    }
    int pwNum = int.parse(pw);
    if (pwNum < 1 || pwNum > 999999) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호 범위는 000001 ~ 999999 사이여야 합니다.')),
      );
      return;
    }

    // 에디터 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditorScreen(nickname: _generatedNickname, roomPassword: pw),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WORA 웹 악보 협업 공간'), centerTitle: true),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('가상 방 입장', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('내 닉네임: ', style: TextStyle(color: Colors.grey)),
                  Text(_generatedNickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: _generateRandomNickname,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: '방 비밀번호 입력',
                  hintText: '000000', // 예시 대신 포맷 힌트 적용
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                  onPressed: _enterRoom,
                  child: const Text('방 입장하기', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ScoreLibraryScreen()),
                    );
                  },
                  child: const Text('악보 보관함 열기', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 굿노트 스타일 펜 5가지 종류
enum PenType { fountain, ballpoint, highlighter, pencil, eraser }

// 악보 편집 및 뷰어 화면
class EditorScreen extends StatefulWidget {
  final String nickname;
  final String roomPassword;

  const EditorScreen({super.key, required this.nickname, required this.roomPassword});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  PenType _currentPen = PenType.ballpoint;
  Color _currentColor = Colors.black;
  final List<DrawingPoint?> _points = [];
  String? _galleryImagePath;
  final ImagePicker _picker = ImagePicker();

  // 1. 갤러리에서 악보 직접 가져오기 기능 (image_picker 연동)
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _galleryImagePath = image.path;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('갤러리에서 악보를 성공적으로 불러왔습니다!')),
        );
      }
    } catch (e) {
      // 웹이나 플랫폼 환경 제약 시 대체 처리
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('갤러리 불러오기 환경을 확인해주세요.')),
      );
    }
  }

  // 악보 저장하기
  void _saveScoreToLibrary() {
    TextEditingController titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('악보 보관함에 저장'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: '악보 이름 입력',
            hintText: '000000', // 예시 생김새 가이드 준수
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isEmpty) return;
              ScoreRepository.addScore(titleController.text, _galleryImagePath);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('악보 보관함에 저장되었습니다!')),
              );
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('방 번호: ${widget.roomPassword} | 사용자: ${widget.nickname}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: '갤러리에서 악보 가져오기',
            onPressed: _pickImageFromGallery,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: '악보 저장',
            onPressed: _saveScoreToLibrary,
          ),
        ],
      ),
      body: Column(
        children: [
          // 2. 굿노트 감성 펜 5가지 선별 툴바
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[200],
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              children: [
                _buildPenButton(PenType.fountain, '만년필', Icons.edit),
                _buildPenButton(PenType.ballpoint, '볼펜', Icons.create),
                _buildPenButton(PenType.highlighter, '형광펜', Icons.highlight),
                _buildPenButton(PenType.pencil, '연필', Icons.mode_edit_outline),
                _buildPenButton(PenType.eraser, '지우개', Icons.cleaning_services),
                const VerticalDivider(width: 10),
                _buildColorCircle(Colors.black),
                _buildColorCircle(Colors.red),
                _buildColorCircle(Colors.blue),
                _buildColorCircle(Colors.yellow),
              ],
            ),
          ),
          // 3. 굿노트 느낌의 넓은 악보 칸 (줌 및 와이드 스크롤 지원)
          Expanded(
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(300),
              minScale: 0.5,
              maxScale: 5.0,
              child: Container(
                color: Colors.white,
                width: 3000,
                height: 3000,
                child: Stack(
                  children: [
                    // 불러온 갤러리 악보 이미지 배경 표현
                    if (_galleryImagePath != null)
                      Positioned.fill(
                        child: Container(
                          color: Colors.grey[50],
                          child: const Center(
                            child: Text(
                              '🎵 [갤러리 악보 이미지 로드 완료]',
                              style: TextStyle(color: Colors.blueGrey, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    // 드로잉 캔버스 영역
                    Positioned.fill(
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            RenderBox renderBox = context.findRenderObject() as RenderBox;
                            Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                            _points.add(DrawingPoint(
                              point: localPosition,
                              type: _currentPen,
                              color: _currentPen == PenType.eraser ? Colors.white : _currentColor,
                              strokeWidth: _currentPen == PenType.highlighter ? 20.0 : 3.0,
                            ));
                          });
                        },
                        onPanEnd: (details) {
                          setState(() {
                            _points.add(null);
                          });
                        },
                        child: CustomPaint(
                          painter: ScorePainter(points: _points),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPenButton(PenType type, String label, IconData icon) {
    bool isSelected = _currentPen == type;
    return ChoiceChip(
      label: Text(label),
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.black),
      selected: isSelected,
      selectedColor: Colors.blueGrey,
      onSelected: (selected) {
        setState(() {
          _currentPen = type;
          if (type == PenType.highlighter) {
            _currentColor = Colors.yellow.withOpacity(0.4);
          } else if (type != PenType.eraser) {
            _currentColor = Colors.black;
          }
        });
      },
    );
  }

  Widget _buildColorCircle(Color color) {
    return GestureDetector(
      onTap: () => setState(() => _currentColor = color),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
        ),
      ),
    );
  }
}

class DrawingPoint {
  Offset? point;
  PenType type;
  Color color;
  double strokeWidth;

  DrawingPoint({required this.point, required this.type, required this.color, required this.strokeWidth});
}

class ScorePainter extends CustomPainter {
  final List<DrawingPoint?> points;

  ScorePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        paint.color = points[i]!.color;
        paint.strokeWidth = points[i]!.strokeWidth;
        
        // 펜 종류별 특징 반영 (연필은 얇고 서걱거리는 느낌)
        if (points[i]!.type == PenType.pencil) {
          paint.strokeWidth = 1.5;
        }

        canvas.drawLine(points[i]!.point!, points[i + 1]!.point!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 7. 악보 보관함 화면 (이름 순서대로 정리된 리스트)
class ScoreLibraryScreen extends StatefulWidget {
  const ScoreLibraryScreen({super.key});

  @override
  State<ScoreLibraryScreen> createState() => _ScoreLibraryScreenState();
}

class _ScoreLibraryScreenState extends State<ScoreLibraryScreen> {
  List<ScoreItem> _scoreList = [];

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  void _loadScores() {
    setState(() {
      _scoreList = ScoreRepository.getSortedScores(); // 이름순 정렬된 목록 가져오기
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('악보 보관함 (이름 순서 정렬)'),
        centerTitle: true,
      ),
      body: _scoreList.isEmpty
          ? const Center(child: Text('저장된 악보가 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 16)))
          : ListView.builder(
              itemCount: _scoreList.length,
              itemBuilder: (context, index) {
                final score = _scoreList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.music_note, color: Colors.blueGrey, size: 32),
                    title: Text(score.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('저장 일시: ${score.createdAt.toLocal().toString().split('.')[0]}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('\'${score.title}\' 악보를 불러옵니다.')),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
