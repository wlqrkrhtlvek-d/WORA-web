import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// 악보 아이템 모델 (이름 순서 정렬 지원)
class ScoreItem implements Comparable<ScoreItem> {
  final String id;
  final String title;
  final DateTime createdAt;

  ScoreItem({required this.id, required this.title, required this.createdAt});

  @override
  int compareTo(ScoreItem other) {
    return title.compareTo(other.title);
  }
}

// 로컬 보관함 저장소
class ScoreRepository {
  static final List<ScoreItem> _storage = [];

  static void addScore(String title) {
    _storage.add(ScoreItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      createdAt: DateTime.now(),
    ));
  }

  static List<ScoreItem> getSortedScores() {
    _storage.sort();
    return List.from(_storage);
  }
}

// 1. 감성적인 그라데이션 배경을 가진 홈 화면 (회원가입 생략 및 바로 입장)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nicknameController = TextEditingController();
  final _roomPasswordController = TextEditingController();
  String _selectedRole = '참여자';

  void _enterRoom() {
    String nickname = _nicknameController.text.trim();
    String pw = _roomPasswordController.text;

    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용할 닉네임을 입력해주세요.')),
      );
      return;
    }

    if (pw.length != 6 || int.tryParse(pw) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('방 비밀번호는 000001부터 999999까지의 6자리 숫자로 입력해주세요.')),
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditorScreen(
          nickname: nickname,
          role: _selectedRole,
          roomPassword: pw,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 딱딱하지 않고 부드러운 감성 그라데이션 배경 적용
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6884B1), Color(0xFFE2E8F0), Color(0xFFF8FAFC)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 440,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.music_note_rounded, size: 48, color: Color(0xFF4F46E5)),
                  const SizedBox(height: 12),
                  const Text(
                    'WORA 웹 악보 협업',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '실시간으로 악보를 공유하고 함께 소통하세요',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _nicknameController,
                    decoration: InputDecoration(
                      labelText: '내 닉네임',
                      hintText: '사용할 이름을 적어주세요',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('역할: ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('인도자'),
                        selected: _selectedRole == '인도자',
                        selectedColor: const Color(0xFFC7D2FE),
                        onSelected: (selected) => setState(() => _selectedRole = '인도자'),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('참여자'),
                        selected: _selectedRole == '참여자',
                        selectedColor: const Color(0xFFC7D2FE),
                        onSelected: (selected) => setState(() => _selectedRole = '참여자'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _roomPasswordController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: '방 비밀번호 (6자리)',
                      hintText: '000000',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: _enterRoom,
                      child: const Text('방 입장하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ScoreLibraryScreen()),
                        );
                      },
                      child: const Text('악보 보관함 열기 (이름순)', style: TextStyle(fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 펜 종류 및 지우개 크기 정의
enum PenType { fountain, ballpoint, highlighter, pencil, eraser }
enum EraserSize { small, medium, large }

// 2. 편집 및 뷰어 화면 (좌표 오정렬 수정 및 다양한 지우개 크기 반영)
class EditorScreen extends StatefulWidget {
  final String nickname;
  final String role;
  final String roomPassword;

  const EditorScreen({
    super.key,
    required this.nickname,
    required this.role,
    required this.roomPassword,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  PenType _currentPen = PenType.ballpoint;
  EraserSize _eraserSize = EraserSize.medium; // 기본 지우개 크기
  Color _currentColor = Colors.black;
  final List<DrawingPoint?> _points = [];
  bool _hasGalleryImage = false;
  
  final TransformationController _transformationController = TransformationController();

  void _pickImageFromGallery() {
    setState(() {
      _hasGalleryImage = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('갤러리에서 악보를 성공적으로 불러왔습니다!')),
    );
  }

  void _saveScoreToLibrary() {
    TextEditingController titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('악보 보관함 저장'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: '악보 이름 입력',
            hintText: '000000',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isEmpty) return;
              ScoreRepository.addScore(titleController.text);
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

  // 지우개 굵기 값 반환 함수
  double _getEraserWidth() {
    switch (_eraserSize) {
      case EraserSize.small:
        return 15.0;
      case EraserSize.medium:
        return 35.0;
      case EraserSize.large:
        return 70.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('[${widget.role}] ${widget.nickname} | 방: ${widget.roomPassword}'),
        backgroundColor: const Color(0xFFF1F5F9),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: '갤러리 악보 가져오기',
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
          // 툴바 영역 (펜 종류 및 지우개 크기 세부 조절 지원)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFE2E8F0),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildPenButton(PenType.fountain, '만년필', Icons.edit),
                _buildPenButton(PenType.ballpoint, '볼펜', Icons.create),
                _buildPenButton(PenType.highlighter, '형광펜', Icons.highlight),
                _buildPenButton(PenType.pencil, '연필', Icons.mode_edit_outline),
                _buildPenButton(PenType.eraser, '지우개', Icons.cleaning_services),
                
                // 지우개 선택 시에만 크기 조절 옵션 노출
                if (_currentPen == PenType.eraser) ...[
                  const VerticalDivider(width: 12, thickness: 1),
                  _buildEraserSizeChip(EraserSize.small, '지우개 얇게'),
                  _buildEraserSizeChip(EraserSize.medium, '지우개 보통'),
                  _buildEraserSizeChip(EraserSize.large, '지우개 두껍게'),
                ],

                const VerticalDivider(width: 12, thickness: 1),
                _buildColorCircle(Colors.black),
                _buildColorCircle(Colors.red),
                _buildColorCircle(Colors.blue),
                _buildColorCircle(Colors.yellow),
              ],
            ),
          ),
          // 캔버스 영역 (오프셋 완벽 매칭을 위한 InteractiveViewer 적용)
          Expanded(
            child: InteractiveViewer(
              transformationController: _transformationController,
              boundaryMargin: const EdgeInsets.all(500),
              minScale: 0.5,
              maxScale: 5.0,
              panEnabled: _currentPen != PenType.fountain && _currentPen != PenType.ballpoint && _currentPen != PenType.highlighter && _currentPen != PenType.pencil && _currentPen != PenType.eraser, 
              // 드로잉 시 화면 스크롤과 터치 위치 충돌을 막기 위해 펜 사용 중에는 제스처 매핑 조정
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  // 터치 위치 오류 수정을 위해 Matrix 변환 적용
                  final localPos = _transformationController.toScene(details.localPosition);
                  setState(() {
                    _points.add(DrawingPoint(
                      point: localPos,
                      type: _currentPen,
                      color: _currentPen == PenType.eraser ? Colors.white : _currentColor,
                      strokeWidth: _currentPen == PenType.highlighter 
                          ? 20.0 
                          : (_currentPen == PenType.eraser ? _getEraserWidth() : 3.0),
                    ));
                  });
                },
                onPanUpdate: (details) {
                  final localPos = _transformationController.toScene(details.localPosition);
                  setState(() {
                    _points.add(DrawingPoint(
                      point: localPos,
                      type: _currentPen,
                      color: _currentPen == PenType.eraser ? Colors.white : _currentColor,
                      strokeWidth: _currentPen == PenType.highlighter 
                          ? 20.0 
                          : (_currentPen == PenType.eraser ? _getEraserWidth() : 3.0),
                    ));
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    _points.add(null);
                  });
                },
                child: Container(
                  color: Colors.white,
                  width: 3000,
                  height: 3000,
                  child: Stack(
                    children: [
                      if (_hasGalleryImage)
                        Positioned.fill(
                          child: Container(
                            color: Colors.indigo.withOpacity(0.03),
                            child: const Center(
                              child: Text('🎵 [갤러리 악보 배경 로드됨]', style: TextStyle(color: Colors.indigo, fontSize: 20, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      CustomPaint(
                        painter: ScorePainter(points: _points),
                        size: Size.infinite,
                      ),
                    ],
                  ),
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
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.black87),
      selected: isSelected,
      selectedColor: const Color(0xFF4F46E5),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
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

  Widget _buildEraserSizeChip(EraserSize size, String label) {
    bool isSelected = _eraserSize == size;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      selectedColor: const Color(0xFF94A3B8),
      onSelected: (selected) {
        setState(() {
          _eraserSize = size;
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
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        paint.color = points[i]!.color;
        paint.strokeWidth = points[i]!.strokeWidth;
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

// 3. 악보 보관함 화면 (이름 순서 자동 정렬)
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
      _scoreList = ScoreRepository.getSortedScores();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('악보 보관함 (이름 순서 정렬)'),
        backgroundColor: const Color(0xFFF1F5F9),
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
                    leading: const Icon(Icons.music_note, color: Color(0xFF4F46E5), size: 32),
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
