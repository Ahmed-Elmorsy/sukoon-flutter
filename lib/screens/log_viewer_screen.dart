import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_logger.dart';
import '../theme/app_theme.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  final ScrollController _scroll = ScrollController();
  String _filter = 'ALL';

  static const _levels = ['ALL', 'API_OK', 'API_ERR', 'AUTH', 'NAV', 'INFO', 'WARN', 'ERROR'];

  static const _levelColors = {
    'API_OK':  Color(0xFF2E7D32),
    'API_ERR': Color(0xFFC62828),
    'AUTH':    Color(0xFF1565C0),
    'NAV':     Color(0xFF6A1B9A),
    'INFO':    Color(0xFF37474F),
    'WARN':    Color(0xFFE65100),
    'ERROR':   Color(0xFFB71C1C),
  };

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List get _filtered {
    final entries = AppLogger.instance.entries;
    if (_filter == 'ALL') return entries;
    return entries.where((e) => e.level == _filter).toList();
  }

  Color _colorFor(String level) =>
      _levelColors[level] ?? AppTheme.textGrey;

  @override
  Widget build(BuildContext context) {
    final entries = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('App Logs',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined, color: Colors.white70),
            tooltip: 'Copy all logs',
            onPressed: () {
              final all = AppLogger.instance.entries
                  .map((e) => '[${e.timestamp}] [${e.level}] [${e.tag}] ${e.message}'
                      '${e.data != null ? '\n  ${e.data}' : ''}')
                  .join('\n');
              Clipboard.setData(ClipboardData(text: all));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logs copied to clipboard')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Refresh',
            onPressed: () => setState(() {}),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              children: _levels.map((lvl) {
                final active = _filter == lvl;
                return GestureDetector(
                  onTap: () => setState(() => _filter = lvl),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: active
                          ? (_levelColors[lvl] ?? AppTheme.primaryBlue)
                          : const Color(0xFF21262D),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      lvl,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: entries.isEmpty
          ? const Center(
              child: Text('No logs yet.',
                  style: TextStyle(color: Colors.white38, fontSize: 16)),
            )
          : ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(8),
              itemCount: entries.length,
              itemBuilder: (_, i) {
                final e = entries[i];
                final color = _colorFor(e.level as String);
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(left: BorderSide(color: color, width: 3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              e.level as String,
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '[${e.tag}]',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                          const Spacer(),
                          Text(
                            (e.timestamp as String).substring(11, 19),
                            style: const TextStyle(color: Colors.white30, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.message as String,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.87),
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (e.data != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          e.data.toString(),
                          style: TextStyle(
                            color: color.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: AppTheme.primaryBlue,
        onPressed: () {
          if (_scroll.hasClients) {
            _scroll.animateTo(
              _scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        },
        child: const Icon(Icons.arrow_downward, color: Colors.white),
      ),
    );
  }
}
