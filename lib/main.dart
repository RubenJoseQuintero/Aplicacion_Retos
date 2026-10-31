import 'dart:math';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF260606),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const CatMemeApp());
}

// ======================================================================
//  MODELOS Y UTILIDADES
// ======================================================================

/// Un meme = foto de gato (Cataas) + texto de arriba + texto de abajo.
/// El texto lo dibuja Flutter encima, como los memes clásicos de internet.
class Meme {
  const Meme(
    this.url,
    this.top,
    this.bottom, {
    this.thumb,
    this.color = Colors.white,
    this.size = 0.095,
  });

  final String url; // foto completa
  final String top;
  final String bottom;
  final String? thumb; // foto chica para cuadrículas
  final Color color;
  final double size; // tamaño de letra como fracción del ancho

  String get preview => thumb ?? url;
  String get id => '$url|$top|$bottom|${color.hashCode}|${size.toStringAsFixed(3)}';
}

class FavoritesModel extends ChangeNotifier {
  final List<Meme> _items = [];
  List<Meme> get items => List.unmodifiable(_items);

  bool contains(Meme m) => _items.any((x) => x.id == m.id);

  void toggle(Meme m) {
    final i = _items.indexWhere((x) => x.id == m.id);
    if (i >= 0) {
      _items.removeAt(i);
    } else {
      _items.insert(0, m);
    }
    notifyListeners();
  }

  void insertAt(int i, Meme m) {
    _items.insert(min(i, _items.length), m);
    notifyListeners();
  }

  void remove(Meme m) {
    _items.removeWhere((x) => x.id == m.id);
    notifyListeners();
  }
}

/// URL de Cataas SIN texto (el texto lo ponemos nosotros).
/// Ej: https://cataas.com/cat/cute?filter=sepia&t=123
Uri catUri({
  String tag = '',
  String filter = 'none',
  int? seed,
  int? width,
}) {
  return Uri(
    scheme: 'https',
    host: 'cataas.com',
    pathSegments: ['cat', if (tag.isNotEmpty) tag],
    queryParameters: {
      't': (seed ?? DateTime.now().millisecondsSinceEpoch).toString(),
      if (filter != 'none') 'filter': filter,
      if (width != null) 'width': width.toString(),
    },
  );
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 1400),
    ));
}

/// Frases estilo meme: (arriba, abajo)
const _pairs = [
  ('Cuando dicen', 'Que ya es lunes'),
  ('Yo viendo mi cuenta', 'Después de la quincena'),
  ('Mamá: ya duérmete', 'Yo a las 3 am'),
  ('Dijeron que habría pizza', 'Y era ensalada'),
  ('Mi cartera', 'Después de pagar el súper'),
  ('¿Tarea para mañana?', 'Mañana la hago'),
  ('Yo: voy a ahorrar', 'También yo: ofertas'),
  ('Cuando suena la alarma', 'Cinco minutos más'),
  ('Nadie:', 'Mi gato a las 4 am'),
  ('Me dicen que sonría', 'Ya sonreí'),
];

// ======================================================================
//  APP
// ======================================================================

class CatMemeApp extends StatelessWidget {
  const CatMemeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meme Gatos',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      builder: (context, child) => PhoneFrame(child: child!),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF260606),
          indicatorColor: Colors.redAccent,
        ),
      ),
      home: const HomeShell(),
    );
  }
}

/// En pantallas grandes (compu) dibuja la app dentro de un marco de celular.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth <= 600) return child;

        const bezel = 10.0;
        final h = min(c.maxHeight - 32, 840.0);
        final w = min(h * 0.49, 410.0);
        final inner = Size(w - bezel * 2, h - bezel * 2);

        return Container(
          color: const Color(0xFF0D0D0D),
          alignment: Alignment.center,
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(44),
              border: Border.all(color: const Color(0xFF2B2B2B), width: bezel),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withAlpha(90),
                  blurRadius: 60,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: inner,
                  padding: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(child: child),
                    Positioned(
                      top: 8,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Estructura principal: PageView (deslizas) + barra de navegación abajo.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _favs = FavoritesModel();
  final _pages = PageController();
  final _createKey = GlobalKey<CreateScreenState>();
  int _index = 0;

  void _go(int i) {
    HapticFeedback.selectionClick();
    _pages.animateToPage(
      i,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _useTemplate(String top, String bottom, String tag) {
    _createKey.currentState?.applyPreset(top, bottom, tag);
    _go(0);
  }

  @override
  void dispose() {
    _pages.dispose();
    _favs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(0);
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFB71C1C), Color(0xFF3E0A0A), Colors.black],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: PageView(
              controller: _pages,
              onPageChanged: (i) {
                FocusScope.of(context).unfocus();
                setState(() => _index = i);
              },
              children: [
                CreateScreen(key: _createKey, favs: _favs),
                ExploreScreen(favs: _favs, onUse: _useTemplate),
                FavoritesScreen(favs: _favs, onGoCreate: () => _go(0)),
              ],
            ),
          ),
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: _favs,
          builder: (context, _) => NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _go,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome),
                label: 'Crear',
              ),
              const NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Explorar',
              ),
              NavigationDestination(
                icon: Badge(
                  label: Text('${_favs.items.length}'),
                  isLabelVisible: _favs.items.isNotEmpty,
                  child: const Icon(Icons.favorite_border),
                ),
                selectedIcon: Badge(
                  label: Text('${_favs.items.length}'),
                  isLabelVisible: _favs.items.isNotEmpty,
                  child: const Icon(Icons.favorite),
                ),
                label: 'Favoritos',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================================
//  WIDGETS COMPARTIDOS
// ======================================================================

class CatImage extends StatelessWidget {
  const CatImage(this.url, {super.key});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
      errorBuilder: (context, error, stack) => const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Text('No se pudo cargar 😿', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

/// Texto estilo meme: letras grandes, en mayúsculas y con contorno.
class OutlinedText extends StatelessWidget {
  const OutlinedText(this.text, {super.key, required this.size, required this.color});
  final String text;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final outline = color.computeLuminance() < 0.15 ? Colors.white : Colors.black;
    final base = TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      height: 1.05,
      letterSpacing: size * 0.02,
      fontFamilyFallback: const ['Impact', 'Anton', 'Arial Black'],
    );
    final t = text.toUpperCase();
    return Stack(
      children: [
        Text(
          t,
          textAlign: TextAlign.center,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size * 0.2
              ..strokeJoin = StrokeJoin.round
              ..color = outline,
          ),
        ),
        Text(t, textAlign: TextAlign.center, style: base.copyWith(color: color)),
      ],
    );
  }
}

/// Foto + texto arriba y abajo. El texto se escala según el ancho disponible,
/// así se ve bien tanto en miniatura como en pantalla grande.
class MemeView extends StatelessWidget {
  const MemeView(this.meme, {super.key, this.thumb = false});
  final Meme meme;
  final bool thumb;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final fontSize = c.maxWidth * meme.size;
        final pad = c.maxWidth * 0.04;
        return Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween(begin: 0.94, end: 1.0).animate(anim),
                  child: child,
                ),
              ),
              child: SizedBox.expand(
                key: ValueKey(thumb ? meme.preview : meme.url),
                child: CatImage(thumb ? meme.preview : meme.url),
              ),
            ),
            if (meme.top.trim().isNotEmpty)
              Positioned(
                top: pad,
                left: pad,
                right: pad,
                child: Center(
                  child: OutlinedText(meme.top, size: fontSize, color: meme.color),
                ),
              ),
            if (meme.bottom.trim().isNotEmpty)
              Positioned(
                bottom: pad,
                left: pad,
                right: pad,
                child: Center(
                  child: OutlinedText(meme.bottom, size: fontSize, color: meme.color),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, required this.onTap, this.color = Colors.white});
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Icon(icon, key: ValueKey(icon), color: color, size: 22),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header(this.title, this.subtitle);
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
            ),
            Text(subtitle, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      );
}

void openDetail(BuildContext context, Meme meme, FavoritesModel favs, String heroTag) {
  Navigator.of(context).push(PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) => DetailScreen(meme: meme, favs: favs, heroTag: heroTag),
    transitionsBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
  ));
}

// ======================================================================
//  PANTALLA DE DETALLE
// ======================================================================

class DetailScreen extends StatelessWidget {
  const DetailScreen({
    super.key,
    required this.meme,
    required this.favs,
    required this.heroTag,
  });

  final Meme meme;
  final FavoritesModel favs;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(meme.top.isEmpty ? 'Meme' : meme.top, overflow: TextOverflow.ellipsis),
        actions: [
          ListenableBuilder(
            listenable: favs,
            builder: (context, _) => IconButton(
              icon: Icon(
                favs.contains(meme) ? Icons.favorite : Icons.favorite_border,
                color: Colors.redAccent,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                favs.toggle(meme);
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Hero(
                tag: heroTag,
                child: InteractiveViewer(
                  maxScale: 5,
                  child: AspectRatio(aspectRatio: 1, child: MemeView(meme)),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Pellizca para hacer zoom', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
//  PESTAÑA 1: CREAR
// ======================================================================

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key, required this.favs});
  final FavoritesModel favs;

  @override
  State<CreateScreen> createState() => CreateScreenState();
}

class CreateScreenState extends State<CreateScreen>
    with AutomaticKeepAliveClientMixin {
  final _topCtrl = TextEditingController();
  final _bottomCtrl = TextEditingController();
  final _random = Random();

  String _tag = 'cute';
  String _filter = 'none';
  Color _color = Colors.white;
  double _size = 0.095;
  int _seed = DateTime.now().millisecondsSinceEpoch;
  double _turns = 0;
  int _memeCount = 0;

  // Nombres de filtros válidos en Cataas
  static const _filters = ['none', 'mono', 'sepia', 'negative', 'blur', 'pixel', 'paint'];

  // Tipo de gato (tags de Cataas)
  static const _styles = {
    'cute': 'Tiernos',
    'kitten': 'Gatitos',
    'orange': 'Naranjas',
    '': 'Cualquiera',
  };

  static const _palette = <Color>[
    Colors.white,
    Colors.yellow,
    Colors.black,
    Colors.cyanAccent,
    Colors.limeAccent,
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final p = _pairs[_random.nextInt(_pairs.length)];
    _topCtrl.text = p.$1;
    _bottomCtrl.text = p.$2;
  }

  Meme get _meme => Meme(
        catUri(tag: _tag, filter: _filter, seed: _seed).toString(),
        _topCtrl.text,
        _bottomCtrl.text,
        color: _color,
        size: _size,
      );

  void applyPreset(String top, String bottom, String tag) {
    _topCtrl.text = top;
    _bottomCtrl.text = bottom;
    setState(() {
      _tag = tag;
      _filter = 'none';
      _seed = DateTime.now().millisecondsSinceEpoch;
      _memeCount++;
    });
  }

  void _newCat() {
    HapticFeedback.lightImpact();
    setState(() {
      _seed = DateTime.now().millisecondsSinceEpoch;
      _turns += 1;
      _memeCount++;
    });
  }

  void _surprise() {
    final p = _pairs[_random.nextInt(_pairs.length)];
    _topCtrl.text = p.$1;
    _bottomCtrl.text = p.$2;
    _filter = _filters[_random.nextInt(_filters.length)];
    _color = _palette[_random.nextInt(_palette.length)];
    _newCat();
  }

  @override
  void dispose() {
    _topCtrl.dispose();
    _bottomCtrl.dispose();
    super.dispose();
  }

  InputDecoration _field(String label, IconData icon) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.black38,
        prefixIcon: Icon(icon, color: Colors.redAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final meme = _meme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _Header('Crear meme', 'Escribe arriba y abajo, como siempre'),
        Center(
          child: Text('Memes creados: $_memeCount',
              style: const TextStyle(color: Colors.white70)),
        ),
        const SizedBox(height: 12),

        // Meme
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.redAccent, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withAlpha(120),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: () => openDetail(context, meme, widget.favs, 'create-hero'),
                    child: Hero(tag: 'create-hero', child: MemeView(meme)),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: ListenableBuilder(
                      listenable: widget.favs,
                      builder: (context, _) {
                        final fav = widget.favs.contains(meme);
                        return Column(
                          children: [
                            _RoundBtn(
                              icon: fav ? Icons.favorite : Icons.favorite_border,
                              color: fav ? Colors.redAccent : Colors.white,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.favs.toggle(meme);
                                toast(context, fav ? 'Quitado de favoritos' : 'Guardado en favoritos');
                              },
                            ),
                            const SizedBox(height: 8),
                            _RoundBtn(
                              icon: Icons.fullscreen,
                              onTap: () => openDetail(context, meme, widget.favs, 'create-hero'),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Textos (se ven al instante, sin esperar a la red)
        TextField(
          controller: _topCtrl,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.next,
          decoration: _field('Texto de arriba', Icons.vertical_align_top),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bottomCtrl,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.done,
          decoration: _field('Texto de abajo', Icons.vertical_align_bottom),
        ),
        const SizedBox(height: 16),

        const _SectionLabel('Tipo de gato'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _styles.entries
              .map((e) => ChoiceChip(
                    label: Text(e.value),
                    selected: _tag == e.key,
                    selectedColor: Colors.redAccent,
                    onSelected: (_) => setState(() {
                      _tag = e.key;
                      _seed = DateTime.now().millisecondsSinceEpoch;
                    }),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),

        const _SectionLabel('Filtro'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _filters
              .map((f) => ChoiceChip(
                    label: Text(f),
                    selected: _filter == f,
                    selectedColor: Colors.redAccent,
                    onSelected: (_) => setState(() => _filter = f),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),

        const _SectionLabel('Color del texto'),
        Row(
          children: _palette.map((c) {
            final selected = _color == c;
            return GestureDetector(
              onTap: () => setState(() => _color = c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 12),
                width: selected ? 44 : 34,
                height: selected ? 44 : 34,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? Colors.redAccent : Colors.white24,
                    width: 3,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        _SectionLabel('Tamaño de letra: ${(_size * 1000).round()}'),
        Slider(
          value: _size,
          min: 0.05,
          max: 0.14,
          activeColor: Colors.redAccent,
          onChanged: (v) => setState(() => _size = v),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _newCat,
                icon: AnimatedRotation(
                  turns: _turns,
                  duration: const Duration(milliseconds: 500),
                  child: const Icon(Icons.refresh),
                ),
                label: const Text('Otro gato'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.redAccent, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _surprise,
                icon: const Icon(Icons.casino),
                label: const Text('Sorpréndeme'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ======================================================================
//  PESTAÑA 2: EXPLORAR
// ======================================================================

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, required this.favs, required this.onUse});
  final FavoritesModel favs;
  final void Function(String top, String bottom, String tag) onUse;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with AutomaticKeepAliveClientMixin {
  static const _tags = {
    'cute': 'Tiernos',
    'kitten': 'Gatitos',
    'orange': 'Naranjas',
    'black': 'Negros',
    'white': 'Blancos',
    '': 'Todos',
  };

  String _tag = 'cute';
  late List<Meme> _items = _build();

  @override
  bool get wantKeepAlive => true;

  List<Meme> _build() {
    final r = Random();
    final pairs = [..._pairs]..shuffle(r);
    return pairs.take(8).map((p) {
      final seed = r.nextInt(1 << 30);
      return Meme(
        catUri(tag: _tag, seed: seed).toString(),
        p.$1,
        p.$2,
        thumb: catUri(tag: _tag, seed: seed, width: 400).toString(),
      );
    }).toList();
  }

  Future<void> _refresh() async => setState(() => _items = _build());

  void _showSheet(Meme m) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A0707),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 240,
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: MemeView(m, thumb: true),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      widget.onUse(m.top, m.bottom, _tag);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.fullscreen),
                    label: const Text('Ver grande'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      openDetail(context, m, widget.favs, 'explore-${m.url}');
                    },
                  ),
                ),
              ],
            ),
            ListenableBuilder(
              listenable: widget.favs,
              builder: (context, _) => TextButton.icon(
                icon: Icon(widget.favs.contains(m) ? Icons.favorite : Icons.favorite_border),
                label: Text(widget.favs.contains(m) ? 'En favoritos' : 'Guardar en favoritos'),
                onPressed: () => widget.favs.toggle(m),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Header('Explorar', 'Toca un meme para editarlo o guardarlo'),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _tags.entries
                .map((e) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(e.value),
                        selected: _tag == e.key,
                        selectedColor: Colors.redAccent,
                        onSelected: (_) {
                          _tag = e.key;
                          _refresh();
                        },
                      ),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: Colors.redAccent,
            onRefresh: _refresh,
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final m = _items[i];
                return GestureDetector(
                  onTap: () => _showSheet(m),
                  child: Hero(
                    tag: 'explore-${m.url}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: MemeView(m, thumb: true),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ======================================================================
//  PESTAÑA 3: FAVORITOS
// ======================================================================

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key, required this.favs, required this.onGoCreate});
  final FavoritesModel favs;
  final VoidCallback onGoCreate;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: favs,
      builder: (context, _) {
        final items = favs.items;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header('Favoritos', '${items.length} guardados · desliza para borrar'),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.6, end: 1),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.elasticOut,
                            builder: (_, v, child) => Transform.scale(scale: v, child: child),
                            child: const Icon(Icons.favorite_border,
                                size: 80, color: Colors.redAccent),
                          ),
                          const SizedBox(height: 12),
                          const Text('Aún no tienes favoritos',
                              style: TextStyle(fontSize: 18, color: Colors.white)),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                            onPressed: onGoCreate,
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('Crear un meme'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final m = items[i];
                        return Dismissible(
                          key: ValueKey(m.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.only(right: 24),
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(
                              color: Colors.red.shade900,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) {
                            favs.remove(m);
                            ScaffoldMessenger.of(context)
                              ..clearSnackBars()
                              ..showSnackBar(SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: const Text('Quitado de favoritos'),
                                action: SnackBarAction(
                                  label: 'Deshacer',
                                  onPressed: () => favs.insertAt(i, m),
                                ),
                              ));
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: Colors.black38,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: const BorderSide(color: Colors.redAccent, width: 1),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => openDetail(context, m, favs, 'fav-${m.id}'),
                              child: Row(
                                children: [
                                  Hero(
                                    tag: 'fav-${m.id}',
                                    child: SizedBox(
                                      width: 120,
                                      height: 120,
                                      child: MemeView(m),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      [m.top, m.bottom].where((s) => s.isNotEmpty).join('\n'),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 15, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.white54),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}